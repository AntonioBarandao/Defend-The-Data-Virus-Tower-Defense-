class_name TowerUpgradeHUD
extends CanvasLayer

const TowerTooltips := preload("res://Scripts/UI/tower_tooltip_data.gd")

signal laser_upgrade_pressed
signal guardian_mode_pressed(mode_id: StringName)
signal scanner_upgrade_pressed
signal scanner_mode_pressed(mode_id: StringName)
signal edr_upgrade_pressed
signal siem_upgrade_pressed
signal siem_dispatch_pressed
signal siem_land_pressed
signal ips_upgrade_pressed
signal honeypot_upgrade_pressed
signal sell_pressed

enum MenuMode {
	NONE,
	GUARDIAN,
	LASER,
	SCANNER,
	EDR,
	SIEM,
	IPS,
	HONEYPOT
}

const GUARDIAN_MODE_DEFENDER := &"defender"
const GUARDIAN_MODE_SIGNAL_BOOST := &"signal_boost"
const GUARDIAN_MODE_FIREWALL := &"firewall"

@export_group("Drawer Animation")
@export var right_margin := 0.0
@export var slide_hidden_offset := 36.0
@export var slide_seconds := 0.24
@export_group("")
@export_group("Honeypot Displays")
@export var honeypot_level_display_textures: Array[Texture2D] = []
@export_group("")

@onready var _menu_panel: PanelContainer = $Root/MenuPanel
@onready var _title_label: Label = $Root/MenuPanel/Margin/Content/Title
@onready var _portrait_row: Control = $Root/MenuPanel/Margin/Content/PortraitRow
@onready var _guardian_mode_container: Control = $Root/MenuPanel/Margin/Content/VBoxContainer
@onready var _guardian_mode_buttons := {
	GUARDIAN_MODE_DEFENDER: $Root/MenuPanel/Margin/Content/VBoxContainer/ButtonPath,
	GUARDIAN_MODE_SIGNAL_BOOST: $Root/MenuPanel/Margin/Content/VBoxContainer/ButtonPath2,
	GUARDIAN_MODE_FIREWALL: $Root/MenuPanel/Margin/Content/VBoxContainer/ButtonPath3
}
@onready var _upgrade_path_container: Control = $Root/MenuPanel/Margin/Content/VBoxContainer2
@onready var _laser_level_label: Label = $Root/MenuPanel/Margin/Content/VBoxContainer2/LevelLabel
@onready var _laser_power_label: Label = $Root/MenuPanel/Margin/Content/VBoxContainer2/PowerLabel
@onready var _laser_range_label: Label = $Root/MenuPanel/Margin/Content/VBoxContainer2/RangeLabel
@onready var _siem_dispatch_section: Control = $Root/MenuPanel/Margin/Content/VBoxContainer2/SIEMDispatchSection
@onready var _siem_dispatch_button: Button = $Root/MenuPanel/Margin/Content/VBoxContainer2/SIEMDispatchSection/DispatchButton
@onready var _siem_land_button: Button = $Root/MenuPanel/Margin/Content/VBoxContainer2/SIEMDispatchSection/LandButton
@onready var _siem_banked_knowledge_label: Label = $Root/MenuPanel/Margin/Content/VBoxContainer2/SIEMDispatchSection/BankedKnowledgeLabel
@onready var _scanner_mode_section: Control = $Root/MenuPanel/Margin/Content/VBoxContainer2/ScannerModeSection
@onready var _scanner_mode_notice_label: Label = $Root/MenuPanel/Margin/Content/VBoxContainer2/ScannerModeSection/ModeNotice
@onready var _scanner_mode_buttons := {
	&"camo": $Root/MenuPanel/Margin/Content/VBoxContainer2/ScannerModeSection/ModeGrid/CamoModeButton,
	&"burner": $Root/MenuPanel/Margin/Content/VBoxContainer2/ScannerModeSection/ModeGrid/BurnerModeButton,
	&"bounty": $Root/MenuPanel/Margin/Content/VBoxContainer2/ScannerModeSection/ModeGrid/BountyModeButton,
	&"quarantine": $Root/MenuPanel/Margin/Content/VBoxContainer2/ScannerModeSection/ModeGrid/QuarantineModeButton,
	&"nullifier": $Root/MenuPanel/Margin/Content/VBoxContainer2/ScannerModeSection/ModeGrid/NullifierModeButton
}
@onready var _laser_cost_row: Control = $Root/MenuPanel/Margin/Content/VBoxContainer2/CostRow
@onready var _honeypot_display_section: Control = $Root/MenuPanel/Margin/Content/VBoxContainer2/HoneypotLevelDisplay
@onready var _honeypot_level_display: TextureRect = $Root/MenuPanel/Margin/Content/VBoxContainer2/HoneypotLevelDisplay/DisplayMargin/LevelImage
@onready var _laser_cost_label: Label = $Root/MenuPanel/Margin/Content/VBoxContainer2/CostRow/CostAmount
@onready var _laser_upgrade_button: Button = $Root/MenuPanel/Margin/Content/VBoxContainer2/ButtonPath4
@onready var _sell_button: Button = $Root/MenuPanel/Margin/Content/SellButton

var _description_label: Label
var _current_mode := MenuMode.NONE
var _guardian_mode_names := {
	GUARDIAN_MODE_DEFENDER: "Defender Mode",
	GUARDIAN_MODE_SIGNAL_BOOST: "Signal Boost Mode",
	GUARDIAN_MODE_FIREWALL: "Firewall Mode"
}
var _guardian_mode_unlock_levels := {
	GUARDIAN_MODE_DEFENDER: 1,
	GUARDIAN_MODE_SIGNAL_BOOST: 1,
	GUARDIAN_MODE_FIREWALL: 1
}
var _scanner_mode_names := {
	&"camo": "Camo",
	&"burner": "Burner",
	&"bounty": "Bounty",
	&"quarantine": "Quarantine",
	&"nullifier": "Nullifier"
}
var _menu_tween: Tween
var _drawer_target_position := Vector2.ZERO
var _drawer_hidden_position := Vector2.ZERO


func _ready() -> void:
	layer = maxi(layer, 240)
	_menu_panel.hide()
	_ensure_description_label()
	_configure_static_tooltips()
	_cache_drawer_positions()
	_menu_panel.position = _drawer_hidden_position
	_laser_upgrade_button.pressed.connect(Callable(self, "_on_upgrade_button_pressed"))
	_sell_button.pressed.connect(func() -> void: sell_pressed.emit())
	_siem_dispatch_button.pressed.connect(Callable(self, "_on_siem_dispatch_button_pressed"))
	_siem_land_button.pressed.connect(Callable(self, "_on_siem_land_button_pressed"))
	for mode_id in _guardian_mode_buttons.keys():
		var button := _guardian_mode_buttons[mode_id] as Button
		if button != null:
			button.pressed.connect(_emit_guardian_mode_pressed.bind(mode_id))
	for mode_id in _scanner_mode_buttons.keys():
		var button := _scanner_mode_buttons[mode_id] as Button
		if button != null:
			button.pressed.connect(_emit_scanner_mode_pressed.bind(mode_id))


func set_guardian_modes(
	current_mode: StringName,
	unlocked_modes: Array[StringName],
	knowledge_level: int,
	unlock_levels: Dictionary = {},
	status_text: String = ""
) -> void:
	if _description_label != null:
		var summary := TowerTooltips.tower_summary(&"guardian")
		_description_label.text = summary if status_text.is_empty() else "%s\n\n%s" % [summary, status_text]

	var unlocked_lookup := {}
	for mode_id in unlocked_modes:
		unlocked_lookup[mode_id] = true

	for mode_id in _guardian_mode_buttons.keys():
		var button := _guardian_mode_buttons[mode_id] as Button
		if button == null:
			continue

		var required_level := _get_guardian_mode_unlock_level(mode_id, unlock_levels)
		var unlocked: bool = unlocked_lookup.has(mode_id) or knowledge_level >= required_level
		var active: bool = mode_id == current_mode
		button.disabled = not unlocked or active
		if active:
			button.text = "%s Active" % _get_guardian_mode_name(mode_id)
		elif unlocked:
			button.text = _get_guardian_mode_name(mode_id)
		else:
			button.text = "%s Locked LV%d" % [_get_guardian_mode_name(mode_id), required_level]


func set_laser_stats(
	level: int,
	max_level: int,
	power: int,
	attack_range: float,
	can_upgrade: bool,
	upgrade_cost: int = 0
) -> void:
	_set_tower_description(&"laser")
	_scanner_mode_section.hide()
	_siem_dispatch_section.hide()
	_laser_level_label.text = "Level %d / %d" % [level, max_level]
	_laser_power_label.text = "Power: %d" % power
	_laser_range_label.text = "Range: %d px" % roundi(attack_range)

	var at_max_level := level >= max_level
	_set_upgrade_button_state(&"laser", at_max_level, can_upgrade, upgrade_cost)


func set_scanner_stats(
	level: int,
	max_level: int,
	scan_radius: float,
	can_upgrade: bool,
	upgrade_cost: int = 0,
	current_mode: StringName = &"camo",
	unlocked_modes: Array[StringName] = [],
	can_change_mode: bool = true
) -> void:
	_set_tower_description(&"scanner")
	_scanner_mode_section.show()
	_siem_dispatch_section.hide()
	_laser_level_label.text = "Level %d / %d" % [level, max_level]
	_laser_power_label.text = "Mode: %s" % _get_scanner_mode_name(current_mode)
	_laser_range_label.text = "Scan Radius: %d px" % roundi(scan_radius)
	if can_change_mode:
		_hide_scanner_mode_notice()
	else:
		show_scanner_mode_notice("Cannot change mode while a virus is in the IDS scan.")
	_sync_scanner_mode_buttons(current_mode, unlocked_modes, can_change_mode)

	var at_max_level := level >= max_level
	_set_upgrade_button_state(&"scanner", at_max_level, can_upgrade, upgrade_cost)


func set_edr_stats(
	level: int,
	max_level: int,
	power: int,
	attack_range: float,
	cooldown: float,
	can_upgrade: bool,
	upgrade_cost: int = 0
) -> void:
	_set_tower_description(&"edr")
	_scanner_mode_section.hide()
	_siem_dispatch_section.hide()
	_laser_level_label.text = "Level %d / %d" % [level, max_level]
	_laser_power_label.text = "Power: %d | Cooldown: %.1fs" % [power, cooldown]
	_laser_range_label.text = "Range: Global" if attack_range >= 99999.0 else "Range: %d px" % roundi(attack_range)

	var at_max_level := level >= max_level
	_set_upgrade_button_state(&"edr", at_max_level, can_upgrade, upgrade_cost)


func set_siem_stats(
	level: int,
	max_level: int,
	power: int,
	attack_range: float,
	cooldown: float,
	can_upgrade: bool,
	upgrade_cost: int = 0
) -> void:
	_set_tower_description(&"siem")
	_scanner_mode_section.hide()
	_siem_dispatch_section.show()
	_laser_level_label.text = "Level %d / %d" % [level, max_level]
	_laser_power_label.text = "Power: %d | Cooldown: %.1fs" % [power, cooldown]
	_laser_range_label.text = "Damage Range: LV2+" if attack_range <= 0.0 else "Damage Range: %d px" % roundi(attack_range)

	var at_max_level := level >= max_level
	_set_upgrade_button_state(&"siem", at_max_level, can_upgrade, upgrade_cost)


func set_ips_stats(
	level: int,
	max_level: int,
	spike_damage: int,
	attack_range: float,
	max_spikes: int,
	cooldown: float,
	can_upgrade: bool,
	upgrade_cost: int = 0
) -> void:
	_set_tower_description(&"ips")
	_scanner_mode_section.hide()
	_siem_dispatch_section.hide()
	_laser_level_label.text = "Level %d / %d" % [level, max_level]
	_laser_power_label.text = "Spike Damage: %d | Slots: %d" % [spike_damage, max_spikes]
	_laser_range_label.text = "Factory Range: %d px | %.1fs" % [roundi(attack_range), cooldown]

	var at_max_level := level >= max_level
	_set_upgrade_button_state(&"ips", at_max_level, can_upgrade, upgrade_cost)


func set_honeypot_stats(
	level: int,
	max_level: int,
	pot_amount: int,
	pot_capacity: int,
	production_rate: float,
	production_radius: float,
	status_text: String,
	knowledge_amount: int,
	knowledge_capacity: int,
	knowledge_unlocked: bool,
	can_upgrade: bool,
	upgrade_cost: int = 0
) -> void:
	_set_tower_description(&"honeypot")
	_sync_honeypot_level_display(level)
	_scanner_mode_section.hide()
	_siem_dispatch_section.hide()
	_laser_level_label.text = "Level %d / %d" % [level, max_level]
	_laser_power_label.text = "Cyber Bucks: %d/%d | +%.1f/s" % [pot_amount, pot_capacity, production_rate]
	if knowledge_unlocked:
		_laser_power_label.text += "\nKnowledge: %d/%d | +1/3s" % [knowledge_amount, knowledge_capacity]
	_laser_range_label.text = "Lure Radius: %d px | %s" % [roundi(production_radius), status_text]

	var at_max_level := level >= max_level
	_set_upgrade_button_state(&"honeypot", at_max_level, can_upgrade, upgrade_cost)


func set_siem_dispatch_state(dispatched: bool, banked_knowledge: int, landing_to_headquarters := false, can_land := false) -> void:
	_siem_dispatch_button.text = "Freeze Mode" if dispatched else "Destination Mode"
	_siem_land_button.text = "Landing..." if landing_to_headquarters else "Land to Headquarters"
	_siem_land_button.disabled = landing_to_headquarters or not can_land
	_siem_banked_knowledge_label.text = "Banked Knowledge: %d" % maxi(0, banked_knowledge)


func show_guardian_panel() -> void:
	_current_mode = MenuMode.GUARDIAN
	_title_label.text = TowerTooltips.tower_name(&"guardian")
	_set_tower_description(&"guardian")
	_portrait_row.show()
	_guardian_mode_container.show()
	_upgrade_path_container.hide()
	_scanner_mode_section.hide()
	_siem_dispatch_section.hide()
	_show_menu_panel_animated()


func hide_guardian_panel() -> void:
	if _current_mode == MenuMode.GUARDIAN:
		hide_all()


func is_guardian_panel_visible() -> bool:
	return _menu_panel.visible and _current_mode == MenuMode.GUARDIAN


func guardian_panel_has_point(screen_position: Vector2) -> bool:
	return is_guardian_panel_visible() and _menu_panel.get_global_rect().has_point(screen_position)


func is_any_panel_visible() -> bool:
	return _menu_panel.visible and _current_mode != MenuMode.NONE


func menu_panel_has_point(screen_position: Vector2) -> bool:
	return _menu_panel.visible and _menu_panel.get_global_rect().has_point(screen_position)


func show_laser_panel() -> void:
	_current_mode = MenuMode.LASER
	_title_label.text = TowerTooltips.tower_name(&"laser")
	_portrait_row.hide()
	_guardian_mode_container.hide()
	_upgrade_path_container.show()
	_scanner_mode_section.hide()
	_siem_dispatch_section.hide()
	_show_menu_panel_animated()


func show_scanner_panel() -> void:
	_current_mode = MenuMode.SCANNER
	_title_label.text = TowerTooltips.tower_name(&"scanner")
	_portrait_row.hide()
	_guardian_mode_container.hide()
	_upgrade_path_container.show()
	_scanner_mode_section.show()
	_siem_dispatch_section.hide()
	_show_menu_panel_animated()


func show_edr_panel() -> void:
	_current_mode = MenuMode.EDR
	_title_label.text = TowerTooltips.tower_name(&"edr")
	_portrait_row.hide()
	_guardian_mode_container.hide()
	_upgrade_path_container.show()
	_scanner_mode_section.hide()
	_siem_dispatch_section.hide()
	_show_menu_panel_animated()


func show_siem_panel() -> void:
	_current_mode = MenuMode.SIEM
	_title_label.text = TowerTooltips.tower_name(&"siem")
	_portrait_row.hide()
	_guardian_mode_container.hide()
	_upgrade_path_container.show()
	_scanner_mode_section.hide()
	_siem_dispatch_section.show()
	_show_menu_panel_animated()


func show_ips_panel() -> void:
	_current_mode = MenuMode.IPS
	_title_label.text = TowerTooltips.tower_name(&"ips")
	_portrait_row.hide()
	_guardian_mode_container.hide()
	_upgrade_path_container.show()
	_scanner_mode_section.hide()
	_siem_dispatch_section.hide()
	_show_menu_panel_animated()


func show_honeypot_panel() -> void:
	_current_mode = MenuMode.HONEYPOT
	_title_label.text = TowerTooltips.tower_name(&"honeypot")
	_portrait_row.hide()
	_guardian_mode_container.hide()
	_upgrade_path_container.show()
	_scanner_mode_section.hide()
	_siem_dispatch_section.hide()
	_show_menu_panel_animated()


func hide_laser_panel() -> void:
	if _current_mode == MenuMode.LASER:
		hide_all()


func is_laser_panel_visible() -> bool:
	return _menu_panel.visible and _current_mode == MenuMode.LASER


func laser_panel_has_point(screen_position: Vector2) -> bool:
	return is_laser_panel_visible() and _menu_panel.get_global_rect().has_point(screen_position)


func hide_scanner_panel() -> void:
	if _current_mode == MenuMode.SCANNER:
		hide_all()


func is_scanner_panel_visible() -> bool:
	return _menu_panel.visible and _current_mode == MenuMode.SCANNER


func scanner_panel_has_point(screen_position: Vector2) -> bool:
	return is_scanner_panel_visible() and _menu_panel.get_global_rect().has_point(screen_position)


func hide_edr_panel() -> void:
	if _current_mode == MenuMode.EDR:
		hide_all()


func is_edr_panel_visible() -> bool:
	return _menu_panel.visible and _current_mode == MenuMode.EDR


func edr_panel_has_point(screen_position: Vector2) -> bool:
	return is_edr_panel_visible() and _menu_panel.get_global_rect().has_point(screen_position)


func hide_siem_panel() -> void:
	if _current_mode == MenuMode.SIEM:
		hide_all()


func is_siem_panel_visible() -> bool:
	return _menu_panel.visible and _current_mode == MenuMode.SIEM


func siem_panel_has_point(screen_position: Vector2) -> bool:
	return is_siem_panel_visible() and _menu_panel.get_global_rect().has_point(screen_position)


func hide_ips_panel() -> void:
	if _current_mode == MenuMode.IPS:
		hide_all()


func is_ips_panel_visible() -> bool:
	return _menu_panel.visible and _current_mode == MenuMode.IPS


func ips_panel_has_point(screen_position: Vector2) -> bool:
	return is_ips_panel_visible() and _menu_panel.get_global_rect().has_point(screen_position)


func hide_honeypot_panel() -> void:
	if _current_mode == MenuMode.HONEYPOT:
		hide_all()


func is_honeypot_panel_visible() -> bool:
	return _menu_panel.visible and _current_mode == MenuMode.HONEYPOT


func honeypot_panel_has_point(screen_position: Vector2) -> bool:
	return is_honeypot_panel_visible() and _menu_panel.get_global_rect().has_point(screen_position)


func show_scanner_mode_notice(message: String) -> void:
	if _scanner_mode_notice_label == null:
		return

	_scanner_mode_notice_label.text = message
	_scanner_mode_notice_label.show()


func hide_all() -> void:
	_current_mode = MenuMode.NONE
	_hide_menu_panel_animated()


func _on_upgrade_button_pressed() -> void:
	match _current_mode:
		MenuMode.LASER:
			laser_upgrade_pressed.emit()
		MenuMode.SCANNER:
			scanner_upgrade_pressed.emit()
		MenuMode.EDR:
			edr_upgrade_pressed.emit()
		MenuMode.SIEM:
			siem_upgrade_pressed.emit()
		MenuMode.IPS:
			ips_upgrade_pressed.emit()
		MenuMode.HONEYPOT:
			honeypot_upgrade_pressed.emit()


func _on_siem_dispatch_button_pressed() -> void:
	if _current_mode != MenuMode.SIEM:
		return

	siem_dispatch_pressed.emit()


func _on_siem_land_button_pressed() -> void:
	if _current_mode != MenuMode.SIEM:
		return

	siem_land_pressed.emit()


func _emit_scanner_mode_pressed(mode_id: StringName) -> void:
	if _current_mode != MenuMode.SCANNER:
		return

	scanner_mode_pressed.emit(mode_id)


func _emit_guardian_mode_pressed(mode_id: StringName) -> void:
	if _current_mode != MenuMode.GUARDIAN:
		return

	guardian_mode_pressed.emit(mode_id)


func _sync_scanner_mode_buttons(current_mode: StringName, unlocked_modes: Array[StringName], can_change_mode: bool) -> void:
	var unlocked_lookup := {}
	for mode_id in unlocked_modes:
		unlocked_lookup[mode_id] = true

	for mode_id in _scanner_mode_buttons.keys():
		var button := _scanner_mode_buttons[mode_id] as Button
		if button == null:
			continue

		var unlocked: bool = unlocked_lookup.has(mode_id)
		var active: bool = mode_id == current_mode
		button.disabled = not unlocked or active or not can_change_mode
		button.tooltip_text = TowerTooltips.scanner_mode_tooltip(mode_id)
		if active:
			button.text = "%s Active" % _get_scanner_mode_name(mode_id)
		elif unlocked:
			button.text = _get_scanner_mode_name(mode_id)
		else:
			button.text = "%s Locked" % _get_scanner_mode_name(mode_id)


func _get_scanner_mode_name(mode_id: StringName) -> String:
	return String(_scanner_mode_names.get(mode_id, "Camo"))


func _get_guardian_mode_name(mode_id: StringName) -> String:
	return String(_guardian_mode_names.get(mode_id, "Defender Mode"))


func _get_guardian_mode_unlock_level(mode_id: StringName, unlock_levels: Dictionary = {}) -> int:
	if unlock_levels.has(mode_id):
		return int(unlock_levels[mode_id])

	return int(_guardian_mode_unlock_levels.get(mode_id, 1))


func _hide_scanner_mode_notice() -> void:
	if _scanner_mode_notice_label != null:
		_scanner_mode_notice_label.hide()


func _ensure_description_label() -> void:
	if _description_label != null:
		return

	_description_label = Label.new()
	_description_label.name = "TowerDescription"
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.theme_type_variation = &""
	_description_label.add_theme_color_override("font_color", Color(0.74, 0.9, 1.0, 0.92))
	_description_label.add_theme_font_size_override("font_size", 15)
	_title_label.get_parent().add_child(_description_label)
	_title_label.get_parent().move_child(_description_label, _title_label.get_index() + 1)


func _configure_static_tooltips() -> void:
	for mode_id in _guardian_mode_buttons.keys():
		var button := _guardian_mode_buttons[mode_id] as Button
		if button != null:
			button.tooltip_text = String(TowerTooltips.GUARDIAN_MODE_DETAILS.get(mode_id, TowerTooltips.tower_tooltip(&"guardian")))
	_siem_dispatch_button.tooltip_text = TowerTooltips.SIEM_DISPATCH_TOOLTIP
	_siem_land_button.tooltip_text = TowerTooltips.SIEM_LAND_TOOLTIP
	for mode_id in _scanner_mode_buttons.keys():
		var button := _scanner_mode_buttons[mode_id] as Button
		if button != null:
			button.tooltip_text = TowerTooltips.scanner_mode_tooltip(mode_id)


func _set_tower_description(tower_id: StringName) -> void:
	if _description_label != null:
		_description_label.text = TowerTooltips.tower_summary(tower_id)
	if _honeypot_display_section != null:
		_honeypot_display_section.visible = tower_id == &"honeypot"


func _sync_honeypot_level_display(level: int) -> void:
	if _honeypot_level_display == null or honeypot_level_display_textures.is_empty():
		return

	var display_index := clampi(level - 1, 0, honeypot_level_display_textures.size() - 1)
	_honeypot_level_display.texture = honeypot_level_display_textures[display_index]


func _set_upgrade_button_state(tower_id: StringName, at_max_level: bool, can_upgrade: bool, upgrade_cost: int) -> void:
	_laser_cost_row.visible = not at_max_level
	_laser_upgrade_button.disabled = at_max_level or not can_upgrade
	_laser_upgrade_button.text = "Max Level" if at_max_level else "Upgrade"
	_laser_upgrade_button.tooltip_text = TowerTooltips.tower_upgrade_tooltip(tower_id)
	if at_max_level:
		_laser_cost_label.text = ""
	else:
		_laser_cost_label.text = str(maxi(0, upgrade_cost))


func _cache_drawer_positions() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := _menu_panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = _menu_panel.custom_minimum_size
		if panel_size.x <= 0.0:
			panel_size.x = 390.0
		if panel_size.y <= 0.0:
			panel_size.y = viewport_size.y
		_menu_panel.size = panel_size

	_drawer_target_position = Vector2(maxf(0.0, viewport_size.x - panel_size.x - right_margin), _menu_panel.position.y)
	_drawer_hidden_position = Vector2(viewport_size.x + slide_hidden_offset, _drawer_target_position.y)


func _show_menu_panel_animated() -> void:
	visible = true
	_honeypot_display_section.visible = _current_mode == MenuMode.HONEYPOT
	_cache_drawer_positions()
	if _menu_tween != null:
		_menu_tween.kill()

	if not _menu_panel.visible:
		_menu_panel.position = _drawer_hidden_position
		_menu_panel.modulate.a = 0.92
		_menu_panel.show()

	_menu_tween = create_tween()
	_menu_tween.set_parallel(true)
	_menu_tween.tween_property(_menu_panel, "position", _drawer_target_position, slide_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_menu_tween.tween_property(_menu_panel, "modulate:a", 1.0, slide_seconds * 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_menu_tween.set_parallel(false)
	_menu_tween.tween_callback(func() -> void:
		_menu_tween = null
	)


func _hide_menu_panel_animated() -> void:
	if _menu_tween != null:
		_menu_tween.kill()
	if not _menu_panel.visible:
		return

	_cache_drawer_positions()
	_menu_tween = create_tween()
	_menu_tween.set_parallel(true)
	_menu_tween.tween_property(_menu_panel, "position", _drawer_hidden_position, slide_seconds * 0.82).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_menu_tween.tween_property(_menu_panel, "modulate:a", 0.0, slide_seconds * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_menu_tween.set_parallel(false)
	_menu_tween.tween_callback(func() -> void:
		_menu_panel.hide()
		_menu_panel.modulate.a = 1.0
		_menu_tween = null
	)
