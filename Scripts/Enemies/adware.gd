class_name Adware
extends Node2D

const POPUP_GROUP := "ADWARE"

@export var popup_display_scale := Vector2(0.18, 0.18)
@export var random_rotation_degrees := 4.0
@export var lifespan_seconds := 12.0
@export var popup_container_path: NodePath = ^"Popups"
@export_group("Spawn Spread")
@export_range(1, 12, 1) var spread_columns: int = 5
@export_range(1, 12, 1) var spread_rows: int = 4
@export var spread_center_ratio := Vector2(0.5, 0.48)
@export var spread_size := Vector2(420.0, 260.0)
@export var spread_jitter := Vector2(52.0, 34.0)
@export var stack_offset := Vector2(14.0, 10.0)
@export var screen_padding := Vector2(80.0, 70.0)
@export_group("")

var _popup_sprites: Array[Sprite2D] = []
var _selected_index := -1

func _ready() -> void:
	add_to_group(POPUP_GROUP)
	_collect_popup_sprites()
	_apply_selected_popup()
	_play_popup_animation()


func setup(variation_index: int = -1) -> void:
	_selected_index = variation_index
	if is_inside_tree():
		_collect_popup_sprites()
		_apply_selected_popup()


func get_spawn_screen_position(spawn_index: int, viewport_size: Vector2, rng: RandomNumberGenerator) -> Vector2:
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

	var screen_position := (viewport_size * spread_center_ratio) - (area * 0.5)
	screen_position += Vector2(step.x * float(column), step.y * float(row))
	screen_position += stack_offset * float(spawn_index % maxi(columns, rows))
	screen_position += Vector2(
		rng.randf_range(-spread_jitter.x, spread_jitter.x),
		rng.randf_range(-spread_jitter.y, spread_jitter.y)
	)

	return Vector2(
		clampf(screen_position.x, screen_padding.x, maxf(screen_padding.x, viewport_size.x - screen_padding.x)),
		clampf(screen_position.y, screen_padding.y, maxf(screen_padding.y, viewport_size.y - screen_padding.y))
	)


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


func _apply_selected_popup() -> void:
	if _popup_sprites.is_empty():
		return

	if _selected_index < 0 or _selected_index >= _popup_sprites.size():
		_selected_index = randi_range(0, _popup_sprites.size() - 1)

	for index in range(_popup_sprites.size()):
		var sprite := _popup_sprites[index]
		sprite.visible = index == _selected_index
		sprite.scale = popup_display_scale
		sprite.modulate = Color.WHITE

	var selected_sprite := _popup_sprites[_selected_index]
	selected_sprite.rotation_degrees = randf_range(-random_rotation_degrees, random_rotation_degrees)


func _play_popup_animation() -> void:
	if _popup_sprites.is_empty():
		return

	var selected_sprite := _popup_sprites[_selected_index]
	selected_sprite.scale = popup_display_scale * 0.2
	selected_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(selected_sprite, "scale", popup_display_scale * 1.08, 0.18)
	tween.parallel().tween_property(selected_sprite, "modulate:a", 1.0, 0.12)
	tween.tween_property(selected_sprite, "scale", popup_display_scale, 0.09)
	if lifespan_seconds > 0.0:
		tween.tween_interval(lifespan_seconds)
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(selected_sprite, "scale", popup_display_scale * 0.85, 0.18)
		tween.parallel().tween_property(selected_sprite, "modulate:a", 0.0, 0.18)
		tween.tween_callback(queue_free)
