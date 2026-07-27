class_name SignalBoostHUD
extends CanvasLayer

signal activation_requested
signal firewall_activation_requested

const MODE_SIGNAL_BOOST := &"signal_boost"
const MODE_FIREWALL := &"firewall"
const STATE_READY := &"ready"
const STATE_DECLARE := &"declare"
const STATE_ACTIVE := &"active"
const STATE_COOLDOWN := &"cooldown"
const READY_COLOR := Color(0.78, 1.0, 0.3, 1.0)
const ACTIVE_COLOR := Color(0.34, 1.0, 0.48, 1.0)
const COOLDOWN_COLOR := Color(1.0, 0.28, 0.24, 1.0)
const DISABLED_ICON_COLOR := Color(0.42, 0.44, 0.42, 0.82)
const HOVER_BORDER_COLOR := Color(1.0, 0.88, 0.18, 1.0)
const HOVER_GLOW_COLOR := Color(1.0, 0.78, 0.08, 0.56)
const FIREWALL_READY_COLOR := Color(1.0, 0.48, 0.18, 1.0)
const FIREWALL_ACTIVE_COLOR := Color(1.0, 0.72, 0.2, 1.0)

@onready var _ability_slot: Panel = $Root/AbilitySlot
@onready var _firewall_ability_slot: Panel = $Root/FirewallAbilitySlot
@onready var _signal_boost_icon := get_node_or_null(
	"Root/AbilitySlot/Margin/Content/IconFrame/SignalBoostIcon"
) as CanvasItem
@onready var _status_label := get_node_or_null(
	"Root/AbilitySlot/Margin/Content/StatusLabel"
) as Label
@onready var _firewall_icon := get_node_or_null(
	"Root/FirewallAbilitySlot/Margin/Content/IconFrame/FirewallIcon"
) as CanvasItem
@onready var _firewall_status_label := get_node_or_null(
	"Root/FirewallAbilitySlot/Margin/Content/StatusLabel"
) as Label

var _guardian: CyberGuardianTower
var _can_activate := false
var _can_activate_firewall := false
var _interaction_locked := false
var _is_hovered := false
var _firewall_is_hovered := false
var _ability_style: StyleBoxFlat
var _firewall_ability_style: StyleBoxFlat
var _base_border_color := Color.TRANSPARENT
var _base_shadow_color := Color.TRANSPARENT
var _base_shadow_size := 0
var _firewall_base_border_color := Color.TRANSPARENT
var _firewall_base_shadow_color := Color.TRANSPARENT
var _firewall_base_shadow_size := 0


func _ready() -> void:
	var authored_style := _ability_slot.get_theme_stylebox("panel") as StyleBoxFlat
	if authored_style:
		_ability_style = authored_style.duplicate() as StyleBoxFlat
		_base_border_color = _ability_style.border_color
		_base_shadow_color = _ability_style.shadow_color
		_base_shadow_size = _ability_style.shadow_size
		_ability_slot.add_theme_stylebox_override("panel", _ability_style)

	var authored_firewall_style := _firewall_ability_slot.get_theme_stylebox(
		"panel"
	) as StyleBoxFlat
	if authored_firewall_style:
		_firewall_ability_style = (
			authored_firewall_style.duplicate() as StyleBoxFlat
		)
		_firewall_base_border_color = _firewall_ability_style.border_color
		_firewall_base_shadow_color = _firewall_ability_style.shadow_color
		_firewall_base_shadow_size = _firewall_ability_style.shadow_size
		_firewall_ability_slot.add_theme_stylebox_override(
			"panel",
			_firewall_ability_style
		)

	_ability_slot.gui_input.connect(_on_ability_slot_gui_input)
	_ability_slot.mouse_entered.connect(_on_ability_slot_mouse_entered)
	_ability_slot.mouse_exited.connect(_on_ability_slot_mouse_exited)
	_firewall_ability_slot.gui_input.connect(
		_on_firewall_ability_slot_gui_input
	)
	_firewall_ability_slot.mouse_entered.connect(
		_on_firewall_ability_slot_mouse_entered
	)
	_firewall_ability_slot.mouse_exited.connect(
		_on_firewall_ability_slot_mouse_exited
	)
	_sync_display()


func _process(_delta: float) -> void:
	_sync_display()


func set_guardian(guardian: CyberGuardianTower) -> void:
	_guardian = guardian
	_sync_display()


func set_interaction_locked(locked: bool) -> void:
	_interaction_locked = locked
	_sync_display()


func is_interaction_locked() -> bool:
	return _interaction_locked


func get_ability_slot() -> Control:
	return _ability_slot


func get_firewall_ability_slot() -> Control:
	return _firewall_ability_slot


func _on_ability_slot_gui_input(event: InputEvent) -> void:
	if not _can_activate:
		return

	var was_pressed := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		was_pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		was_pressed = (event as InputEventScreenTouch).pressed

	if not was_pressed:
		return

	activation_requested.emit()
	get_viewport().set_input_as_handled()


func _on_firewall_ability_slot_gui_input(event: InputEvent) -> void:
	if not _can_activate_firewall:
		return

	var was_pressed := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		was_pressed = (
			mouse_event.button_index == MOUSE_BUTTON_LEFT
			and mouse_event.pressed
		)
	elif event is InputEventScreenTouch:
		was_pressed = (event as InputEventScreenTouch).pressed

	if not was_pressed:
		return

	firewall_activation_requested.emit()
	get_viewport().set_input_as_handled()


func _on_ability_slot_mouse_entered() -> void:
	_is_hovered = true
	_sync_hover_style()


func _on_ability_slot_mouse_exited() -> void:
	_is_hovered = false
	_sync_hover_style()


func _on_firewall_ability_slot_mouse_entered() -> void:
	_firewall_is_hovered = true
	_sync_firewall_hover_style()


func _on_firewall_ability_slot_mouse_exited() -> void:
	_firewall_is_hovered = false
	_sync_firewall_hover_style()


func _sync_hover_style() -> void:
	if not _ability_style:
		return
	_ability_style.border_color = HOVER_BORDER_COLOR if _is_hovered else _base_border_color
	_ability_style.shadow_color = HOVER_GLOW_COLOR if _is_hovered else _base_shadow_color
	_ability_style.shadow_size = 14 if _is_hovered else _base_shadow_size


func _sync_firewall_hover_style() -> void:
	if not _firewall_ability_style:
		return
	_firewall_ability_style.border_color = (
		HOVER_BORDER_COLOR
		if _firewall_is_hovered
		else _firewall_base_border_color
	)
	_firewall_ability_style.shadow_color = (
		HOVER_GLOW_COLOR
		if _firewall_is_hovered
		else _firewall_base_shadow_color
	)
	_firewall_ability_style.shadow_size = (
		14
		if _firewall_is_hovered
		else _firewall_base_shadow_size
	)


func _sync_display() -> void:
	_sync_signal_boost_display()
	_sync_firewall_display()


func _sync_signal_boost_display() -> void:
	var should_show := is_instance_valid(_guardian) \
		and _guardian.is_placed() \
		and _guardian.get_current_mode_id() == MODE_SIGNAL_BOOST
	_ability_slot.visible = should_show
	_can_activate = false
	if not should_show:
		return

	var state_id := _guardian.get_signal_boost_state_id()
	var remaining_seconds := ceili(_guardian.get_signal_boost_time_remaining())
	_can_activate = state_id == STATE_READY and not _interaction_locked
	if _signal_boost_icon:
		_signal_boost_icon.self_modulate = Color.WHITE if _can_activate else DISABLED_ICON_COLOR
	if not _status_label:
		return
	if _interaction_locked:
		_status_label.text = "RANSOM LOCK"
		_status_label.modulate = COOLDOWN_COLOR
		return

	match state_id:
		STATE_DECLARE:
			_status_label.text = "DEPLOYING  %ds" % remaining_seconds
			_status_label.modulate = ACTIVE_COLOR
		STATE_ACTIVE:
			_status_label.text = "SIGNAL BOOST  %ds" % remaining_seconds
			_status_label.modulate = ACTIVE_COLOR
		STATE_COOLDOWN:
			_status_label.text = "COOLDOWN  %ds" % remaining_seconds
			_status_label.modulate = COOLDOWN_COLOR
		_:
			_status_label.text = "SIGNAL BOOST"
			_status_label.modulate = READY_COLOR


func _sync_firewall_display() -> void:
	var should_show := is_instance_valid(_guardian) \
		and _guardian.is_placed() \
		and _guardian.get_current_mode_id() == MODE_FIREWALL
	_firewall_ability_slot.visible = should_show
	_can_activate_firewall = false
	if not should_show:
		return

	var state_id := _guardian.get_firewall_state_id()
	var remaining_seconds := ceili(_guardian.get_firewall_time_remaining())
	_can_activate_firewall = state_id == STATE_READY and not _interaction_locked
	if _firewall_icon:
		_firewall_icon.self_modulate = (
			Color.WHITE
			if _can_activate_firewall
			else DISABLED_ICON_COLOR
		)
	if not _firewall_status_label:
		return
	if _interaction_locked:
		_firewall_status_label.text = "RANSOM LOCK"
		_firewall_status_label.modulate = COOLDOWN_COLOR
		return

	match state_id:
		STATE_DECLARE:
			_firewall_status_label.text = "DEPLOYING  %ds" % remaining_seconds
			_firewall_status_label.modulate = FIREWALL_ACTIVE_COLOR
		STATE_ACTIVE:
			_firewall_status_label.text = "FIREWALL  %ds" % remaining_seconds
			_firewall_status_label.modulate = FIREWALL_ACTIVE_COLOR
		_:
			_firewall_status_label.text = "FIREWALL"
			_firewall_status_label.modulate = FIREWALL_READY_COLOR
