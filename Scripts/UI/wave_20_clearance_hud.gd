class_name Wave20ClearanceHUD
extends CanvasLayer

signal choice_made(continue_selected: bool)

@export_range(0.1, 1.5, 0.05) var appear_duration := 0.42
@export_range(0.1, 1.5, 0.05) var disappear_duration := 0.28
@export_range(20.0, 240.0, 1.0) var slide_distance := 72.0
@export var dim_color := Color(0.025, 0.03, 0.045, 0.82)

@onready var _root: Control = $Root
@onready var _dim_overlay: ColorRect = $Root/DimOverlay
@onready var _clearance_panel: PanelContainer = $Root/ClearancePanel
@onready var _yes_button: Button = $Root/ClearancePanel/Margin/Content/Choices/YesButton
@onready var _no_button: Button = $Root/ClearancePanel/Margin/Content/Choices/NoButton

var _running := false
var _panel_final_position := Vector2.ZERO
var _transition_tween: Tween


func _ready() -> void:
	_yes_button.pressed.connect(func() -> void: _select_choice(true))
	_no_button.pressed.connect(func() -> void: _select_choice(false))
	_panel_final_position = _clearance_panel.global_position
	_root.hide()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_clearance() -> void:
	if _running:
		return

	_running = true
	visible = true
	_root.show()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_yes_button.disabled = false
	_no_button.disabled = false
	await get_tree().process_frame
	_panel_final_position = _clearance_panel.global_position
	_clearance_panel.pivot_offset = _clearance_panel.size * 0.5
	_clearance_panel.global_position = _panel_final_position + Vector2(0.0, slide_distance)
	_clearance_panel.scale = Vector2(0.96, 0.96)
	_clearance_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_dim_overlay.color = Color(dim_color.r, dim_color.g, dim_color.b, 0.0)

	_kill_transition()
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(_dim_overlay, "color", dim_color, appear_duration)
	_transition_tween.tween_property(
		_clearance_panel,
		"global_position",
		_panel_final_position,
		appear_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(
		_clearance_panel,
		"scale",
		Vector2.ONE,
		appear_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(
		_clearance_panel,
		"modulate",
		Color.WHITE,
		appear_duration * 0.75
	)
	await _transition_tween.finished
	_transition_tween = null
	if _running:
		_yes_button.grab_focus()


func is_cutscene_running() -> bool:
	return _running


func handle_clearance_input(event: InputEvent) -> bool:
	if not _running:
		return false

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return false
		if key_event.keycode == KEY_Y:
			_select_choice(true)
			return true
		if key_event.keycode == KEY_N or key_event.keycode == KEY_ESCAPE:
			_select_choice(false)
			return true

	var pointer_position := Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		pointer_position = mouse_event.position
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed:
			return false
		pointer_position = touch_event.position
	else:
		return false

	if _yes_button.get_global_rect().has_point(pointer_position):
		_select_choice(true)
		return true
	if _no_button.get_global_rect().has_point(pointer_position):
		_select_choice(false)
		return true
	return false


func _select_choice(continue_selected: bool) -> void:
	if not _running:
		return

	_yes_button.disabled = true
	_no_button.disabled = true
	_kill_transition()
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(
		_clearance_panel,
		"global_position",
		_panel_final_position - Vector2(0.0, slide_distance * 0.45),
		disappear_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_transition_tween.tween_property(
		_clearance_panel,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.0),
		disappear_duration
	)
	_transition_tween.tween_property(
		_dim_overlay,
		"color",
		Color(dim_color.r, dim_color.g, dim_color.b, 0.0),
		disappear_duration
	)
	await _transition_tween.finished
	_transition_tween = null

	_clearance_panel.global_position = _panel_final_position
	_clearance_panel.scale = Vector2.ONE
	_clearance_panel.modulate = Color.WHITE
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.hide()
	_running = false
	choice_made.emit(continue_selected)


func _kill_transition() -> void:
	if _transition_tween != null:
		_transition_tween.kill()
		_transition_tween = null
