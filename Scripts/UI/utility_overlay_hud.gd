class_name UtilityOverlayHUD
extends CanvasLayer

const TowerTooltips := preload("res://Scripts/UI/tower_tooltip_data.gd")

signal laser_upgrade_requested
signal guardian_upgrade_requested
signal scanner_upgrade_requested
signal edr_upgrade_requested
signal siem_upgrade_requested
signal siem_hawk_freeze_requested
signal siem_hawk_land_requested
signal ips_upgrade_requested
signal honeypot_upgrade_requested

const POPUP_DURATION := 1.45
const BUCKS_ICON_SIZE := Vector2(38, 38)
const UPGRADE_BUTTON_OFFSET := Vector2(0, -114)
const UPGRADE_BUTTON_FALLBACK_OFFSET := Vector2(0, 114)
const SIEM_HAWK_ACTION_OFFSET := Vector2(132, -34)
const SIEM_HAWK_ACTION_FALLBACK_OFFSET := Vector2(132, 116)
const VIEWPORT_EDGE_PADDING := Vector2(12, 12)
const SPARKLE_DOT_COUNT := 22
const SPARKLE_RADIUS_MIN := 20.0
const SPARKLE_RADIUS_MAX := 118.0
const COST_READY_COLOR := Color(0.91, 0.98, 1.0, 1.0)
const COST_LOCKED_COLOR := Color(1.0, 0.48, 0.48, 1.0)

@export var naked_power_font: Font
@export var cyber_bucks_texture: Texture2D

@onready var _world_popups: Control = $Root/WorldPopups
@onready var _guardian_upgrade_button: Button = $Root/GuardianUpgradeButton
@onready var _guardian_upgrade_cost_label: Label = $Root/GuardianUpgradeButton/Content/CostRow/Amount
@onready var _laser_upgrade_button: Button = $Root/LaserUpgradeButton
@onready var _laser_upgrade_cost_label: Label = $Root/LaserUpgradeButton/Content/CostRow/Amount
@onready var _scanner_upgrade_button: Button = $Root/ScannerUpgradeButton
@onready var _scanner_upgrade_cost_label: Label = $Root/ScannerUpgradeButton/Content/CostRow/Amount

var _edr_upgrade_button: Button
var _edr_upgrade_cost_label: Label
var _siem_upgrade_button: Button
var _siem_upgrade_cost_label: Label
var _siem_hawk_action_panel: PanelContainer
var _siem_hawk_land_button: Button
var _siem_hawk_freeze_button: Button
var _ips_upgrade_button: Button
var _ips_upgrade_cost_label: Label
var _honeypot_upgrade_button: Button
var _honeypot_upgrade_cost_label: Label


func _ready() -> void:
	_configure_upgrade_button(_guardian_upgrade_button)
	_configure_upgrade_button(_laser_upgrade_button)
	_configure_upgrade_button(_scanner_upgrade_button)
	_edr_upgrade_button = _create_extra_upgrade_button("EDRUpgradeButton")
	_edr_upgrade_cost_label = _get_upgrade_cost_label(_edr_upgrade_button)
	_siem_upgrade_button = _create_extra_upgrade_button("SIEMUpgradeButton")
	_siem_upgrade_cost_label = _get_upgrade_cost_label(_siem_upgrade_button)
	_create_siem_hawk_action_panel()
	_ips_upgrade_button = _create_extra_upgrade_button("IPSUpgradeButton")
	_ips_upgrade_cost_label = _get_upgrade_cost_label(_ips_upgrade_button)
	_honeypot_upgrade_button = _create_extra_upgrade_button("HoneypotUpgradeButton")
	_honeypot_upgrade_cost_label = _get_upgrade_cost_label(_honeypot_upgrade_button)
	_set_upgrade_button_copy(_guardian_upgrade_button, &"guardian")
	_set_upgrade_button_copy(_laser_upgrade_button, &"laser")
	_set_upgrade_button_copy(_scanner_upgrade_button, &"scanner")
	_set_upgrade_button_copy(_edr_upgrade_button, &"edr")
	_set_upgrade_button_copy(_siem_upgrade_button, &"siem")
	_set_upgrade_button_copy(_ips_upgrade_button, &"ips")
	_set_upgrade_button_copy(_honeypot_upgrade_button, &"honeypot")
	_guardian_upgrade_button.pressed.connect(func() -> void: guardian_upgrade_requested.emit())
	_laser_upgrade_button.pressed.connect(func() -> void: laser_upgrade_requested.emit())
	_scanner_upgrade_button.pressed.connect(func() -> void: scanner_upgrade_requested.emit())
	_edr_upgrade_button.pressed.connect(func() -> void: edr_upgrade_requested.emit())
	_siem_upgrade_button.pressed.connect(func() -> void: siem_upgrade_requested.emit())
	_siem_hawk_land_button.pressed.connect(func() -> void: siem_hawk_land_requested.emit())
	_siem_hawk_freeze_button.pressed.connect(func() -> void: siem_hawk_freeze_requested.emit())
	_ips_upgrade_button.pressed.connect(func() -> void: ips_upgrade_requested.emit())
	_honeypot_upgrade_button.pressed.connect(func() -> void: honeypot_upgrade_requested.emit())


func show_guardian_destroy_popup(
	guardian_position: Vector2,
	damage_points: int,
	damage_cooldown: float
) -> void:
	return


func show_tower_destroy_popup(
	tower_position: Vector2,
	cyberbuck_reward: int,
	damage_points: int,
	damage_cooldown: float
) -> void:
	return


func set_guardian_upgrade_button_state(
	guardian_screen_position: Vector2,
	deployed: bool,
	can_upgrade: bool,
	hovered: bool,
	cost: int,
	affordable: bool
) -> void:
	_set_upgrade_button_state(
		_guardian_upgrade_button,
		_guardian_upgrade_cost_label,
		guardian_screen_position,
		deployed,
		can_upgrade,
		hovered,
		cost,
		affordable
	)


func set_laser_upgrade_button_state(
	laser_screen_position: Vector2,
	deployed: bool,
	can_upgrade: bool,
	hovered: bool,
	cost: int,
	affordable: bool
) -> void:
	_set_upgrade_button_state(
		_laser_upgrade_button,
		_laser_upgrade_cost_label,
		laser_screen_position,
		deployed,
		can_upgrade,
		hovered,
		cost,
		affordable
	)


func set_scanner_upgrade_button_state(
	scanner_screen_position: Vector2,
	deployed: bool,
	can_upgrade: bool,
	hovered: bool,
	cost: int,
	affordable: bool
) -> void:
	_set_upgrade_button_state(
		_scanner_upgrade_button,
		_scanner_upgrade_cost_label,
		scanner_screen_position,
		deployed,
		can_upgrade,
		hovered,
		cost,
		affordable
	)


func set_edr_upgrade_button_state(
	edr_screen_position: Vector2,
	deployed: bool,
	can_upgrade: bool,
	hovered: bool,
	cost: int,
	affordable: bool
) -> void:
	_set_upgrade_button_state(
		_edr_upgrade_button,
		_edr_upgrade_cost_label,
		edr_screen_position,
		deployed,
		can_upgrade,
		hovered,
		cost,
		affordable
	)


func set_siem_upgrade_button_state(
	siem_screen_position: Vector2,
	deployed: bool,
	can_upgrade: bool,
	hovered: bool,
	cost: int,
	affordable: bool
) -> void:
	_set_upgrade_button_state(
		_siem_upgrade_button,
		_siem_upgrade_cost_label,
		siem_screen_position,
		deployed,
		can_upgrade,
		hovered,
		cost,
		affordable
	)


func set_siem_hawk_action_state(
	hawk_screen_position: Vector2,
	deployed: bool,
	hovered: bool,
	dispatched: bool,
	landing_to_headquarters: bool,
	can_land: bool
) -> void:
	if _siem_hawk_action_panel == null:
		return

	_siem_hawk_action_panel.visible = deployed and hovered
	if not _siem_hawk_action_panel.visible:
		return

	_siem_hawk_land_button.disabled = landing_to_headquarters or not can_land
	_siem_hawk_land_button.text = "Landing..." if landing_to_headquarters else "Land to Headquarters"
	_siem_hawk_freeze_button.disabled = landing_to_headquarters
	_siem_hawk_freeze_button.text = "Freeze Mode" if dispatched else "Follow Mode"
	_position_hover_control(
		_siem_hawk_action_panel,
		hawk_screen_position,
		SIEM_HAWK_ACTION_OFFSET,
		SIEM_HAWK_ACTION_FALLBACK_OFFSET
	)


func set_ips_upgrade_button_state(
	ips_screen_position: Vector2,
	deployed: bool,
	can_upgrade: bool,
	hovered: bool,
	cost: int,
	affordable: bool
) -> void:
	_set_upgrade_button_state(
		_ips_upgrade_button,
		_ips_upgrade_cost_label,
		ips_screen_position,
		deployed,
		can_upgrade,
		hovered,
		cost,
		affordable
	)


func set_honeypot_upgrade_button_state(
	honeypot_screen_position: Vector2,
	deployed: bool,
	can_upgrade: bool,
	hovered: bool,
	cost: int,
	affordable: bool
) -> void:
	_set_upgrade_button_state(
		_honeypot_upgrade_button,
		_honeypot_upgrade_cost_label,
		honeypot_screen_position,
		deployed,
		can_upgrade,
		hovered,
		cost,
		affordable
	)


func guardian_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _button_has_point(_guardian_upgrade_button, screen_position)


func laser_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _button_has_point(_laser_upgrade_button, screen_position)


func scanner_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _button_has_point(_scanner_upgrade_button, screen_position)


func edr_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _button_has_point(_edr_upgrade_button, screen_position)


func siem_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _button_has_point(_siem_upgrade_button, screen_position)


func siem_hawk_action_buttons_has_point(screen_position: Vector2) -> bool:
	return _siem_hawk_action_panel != null \
		and _siem_hawk_action_panel.is_visible_in_tree() \
		and _siem_hawk_action_panel.get_global_rect().has_point(screen_position)


func ips_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _button_has_point(_ips_upgrade_button, screen_position)


func honeypot_upgrade_button_has_point(screen_position: Vector2) -> bool:
	return _button_has_point(_honeypot_upgrade_button, screen_position)


func upgrade_button_has_point(screen_position: Vector2) -> bool:
	return guardian_upgrade_button_has_point(screen_position) \
		or laser_upgrade_button_has_point(screen_position) \
		or scanner_upgrade_button_has_point(screen_position) \
		or edr_upgrade_button_has_point(screen_position) \
		or siem_upgrade_button_has_point(screen_position) \
		or siem_hawk_action_buttons_has_point(screen_position) \
		or ips_upgrade_button_has_point(screen_position) \
		or honeypot_upgrade_button_has_point(screen_position)


func show_laser_upgrade_fx(laser_position: Vector2) -> void:
	show_tower_upgrade_fx(laser_position)


func show_tower_upgrade_fx(tower_position: Vector2) -> void:
	var evolve_label := _make_popup_label("EVOLVED", 30, Color(0.48, 0.83, 1.0, 1.0))
	evolve_label.add_theme_color_override("font_outline_color", Color(0.02, 0.07, 0.22, 1.0))
	_world_popups.add_child(evolve_label)
	_position_popup(evolve_label, tower_position + Vector2(0, -138), Vector2(0.5, 0.5))
	_animate_popup(evolve_label, Vector2(0, -64))

	for index in range(SPARKLE_DOT_COUNT):
		_spawn_sparkle_dot(tower_position, index)


func _configure_upgrade_button(button: Button) -> void:
	button.hide()
	button.add_theme_font_override("font", naked_power_font)


func _create_extra_upgrade_button(button_name: String) -> Button:
	var button := _scanner_upgrade_button.duplicate() as Button
	button.name = button_name
	_scanner_upgrade_button.get_parent().add_child(button)
	_configure_upgrade_button(button)
	return button


func _get_upgrade_cost_label(button: Button) -> Label:
	return button.get_node(^"Content/CostRow/Amount") as Label


func _create_siem_hawk_action_panel() -> void:
	_siem_hawk_action_panel = PanelContainer.new()
	_siem_hawk_action_panel.name = "SIEMHawkActionPanel"
	_siem_hawk_action_panel.visible = false
	_siem_hawk_action_panel.z_as_relative = false
	_siem_hawk_action_panel.z_index = 1000
	_siem_hawk_action_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.028, 0.054, 0.12, 0.94)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.42, 0.78, 1.0, 0.96)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.shadow_color = Color(0.08, 0.3, 0.95, 0.42)
	panel_style.shadow_size = 10
	_siem_hawk_action_panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_siem_hawk_action_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	_siem_hawk_land_button = _create_siem_hawk_action_button("Land to Headquarters")
	_siem_hawk_freeze_button = _create_siem_hawk_action_button("Freeze Mode")
	content.add_child(_siem_hawk_land_button)
	content.add_child(_siem_hawk_freeze_button)
	$Root.add_child(_siem_hawk_action_panel)


func _create_siem_hawk_action_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(196, 42)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", naked_power_font)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color(0.72, 0.9, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.35, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.46, 0.55, 0.68, 0.8))
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.16, 1.0))
	button.add_theme_constant_override("outline_size", 3)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.045, 0.088, 0.19, 0.96)
	normal_style.border_width_left = 1
	normal_style.border_width_top = 1
	normal_style.border_width_right = 1
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(0.34, 0.72, 1.0, 0.86)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_right = 6
	normal_style.corner_radius_bottom_left = 6

	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.08, 0.15, 0.31, 0.98)
	hover_style.border_color = Color(1.0, 0.86, 0.24, 1.0)

	var disabled_style := normal_style.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(0.035, 0.047, 0.072, 0.88)
	disabled_style.border_color = Color(0.28, 0.34, 0.44, 0.86)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	return button


func _set_upgrade_button_copy(button: Button, tower_id: StringName) -> void:
	var label := button.get_node_or_null(^"Content/UpgradeLabel") as Label
	if label != null:
		label.text = "Upgrade"

	button.tooltip_text = TowerTooltips.tower_tooltip(tower_id) + "\n\n" + TowerTooltips.tower_upgrade_tooltip(tower_id)


func _set_upgrade_button_state(
	button: Button,
	cost_label: Label,
	screen_position: Vector2,
	deployed: bool,
	can_upgrade: bool,
	hovered: bool,
	cost: int,
	affordable: bool
) -> void:
	button.visible = deployed and can_upgrade and hovered
	if not button.visible:
		return

	button.disabled = not affordable
	cost_label.text = str(maxi(0, cost))
	cost_label.add_theme_color_override("font_color", COST_READY_COLOR if affordable else COST_LOCKED_COLOR)
	_position_hover_control(button, screen_position, UPGRADE_BUTTON_OFFSET, UPGRADE_BUTTON_FALLBACK_OFFSET)


func _button_has_point(button: Button, screen_position: Vector2) -> bool:
	return button.is_visible_in_tree() and button.get_global_rect().has_point(screen_position)


func _position_hover_control(
	control: Control,
	screen_position: Vector2,
	preferred_offset: Vector2,
	fallback_offset: Vector2
) -> void:
	control.reset_size()
	var control_size := control.size
	if control_size == Vector2.ZERO:
		control_size = control.get_combined_minimum_size()
		control.size = control_size

	var candidate := screen_position + preferred_offset - control_size * 0.5
	if candidate.y < VIEWPORT_EDGE_PADDING.y:
		candidate = screen_position + fallback_offset - control_size * 0.5

	var viewport_size := get_viewport().get_visible_rect().size
	var max_position := viewport_size - control_size - VIEWPORT_EDGE_PADDING
	control.global_position = Vector2(
		clampf(candidate.x, VIEWPORT_EDGE_PADDING.x, maxf(VIEWPORT_EDGE_PADDING.x, max_position.x)),
		clampf(candidate.y, VIEWPORT_EDGE_PADDING.y, maxf(VIEWPORT_EDGE_PADDING.y, max_position.y))
	)


func _make_popup_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", naked_power_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _spawn_sparkle_dot(laser_position: Vector2, index: int) -> void:
	var dot := Panel.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.custom_minimum_size = Vector2(8, 8)
	dot.size = Vector2(8, 8)
	dot.modulate = Color(1, 1, 1, 0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.82, 1.0, 0.96)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.72, 0.94, 1.0, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	dot.add_theme_stylebox_override("panel", style)

	var angle := TAU * float(index) / float(SPARKLE_DOT_COUNT)
	var start_radius := SPARKLE_RADIUS_MIN + float(index % 5) * 4.0
	var end_radius := SPARKLE_RADIUS_MAX + float(index % 4) * 10.0
	var direction := Vector2(cos(angle), sin(angle))
	var start_position := laser_position + direction * start_radius - dot.size * 0.5
	var end_position := laser_position + direction * end_radius - dot.size * 0.5
	dot.position = start_position
	_world_popups.add_child(dot)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dot, "modulate:a", 1.0, 0.1)
	tween.tween_property(dot, "position", end_position, 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(dot, "scale", Vector2(0.15, 0.15), 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_property(dot, "modulate:a", 0.0, 0.18)
	tween.tween_callback(Callable(dot, "queue_free"))


func _position_popup(control: Control, world_position: Vector2, anchor: Vector2) -> void:
	control.reset_size()
	var popup_size := control.size
	if popup_size == Vector2.ZERO:
		popup_size = control.get_combined_minimum_size()

	control.global_position = world_position - popup_size * anchor


func _animate_popup(control: Control, travel: Vector2) -> void:
	var start_position := control.position
	control.pivot_offset = control.get_combined_minimum_size() * 0.5

	var motion_tween := create_tween()
	motion_tween.set_parallel(true)
	motion_tween.tween_property(control, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(control, "position", start_position + travel, POPUP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var fade_tween := create_tween()
	fade_tween.tween_property(control, "modulate:a", 1.0, 0.16)
	fade_tween.tween_interval(0.74)
	fade_tween.tween_property(control, "modulate:a", 0.0, 0.42)
	fade_tween.tween_callback(Callable(control, "queue_free"))
