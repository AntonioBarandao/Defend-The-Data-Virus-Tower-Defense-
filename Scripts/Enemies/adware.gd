class_name Adware
extends RedVirus

const POPUP_GROUP := "ADWARE"
const CLOSE_BUTTON_ANIMATION := &"Adware_Exit_Press"
const ADWARE_BODY_Z_INDEX := 3800
const HEALTH_BAR_Z_INDEX := 3900
const POPUP_Z_INDEX_BASE := 4000
const POPUP_Z_INDEX_MAX := 4088

@export var random_rotation_degrees := 4.0
@export var lifespan_seconds := 12.0
@export var popup_container_path: NodePath = ^"Popups"
@export_group("Popup Burst")
@export_range(1, 40, 1) var popup_burst_count := 20
@export_range(1, 10, 1) var max_active_popups := 5
@export_range(0.05, 3.0, 0.05) var popup_interval_seconds := 0.5
@export_group("Popup Anchor")
@export var popup_anchor_offset := Vector2.ZERO
@export_group("Popup Spread")
@export_range(1, 12, 1) var spread_columns: int = 5
@export_range(1, 12, 1) var spread_rows: int = 1
@export var spread_size := Vector2(64.0, 28.0)
@export var spread_jitter := Vector2(12.0, 8.0)
@export var stack_offset := Vector2(5.0, 4.0)
@export_group("Popup Close Button")
@export var popup_close_button_template_path: NodePath = ^"Popups/RedButtonCollision"
@export_range(0.05, 1.0, 0.01) var close_button_press_duration := 0.35
@export_group("Health Bar")
@export var health_bar_root_path: NodePath = ^"MinibossHealthBar"
@export var health_bar_offset := Vector2(0.0, -125.0)
@export_group("")

var _popup_sprites: Array[Sprite2D] = []
var _popup_offsets := {}
var _popup_buttons := {}
var _popup_tweens := {}
var _popup_closing_indices := {}
var _popup_base_positions := {}
var _popup_base_rotations := {}
var _popup_base_scales := {}
var _active_popup_indices: Array[int] = []
var _popup_spawn_order: Array[int] = []
var _popup_spawn_index := 0
var _popup_spawn_cooldown := 0.0
var _popup_burst_running := false
var _popup_anchor_candidates: Array[Node2D] = []
var _popup_anchor: Node2D
var _rng := RandomNumberGenerator.new()
var _health_bar: TrojanHorseProgressBar
var _close_button_template: Area2D


func _ready() -> void:
	_rng.randomize()
	add_to_group(POPUP_GROUP)
	super._ready()
	_apply_popup_layering()
	if not health_changed.is_connected(_on_health_changed):
		health_changed.connect(_on_health_changed)
	_collect_popup_sprites()
	_hide_all_popups()
	_ensure_close_button_template()
	_ensure_health_bar()
	_set_health_bar_health(current_health, max_health, false)
	_set_health_bar_visible(false)


func _process(delta: float) -> void:
	super._process(delta)
	_position_health_bar()
	_update_popup_positions()
	_update_popup_burst(delta)


func reset_for_spawn() -> void:
	super.reset_for_spawn()
	_apply_popup_layering()
	self_modulate = Color.WHITE
	_collect_popup_sprites()
	_hide_all_popups()
	_ensure_close_button_template()
	_ensure_health_bar()
	_set_health_bar_health(current_health, max_health, false)
	_set_health_bar_visible(true)
	_position_health_bar()


func start_popup_burst(
	variation_indices: Array = [],
	count := -1,
	interval_seconds := -1.0,
	anchor_candidates: Array = []
) -> void:
	_collect_popup_sprites()
	_hide_all_popups()
	if _popup_sprites.is_empty():
		return

	_popup_anchor_candidates = _filter_popup_anchors(anchor_candidates)
	_popup_anchor = _select_popup_anchor()

	var final_count := popup_burst_count if count <= 0 else count
	var final_interval := popup_interval_seconds if interval_seconds <= 0.0 else interval_seconds
	_popup_spawn_order.clear()
	for index in range(final_count):
		if index < variation_indices.size():
			_popup_spawn_order.append(int(variation_indices[index]) % _popup_sprites.size())
		else:
			_popup_spawn_order.append(_rng.randi_range(0, _popup_sprites.size() - 1))

	_popup_spawn_index = 0
	_popup_spawn_cooldown = 0.0
	popup_interval_seconds = final_interval
	_popup_burst_running = true


func setup(variation_index: int = -1) -> void:
	_collect_popup_sprites()
	_hide_all_popups()
	if variation_index >= 0:
		_show_popup(variation_index % _popup_sprites.size(), 0)


func play_destroy_and_queue_owner(owner: Node) -> void:
	_set_health_bar_visible(false)
	_hide_all_popups()
	super.play_destroy_and_queue_owner(owner)


func try_press_popup_close_at(global_point: Vector2) -> bool:
	for popup_index in _active_popup_indices.duplicate():
		var button := _popup_buttons.get(popup_index) as Area2D
		if not is_instance_valid(button) or not button.visible:
			continue
		if not _button_contains_global_point(button, global_point):
			continue

		_press_popup_button(popup_index)
		return true

	return false


func _update_popup_burst(delta: float) -> void:
	if not _popup_burst_running:
		return

	_popup_spawn_cooldown -= delta
	if _popup_spawn_cooldown > 0.0:
		return

	if _popup_spawn_index >= _popup_spawn_order.size():
		_popup_burst_running = false
		return

	_show_popup(_popup_spawn_order[_popup_spawn_index], _popup_spawn_index)
	_popup_spawn_index += 1
	_popup_spawn_cooldown = popup_interval_seconds


func _collect_popup_sprites() -> void:
	_popup_sprites.clear()
	var popup_container := get_node_or_null(popup_container_path)
	if popup_container == null:
		return

	for child in popup_container.get_children():
		var sprite := child as Sprite2D
		if sprite == null:
			continue
		_popup_sprites.append(sprite)
		var popup_index := _popup_sprites.size() - 1
		if not _popup_base_positions.has(popup_index):
			_popup_base_positions[popup_index] = sprite.position
			_popup_base_rotations[popup_index] = sprite.rotation
			_popup_base_scales[popup_index] = sprite.scale


func _show_popup(variation_index: int, spawn_index: int) -> void:
	if _popup_sprites.is_empty():
		return

	var popup_index := clampi(variation_index, 0, _popup_sprites.size() - 1)
	if _active_popup_indices.has(popup_index):
		_close_popup_by_index(popup_index, false)
	while _active_popup_indices.size() >= maxi(1, max_active_popups):
		_close_popup_by_index(_active_popup_indices[0], false)

	var sprite := _popup_sprites[popup_index]
	_restore_popup_scene_transform(sprite, popup_index)
	var target_scale := sprite.global_scale
	_kill_popup_tween(popup_index)
	_popup_closing_indices.erase(popup_index)
	_popup_offsets[popup_index] = _get_popup_offset(_active_popup_indices.size())
	_active_popup_indices.append(popup_index)

	sprite.top_level = true
	sprite.visible = true
	sprite.z_as_relative = false
	sprite.z_index = mini(POPUP_Z_INDEX_MAX, POPUP_Z_INDEX_BASE + spawn_index)
	sprite.global_rotation = deg_to_rad(_rng.randf_range(-random_rotation_degrees, random_rotation_degrees))
	sprite.global_scale = target_scale * 0.2
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_position_popup(sprite, popup_index)
	_configure_popup_close_button(popup_index, sprite)

	var tween := create_tween()
	_popup_tweens[popup_index] = tween
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "global_scale", target_scale * 1.08, 0.18)
	tween.parallel().tween_property(sprite, "modulate:a", 1.0, 0.12)
	tween.tween_property(sprite, "global_scale", target_scale, 0.09)
	if lifespan_seconds > 0.0:
		tween.tween_interval(lifespan_seconds)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(sprite, "global_scale", target_scale * 0.85, 0.18)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.18)
		tween.tween_callback(Callable(self, "_auto_hide_popup").bind(popup_index))


func _get_popup_offset(spawn_index: int) -> Vector2:
	var columns := maxi(1, spread_columns)
	var rows := maxi(1, spread_rows)
	var column := spawn_index % columns
	var row := int(spawn_index / columns) % rows
	var area := Vector2(maxf(1.0, spread_size.x), maxf(1.0, spread_size.y))
	var step := Vector2.ZERO
	if columns > 1:
		step.x = area.x / float(columns - 1)
	if rows > 1:
		step.y = area.y / float(rows - 1)

	var offset := -area * 0.5
	offset += Vector2(step.x * float(column), step.y * float(row))
	offset += stack_offset * float(spawn_index % maxi(columns, rows))
	offset += Vector2(
		_rng.randf_range(-spread_jitter.x, spread_jitter.x),
		_rng.randf_range(-spread_jitter.y, spread_jitter.y)
	)
	return offset


func _update_popup_positions() -> void:
	for popup_index in _active_popup_indices:
		var sprite := _get_popup_sprite(popup_index)
		if not is_instance_valid(sprite) or not sprite.visible:
			continue
		_position_popup(sprite, popup_index)


func _position_popup(sprite: Sprite2D, popup_index: int) -> void:
	var offset := _popup_offsets.get(popup_index, Vector2.ZERO) as Vector2
	sprite.global_position = _get_popup_anchor_position() + offset


func _get_popup_anchor_position() -> Vector2:
	if is_instance_valid(_popup_anchor):
		return _popup_anchor.global_position + popup_anchor_offset

	return global_position


func _filter_popup_anchors(anchor_candidates: Array) -> Array[Node2D]:
	var anchors: Array[Node2D] = []
	for candidate in anchor_candidates:
		var anchor := candidate as Node2D
		if is_instance_valid(anchor):
			anchors.append(anchor)
	return anchors


func _select_popup_anchor() -> Node2D:
	if _popup_anchor_candidates.is_empty():
		return null

	return _popup_anchor_candidates[_rng.randi_range(0, _popup_anchor_candidates.size() - 1)]


func _hide_all_popups() -> void:
	for popup_index in _popup_tweens.keys():
		_kill_popup_tween(int(popup_index))

	_popup_offsets.clear()
	_active_popup_indices.clear()
	_popup_spawn_order.clear()
	_popup_closing_indices.clear()
	_popup_spawn_index = 0
	_popup_spawn_cooldown = 0.0
	_popup_burst_running = false
	_popup_anchor_candidates.clear()
	_popup_anchor = null
	for sprite in _popup_sprites:
		if sprite == null:
			continue
		sprite.hide()
		sprite.modulate = Color.WHITE
		sprite.top_level = false
		_restore_popup_scene_transform(sprite, _popup_sprites.find(sprite))

	for popup_index in _popup_buttons.keys():
		_hide_popup_button(int(popup_index))


func _auto_hide_popup(popup_index: int) -> void:
	_popup_tweens.erase(popup_index)
	_finalize_popup_hidden(popup_index)


func _close_popup_by_index(popup_index: int, animate: bool) -> void:
	var sprite := _get_popup_sprite(popup_index)
	if not is_instance_valid(sprite):
		_finalize_popup_hidden(popup_index)
		return

	_kill_popup_tween(popup_index)
	_popup_closing_indices.erase(popup_index)
	if not animate:
		_finalize_popup_hidden(popup_index)
		return

	var tween := create_tween()
	var target_scale := sprite.global_scale
	_popup_tweens[popup_index] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "global_scale", target_scale * 0.85, 0.16)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.16)
	tween.tween_callback(Callable(self, "_auto_hide_popup").bind(popup_index))


func _finalize_popup_hidden(popup_index: int) -> void:
	var sprite := _get_popup_sprite(popup_index)
	if is_instance_valid(sprite):
		sprite.hide()
		sprite.modulate = Color.WHITE
		sprite.top_level = false
		_restore_popup_scene_transform(sprite, popup_index)

	_popup_offsets.erase(popup_index)
	_active_popup_indices.erase(popup_index)
	_popup_closing_indices.erase(popup_index)
	_hide_popup_button(popup_index)


func _kill_popup_tween(popup_index: int) -> void:
	var tween := _popup_tweens.get(popup_index) as Tween
	if tween != null:
		tween.kill()
	_popup_tweens.erase(popup_index)


func _get_popup_sprite(popup_index: int) -> Sprite2D:
	if popup_index < 0 or popup_index >= _popup_sprites.size():
		return null

	return _popup_sprites[popup_index]


func _restore_popup_scene_transform(sprite: Sprite2D, popup_index: int) -> void:
	if not is_instance_valid(sprite) or popup_index < 0:
		return

	sprite.z_as_relative = true
	sprite.position = _popup_base_positions.get(popup_index, sprite.position) as Vector2
	sprite.rotation = float(_popup_base_rotations.get(popup_index, sprite.rotation))
	sprite.scale = _popup_base_scales.get(popup_index, sprite.scale) as Vector2


func _apply_popup_layering() -> void:
	z_as_relative = false
	z_index = ADWARE_BODY_Z_INDEX
	var popup_container := get_node_or_null(popup_container_path) as CanvasItem
	if popup_container != null:
		popup_container.z_as_relative = false
		popup_container.z_index = POPUP_Z_INDEX_BASE
	if is_instance_valid(_health_bar):
		_health_bar.z_as_relative = false
		_health_bar.z_index = HEALTH_BAR_Z_INDEX


func _ensure_close_button_template() -> void:
	if is_instance_valid(_close_button_template):
		return

	_close_button_template = get_node_or_null(popup_close_button_template_path) as Area2D
	if not is_instance_valid(_close_button_template):
		return

	_close_button_template.hide()
	_close_button_template.monitoring = false
	_close_button_template.input_pickable = false


func _configure_popup_close_button(popup_index: int, sprite: Sprite2D) -> void:
	var button := _get_popup_close_button(popup_index, sprite)
	if not is_instance_valid(button):
		return

	button.set_meta("popup_index", popup_index)
	button.show()
	button.monitoring = true
	button.input_pickable = true

	var button_sprite := _get_close_button_sprite(button)
	if button_sprite == null:
		return
	if button_sprite.sprite_frames != null and button_sprite.sprite_frames.has_animation(CLOSE_BUTTON_ANIMATION):
		button_sprite.animation = CLOSE_BUTTON_ANIMATION
	button_sprite.frame = 0
	button_sprite.frame_progress = 0.0
	button_sprite.stop()
	button_sprite.show()


func _get_popup_close_button(popup_index: int, sprite: Sprite2D) -> Area2D:
	var existing := _popup_buttons.get(popup_index) as Area2D
	if is_instance_valid(existing):
		return existing
	_popup_buttons.erase(popup_index)

	_ensure_close_button_template()
	if not is_instance_valid(_close_button_template):
		return null

	var button := _close_button_template.duplicate() as Area2D
	if button == null:
		return null

	button.name = "RedButtonCollision"
	sprite.add_child(button)
	button.input_event.connect(Callable(self, "_on_popup_close_button_input_event").bind(button))
	_popup_buttons[popup_index] = button
	return button


func _hide_popup_button(popup_index: int) -> void:
	var button := _popup_buttons.get(popup_index) as Area2D
	if not is_instance_valid(button):
		return

	button.hide()
	button.monitoring = false
	button.input_pickable = false
	button.set_meta("popup_index", -1)

	var button_sprite := _get_close_button_sprite(button)
	if button_sprite != null:
		button_sprite.stop()
		button_sprite.frame = 0
		button_sprite.frame_progress = 0.0


func _get_close_button_sprite(button: Area2D) -> AnimatedSprite2D:
	if button == null:
		return null

	return button.get_node_or_null(^"ExitButton") as AnimatedSprite2D


func _on_popup_close_button_input_event(
	_viewport: Viewport,
	event: InputEvent,
	_shape_idx: int,
	button: Area2D
) -> void:
	if not _is_popup_press_event(event):
		return

	var popup_index := int(button.get_meta("popup_index", -1))
	if popup_index < 0:
		return

	_press_popup_button(popup_index)
	get_viewport().set_input_as_handled()


func _is_popup_press_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		return mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed
	if event is InputEventScreenTouch:
		var screen_touch := event as InputEventScreenTouch
		return screen_touch.pressed

	return false


func _button_contains_global_point(button: Area2D, global_point: Vector2) -> bool:
	var shape_node := button.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return false

	var rectangle := shape_node.shape as RectangleShape2D
	if rectangle == null:
		return false

	var local_point := shape_node.to_local(global_point)
	return Rect2(-rectangle.size * 0.5, rectangle.size).has_point(local_point)


func _press_popup_button(popup_index: int) -> void:
	if _popup_closing_indices.has(popup_index):
		return
	_popup_closing_indices[popup_index] = true
	_kill_popup_tween(popup_index)

	var button := _popup_buttons.get(popup_index) as Area2D
	if is_instance_valid(button):
		button.monitoring = false
		button.input_pickable = false
		var button_sprite := _get_close_button_sprite(button)
		if button_sprite != null:
			if button_sprite.sprite_frames != null and button_sprite.sprite_frames.has_animation(CLOSE_BUTTON_ANIMATION):
				button_sprite.animation = CLOSE_BUTTON_ANIMATION
			button_sprite.frame = 0
			button_sprite.frame_progress = 0.0
			button_sprite.play()

	var tween := create_tween()
	_popup_tweens[popup_index] = tween
	tween.tween_interval(close_button_press_duration)
	tween.tween_callback(Callable(self, "_close_popup_after_button_press").bind(popup_index))


func _close_popup_after_button_press(popup_index: int) -> void:
	_popup_tweens.erase(popup_index)
	_close_popup_by_index(popup_index, true)


func _on_health_changed(new_health: int, new_max_health: int) -> void:
	_ensure_health_bar()
	_set_health_bar_health(new_health, new_max_health, true)


func _ensure_health_bar() -> void:
	if is_instance_valid(_health_bar):
		return

	_health_bar = get_node_or_null(health_bar_root_path) as TrojanHorseProgressBar
	if not is_instance_valid(_health_bar):
		return

	_health_bar.top_level = true
	_health_bar.z_as_relative = false
	_health_bar.z_index = HEALTH_BAR_Z_INDEX
	_health_bar.modulate = Color.WHITE
	_set_health_bar_health(current_health, max_health, false)


func _set_health_bar_visible(value: bool) -> void:
	_ensure_health_bar()
	if not is_instance_valid(_health_bar):
		return

	_health_bar.set_bar_visible(value)


func _set_health_bar_health(current: int, maximum: int, animate: bool) -> void:
	_ensure_health_bar()
	if not is_instance_valid(_health_bar):
		return

	_health_bar.set_health(current, maxi(1, maximum), animate)


func _position_health_bar() -> void:
	if not is_instance_valid(_health_bar):
		return

	_health_bar.global_position = global_position + health_bar_offset
	_health_bar.global_rotation = 0.0
