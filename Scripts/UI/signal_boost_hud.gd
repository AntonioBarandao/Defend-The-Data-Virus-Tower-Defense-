class_name SignalBoostHUD
extends CanvasLayer

signal activation_requested

const MODE_SIGNAL_BOOST := &"signal_boost"
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

@onready var _ability_slot: Panel = $Root/AbilitySlot
@onready var _signal_boost_icon := get_node_or_null(
	"Root/AbilitySlot/Margin/Content/IconFrame/SignalBoostIcon"
) as CanvasItem
@onready var _status_label := get_node_or_null(
	"Root/AbilitySlot/Margin/Content/StatusLabel"
) as Label

var _guardian: CyberGuardianTower
var _can_activate := false
var _is_hovered := false
var _ability_style: StyleBoxFlat
var _base_border_color := Color.TRANSPARENT
var _base_shadow_color := Color.TRANSPARENT
var _base_shadow_size := 0


func _ready() -> void:
	var authored_style := _ability_slot.get_theme_stylebox("panel") as StyleBoxFlat
	if authored_style:
		_ability_style = authored_style.duplicate() as StyleBoxFlat
		_base_border_color = _ability_style.border_color
		_base_shadow_color = _ability_style.shadow_color
		_base_shadow_size = _ability_style.shadow_size
		_ability_slot.add_theme_stylebox_override("panel", _ability_style)

	_ability_slot.gui_input.connect(_on_ability_slot_gui_input)
	_ability_slot.mouse_entered.connect(_on_ability_slot_mouse_entered)
	_ability_slot.mouse_exited.connect(_on_ability_slot_mouse_exited)
	_sync_display()


func _process(_delta: float) -> void:
	_sync_display()


func set_guardian(guardian: CyberGuardianTower) -> void:
	_guardian = guardian
	_sync_display()


func get_ability_slot() -> Control:
	return _ability_slot


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


func _on_ability_slot_mouse_entered() -> void:
	_is_hovered = true
	_sync_hover_style()


func _on_ability_slot_mouse_exited() -> void:
	_is_hovered = false
	_sync_hover_style()


func _sync_hover_style() -> void:
	if not _ability_style:
		return
	_ability_style.border_color = HOVER_BORDER_COLOR if _is_hovered else _base_border_color
	_ability_style.shadow_color = HOVER_GLOW_COLOR if _is_hovered else _base_shadow_color
	_ability_style.shadow_size = 14 if _is_hovered else _base_shadow_size


func _sync_display() -> void:
	var should_show := is_instance_valid(_guardian) \
		and _guardian.is_placed() \
		and _guardian.get_current_mode_id() == MODE_SIGNAL_BOOST
	_ability_slot.visible = should_show
	_can_activate = false
	if not should_show:
		return

	var state_id := _guardian.get_signal_boost_state_id()
	var remaining_seconds := ceili(_guardian.get_signal_boost_time_remaining())
	_can_activate = state_id == STATE_READY
	if _signal_boost_icon:
		_signal_boost_icon.self_modulate = Color.WHITE if _can_activate else DISABLED_ICON_COLOR
	if not _status_label:
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
