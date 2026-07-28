@tool
class_name TowerShopCard
extends Control

const INFORMATION_POPUP_CANVAS_LAYER := 12000

@export var card_resource: TowerShopCardResource:
	set(value):
		card_resource = value
		_sync_text()

@export var tower_name := "Tower":
	set(value):
		tower_name = value
		_sync_text()

@export var deploy_cost := 0:
	set(value):
		deploy_cost = maxi(0, value)
		_sync_text()

@export var free_text := "FREE":
	set(value):
		free_text = value
		_sync_text()

@export_group("State Colors")
@export var normal_cost_color := Color(1.0, 0.86, 0.24, 1.0)
@export var unaffordable_cost_color := Color(1.0, 0.18, 0.16, 1.0)
@export var deployed_cost_color := Color(0.72, 0.84, 0.92, 1.0)
@export var normal_visual_modulate := Color.WHITE
@export var disabled_visual_modulate := Color(0.42, 0.42, 0.42, 1.0)
@export var dragging_border_color := Color(1.0, 0.84, 0.18, 1.0)
@export var dragging_shadow_color := Color(1.0, 0.78, 0.18, 0.72)
@export_range(0, 48, 1) var dragging_shadow_size := 18
@export_group("Editable Nodes")
@export var card_panel_path: NodePath = ^"CardPanel"
@export var name_label_path: NodePath = ^"NameLabel"
@export var cost_label_path: NodePath = ^"CostLabel"
@export var display_image_container_path: NodePath = ^"DisplayImageContainer"
@export var display_sprite_path: NodePath = ^"DisplayImageContainer/DisplaySprite"
@export var information_button_path: NodePath = ^"InformationButton"
@export var information_popup_path: NodePath = ^"InformationPopup"
@export var information_popup_card_path: NodePath = ^"InformationPopup/PopupCard"
@export var information_close_button_path: NodePath = ^"InformationPopup/PopupCard/ExitButton"
@export var information_popup_image_path: NodePath = ^"InformationPopup/PopupCard/ImagePanel/PopupSprite"
@export var information_header_label_path: NodePath = ^"InformationPopup/PopupCard/HeaderLabel"
@export var information_description_label_path: NodePath = ^"InformationPopup/PopupCard/DescriptionLabel"
@export var information_type_label_path: NodePath = ^"InformationPopup/PopupCard/TypeLabel"
@export var information_upgrade_costs_label_path: NodePath = ^"InformationPopup/PopupCard/UpgradeCostsLabel"
@export_group("")
@export_group("Editable Display Sprites")
@export var preserve_authored_sprite_textures := true
@export var auto_center_information_sprite := false
@export_group("")
@export_group("Information Popup Animation")
@export_range(0.0, 800.0, 1.0) var information_popup_slide_offset := 260.0
@export_range(0.01, 1.0, 0.01) var information_popup_enter_seconds := 0.24
@export_range(0.01, 1.0, 0.01) var information_popup_exit_seconds := 0.14
@export_group("")

@onready var card_panel: Control = get_node_or_null(card_panel_path) as Control
@onready var name_label: Label = get_node_or_null(name_label_path) as Label
@onready var cost_label: Label = get_node_or_null(cost_label_path) as Label
@onready var display_image_container: Control = get_node_or_null(display_image_container_path) as Control
@onready var display_sprite: Sprite2D = get_node_or_null(display_sprite_path) as Sprite2D
@onready var information_button: Button = get_node_or_null(information_button_path) as Button
@onready var information_popup: Control = get_node_or_null(information_popup_path) as Control
@onready var information_popup_card: Control = get_node_or_null(information_popup_card_path) as Control
@onready var information_close_button: Button = get_node_or_null(information_close_button_path) as Button
@onready var information_popup_image: Sprite2D = get_node_or_null(information_popup_image_path) as Sprite2D
@onready var information_header_label: Label = get_node_or_null(information_header_label_path) as Label
@onready var information_description_label: Label = get_node_or_null(information_description_label_path) as Label
@onready var information_type_label: Label = get_node_or_null(information_type_label_path) as Label
@onready var information_upgrade_costs_label: Label = get_node_or_null(information_upgrade_costs_label_path) as Label

var _can_afford := true
var _deployed := false
var _dragging := false
var _normal_card_panel_style: StyleBox
var _dragging_card_panel_style: StyleBox
var _was_tree_paused_before_information := false
var _information_popup_tween: Tween
var _information_popup_layer: CanvasLayer
var _information_popup_card_rest_position := Vector2.ZERO
var _information_popup_card_rest_scale := Vector2.ONE
var _information_popup_card_rest_transform_cached := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_editable_nodes()
	_cache_card_panel_styles()
	_connect_information_buttons()
	_setup_information_popup()
	_sync_sprite_texture_fallbacks()
	_sync_text()


func use_default_information_popup_paths() -> void:
	information_popup_path = ^"InformationPopup"
	information_popup_card_path = ^"InformationPopup/PopupCard"
	information_close_button_path = ^"InformationPopup/PopupCard/ExitButton"
	information_popup_image_path = ^"InformationPopup/PopupCard/ImagePanel/PopupSprite"
	information_header_label_path = ^"InformationPopup/PopupCard/HeaderLabel"
	information_description_label_path = ^"InformationPopup/PopupCard/DescriptionLabel"
	information_type_label_path = ^"InformationPopup/PopupCard/TypeLabel"
	information_upgrade_costs_label_path = ^"InformationPopup/PopupCard/UpgradeCostsLabel"

	if not is_node_ready():
		return

	_resolve_editable_nodes()
	_connect_information_buttons()
	_setup_information_popup()
	_sync_text()


func _resolve_editable_nodes() -> void:
	card_panel = _get_editable_node(card_panel_path) as Control
	name_label = _get_editable_node(name_label_path) as Label
	cost_label = _get_editable_node(cost_label_path) as Label
	display_image_container = _get_editable_node(display_image_container_path) as Control
	display_sprite = _get_editable_node(display_sprite_path) as Sprite2D
	information_button = _get_editable_node(information_button_path) as Button
	information_popup = _get_editable_node(information_popup_path) as Control
	information_popup_card = _get_editable_node(information_popup_card_path) as Control
	information_close_button = _get_editable_node(information_close_button_path) as Button
	information_popup_image = _get_editable_node(information_popup_image_path) as Sprite2D
	information_header_label = _get_editable_node(information_header_label_path) as Label
	information_description_label = _get_editable_node(information_description_label_path) as Label
	information_type_label = _get_editable_node(information_type_label_path) as Label
	information_upgrade_costs_label = _get_editable_node(information_upgrade_costs_label_path) as Label


func _get_editable_node(path: NodePath) -> Node:
	var node := get_node_or_null(path)
	if node == null and _information_popup_layer != null:
		node = _information_popup_layer.get_node_or_null(path)
	return node


func _connect_information_buttons() -> void:
	if information_button != null:
		var info_pressed_callback := Callable(self, "open_information_popup")
		if not information_button.pressed.is_connected(info_pressed_callback):
			information_button.pressed.connect(info_pressed_callback)
	if information_close_button != null:
		var close_pressed_callback := Callable(self, "close_information_popup")
		if not information_close_button.pressed.is_connected(close_pressed_callback):
			information_close_button.pressed.connect(close_pressed_callback)


func _setup_information_popup() -> void:
	if information_popup != null:
		information_popup.process_mode = Node.PROCESS_MODE_ALWAYS
		information_popup.mouse_filter = Control.MOUSE_FILTER_STOP
		information_popup.top_level = true
		information_popup.z_as_relative = false
		information_popup.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
		if not Engine.is_editor_hint():
			information_popup.hide()
	if _information_popup_layer != null:
		_information_popup_layer.visible = false


func _ensure_information_popup_layer() -> void:
	if Engine.is_editor_hint() or information_popup == null:
		return

	if _information_popup_layer == null:
		_information_popup_layer = CanvasLayer.new()
		_information_popup_layer.name = name + "InformationPopupLayer"
		_information_popup_layer.layer = INFORMATION_POPUP_CANVAS_LAYER
		_information_popup_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		_information_popup_layer.visible = false
		add_child(_information_popup_layer)

	_information_popup_layer.layer = INFORMATION_POPUP_CANVAS_LAYER
	if information_popup.get_parent() == _information_popup_layer:
		return

	var was_visible := information_popup.visible
	var previous_global_position := information_popup.global_position
	var popup_parent := information_popup.get_parent()
	if popup_parent != null:
		popup_parent.remove_child(information_popup)
	_information_popup_layer.add_child(information_popup)
	information_popup.global_position = previous_global_position
	information_popup.visible = was_visible


func configure(display_name: String, cost: int) -> void:
	if card_resource != null:
		_sync_text()
		return

	tower_name = display_name
	deploy_cost = cost
	_sync_text()


func has_card_resource() -> bool:
	return card_resource != null


func get_display_name() -> String:
	return card_resource.display_name if card_resource != null else tower_name


func get_deploy_cost() -> int:
	return maxi(0, card_resource.deploy_cost if card_resource != null else deploy_cost)


func get_tower_id() -> StringName:
	return card_resource.tower_id if card_resource != null else &""


func get_information_header() -> String:
	if card_resource != null and not card_resource.info_header.is_empty():
		return card_resource.info_header

	return get_display_name()


func get_information_description() -> String:
	if card_resource != null and not card_resource.info_description.is_empty():
		return card_resource.info_description

	return "No tower information configured yet."


func get_tower_type() -> String:
	if card_resource != null and not card_resource.tower_type.is_empty():
		return card_resource.tower_type

	return "Tower"


func get_upgrade_costs() -> Array[int]:
	if card_resource != null:
		return card_resource.upgrade_costs
	var no_upgrade_costs: Array[int] = []
	return no_upgrade_costs


func set_store_state(can_afford: bool, deployed: bool) -> void:
	_can_afford = can_afford
	_deployed = deployed
	_sync_text()


func set_drag_highlight(active: bool) -> void:
	if _dragging == active:
		return

	_dragging = active
	_sync_visual_state()


func toggle_information_popup() -> void:
	if information_popup != null and information_popup.visible:
		close_information_popup()
	else:
		open_information_popup()


func set_information_popup_visible(visible: bool) -> void:
	if visible:
		open_information_popup()
	else:
		close_information_popup()


func open_information_popup() -> void:
	if information_popup == null:
		return

	_ensure_information_popup_layer()
	_sync_information_popup()
	_sync_information_popup_layout()
	if _information_popup_tween != null:
		_information_popup_tween.kill()

	if _information_popup_layer != null:
		_information_popup_layer.visible = true
	if not information_popup.visible:
		_was_tree_paused_before_information = get_tree().paused
		get_tree().paused = true
		information_popup.modulate = Color(1, 1, 1, 0)
		if information_popup_card != null:
			_cache_information_popup_card_rest_transform()
			information_popup_card.position = _information_popup_card_rest_position + Vector2(information_popup_slide_offset, 0.0)
			information_popup_card.scale = _information_popup_card_rest_scale
		information_popup.show()

	_information_popup_tween = create_tween()
	_information_popup_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_information_popup_tween.set_parallel(true)
	_information_popup_tween.tween_property(information_popup, "modulate:a", 1.0, information_popup_enter_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if information_popup_card != null:
		_information_popup_tween.tween_property(information_popup_card, "position", _information_popup_card_rest_position, information_popup_enter_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_information_popup_tween.set_parallel(false)
	_information_popup_tween.tween_callback(func() -> void:
		_information_popup_tween = null
	)


func close_information_popup() -> void:
	if information_popup == null or not information_popup.visible:
		return

	if _information_popup_tween != null:
		_information_popup_tween.kill()

	_information_popup_tween = create_tween()
	_information_popup_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_information_popup_tween.set_parallel(true)
	_information_popup_tween.tween_property(information_popup, "modulate:a", 0.0, information_popup_exit_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if information_popup_card != null:
		_cache_information_popup_card_rest_transform()
		_information_popup_tween.tween_property(information_popup_card, "position", _information_popup_card_rest_position + Vector2(information_popup_slide_offset, 0.0), information_popup_exit_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_information_popup_tween.set_parallel(false)
	_information_popup_tween.tween_callback(func() -> void:
		if _information_popup_layer != null:
			_information_popup_layer.visible = false
		information_popup.hide()
		information_popup.modulate = Color.WHITE
		if information_popup_card != null:
			information_popup_card.position = _information_popup_card_rest_position
			information_popup_card.scale = _information_popup_card_rest_scale
		get_tree().paused = _was_tree_paused_before_information
		_information_popup_tween = null
	)


func information_button_has_point(global_point: Vector2) -> bool:
	return information_button != null \
		and information_button.visible \
		and information_button.get_global_rect().has_point(global_point)


func information_popup_has_point(global_point: Vector2) -> bool:
	return information_popup != null \
		and information_popup.visible \
		and information_popup.get_global_rect().has_point(global_point)


func handle_information_press(global_point: Vector2) -> bool:
	if information_button_has_point(global_point):
		open_information_popup()
		return true

	return information_popup_has_point(global_point)


func _sync_text() -> void:
	if not is_node_ready():
		return

	var resolved_name := get_display_name()
	var resolved_cost := get_deploy_cost()
	var resolved_free_text := card_resource.free_text if card_resource != null else free_text

	if name_label != null:
		name_label.text = resolved_name
	if cost_label != null:
		if _deployed:
			cost_label.text = "Deployed"
			cost_label.add_theme_color_override("font_color", deployed_cost_color)
		else:
			cost_label.text = resolved_free_text if resolved_cost <= 0 else str(resolved_cost)
			cost_label.add_theme_color_override("font_color", normal_cost_color if _can_afford else unaffordable_cost_color)
	_sync_sprite_texture_fallbacks()
	if information_popup != null and information_popup.visible:
		_sync_information_popup()
	_sync_visual_state()


func _sync_visual_state() -> void:
	_sync_card_panel_style()
	var visual_modulate := disabled_visual_modulate if _deployed or not _can_afford else normal_visual_modulate
	_apply_canvas_item_modulate(card_panel, visual_modulate)
	_apply_canvas_item_modulate(display_image_container, visual_modulate)
	_apply_canvas_item_modulate(display_sprite, visual_modulate)
	_apply_canvas_item_modulate(name_label, visual_modulate)
	if cost_label != null:
		cost_label.modulate = Color.WHITE


func _apply_canvas_item_modulate(item: CanvasItem, value: Color) -> void:
	if item != null:
		item.modulate = value


func _cache_card_panel_styles() -> void:
	if card_panel == null:
		return

	var base_style := card_panel.get_theme_stylebox("panel")
	if base_style == null:
		return

	_normal_card_panel_style = base_style.duplicate()
	_dragging_card_panel_style = base_style.duplicate()
	var flat_style := _dragging_card_panel_style as StyleBoxFlat
	if flat_style != null:
		flat_style.border_color = dragging_border_color
		flat_style.shadow_color = dragging_shadow_color
		flat_style.shadow_size = dragging_shadow_size
		flat_style.border_width_left = maxi(flat_style.border_width_left, 3)
		flat_style.border_width_top = maxi(flat_style.border_width_top, 3)
		flat_style.border_width_right = maxi(flat_style.border_width_right, 3)
		flat_style.border_width_bottom = maxi(flat_style.border_width_bottom, 3)


func _sync_card_panel_style() -> void:
	if card_panel == null:
		return

	var style := _dragging_card_panel_style if _dragging and _dragging_card_panel_style != null else _normal_card_panel_style
	if style != null:
		card_panel.add_theme_stylebox_override("panel", style)


func _sync_information_popup() -> void:
	_sync_sprite_texture_fallbacks()
	if information_header_label != null:
		information_header_label.text = get_information_header()
	if information_description_label != null:
		information_description_label.text = get_information_description()
	if information_type_label != null:
		information_type_label.text = "Type: " + get_tower_type()
	if information_upgrade_costs_label != null:
		information_upgrade_costs_label.text = _format_information_costs()


func _sync_information_popup_layout() -> void:
	if information_popup == null:
		return

	var viewport_size := get_viewport_rect().size
	information_popup.global_position = Vector2.ZERO
	information_popup.position = Vector2.ZERO
	information_popup.size = viewport_size
	if information_popup_card == null:
		return

	_cache_information_popup_card_rest_transform()
	if information_popup_image != null and auto_center_information_sprite:
		var image_panel := information_popup_image.get_parent() as Control
		if image_panel != null:
			information_popup_image.position = image_panel.size * 0.5


func _sync_sprite_texture_fallbacks() -> void:
	var resource_texture: Texture2D = card_resource.display_texture if card_resource != null else null
	if display_sprite != null and resource_texture != null:
		if not preserve_authored_sprite_textures or display_sprite.texture == null:
			display_sprite.texture = resource_texture

	if information_popup_image == null:
		return
	if preserve_authored_sprite_textures and information_popup_image.texture != null:
		return

	if display_sprite != null and display_sprite.texture != null:
		information_popup_image.texture = display_sprite.texture
	elif resource_texture != null:
		information_popup_image.texture = resource_texture


func _cache_information_popup_card_rest_transform() -> void:
	if information_popup_card == null:
		return
	if _information_popup_card_rest_transform_cached:
		return

	_information_popup_card_rest_position = information_popup_card.position
	_information_popup_card_rest_scale = information_popup_card.scale
	_information_popup_card_rest_transform_cached = true


func _format_information_costs() -> String:
	var lines: Array[String] = []
	lines.append("Deploy: " + _format_cost(get_deploy_cost()))

	var upgrade_costs := get_upgrade_costs()
	if upgrade_costs.is_empty():
		lines.append("Upgrades: None")
	else:
		lines.append("Upgrade Costs:")
		for index in range(upgrade_costs.size()):
			lines.append("LV%d -> LV%d: %s" % [index + 1, index + 2, _format_cost(upgrade_costs[index])])

	var output := ""
	for index in range(lines.size()):
		if index > 0:
			output += "\n"
		output += lines[index]
	return output


func _format_cost(cost: int) -> String:
	return "FREE" if cost <= 0 else str(cost) + " Cyber Bucks"
