class_name CutsceneSkipHUD
extends CanvasLayer

const MAX_INPUT_LAYER := 4095

@export var text_cutscene_hud_path: NodePath = ^"../TextCutsceneHUD"
@export var announce_text_hud_path: NodePath = ^"../AnnounceTextHUD"

@onready var _skip_button: Button = $Root/SkipButton

var _text_cutscene_hud: Node
var _announce_text_hud: AnnounceTextHUD
var _victory_screen_active := false


func _ready() -> void:
	layer = maxi(layer, MAX_INPUT_LAYER)
	_text_cutscene_hud = get_node_or_null(text_cutscene_hud_path)
	_announce_text_hud = get_node_or_null(announce_text_hud_path) as AnnounceTextHUD
	_skip_button.pressed.connect(_on_skip_pressed)
	_skip_button.gui_input.connect(_on_skip_button_gui_input)
	_skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_skip_button.disabled = true
	hide()
	set_process(true)


func _input(event: InputEvent) -> void:
	if handle_cutscene_skip_input(event):
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var running := not _victory_screen_active and _is_cutscene_running()
	visible = running
	_skip_button.disabled = not running


func set_victory_screen_active(active: bool) -> void:
	_victory_screen_active = active
	if active:
		_skip_button.disabled = true
		hide()


func handle_cutscene_skip_input(event: InputEvent) -> bool:
	if not event_targets_skip_button(event):
		return false

	_on_skip_pressed()
	return true


func event_targets_skip_button(event: InputEvent) -> bool:
	if _victory_screen_active \
			or not _is_cutscene_running() \
			or not _is_primary_press(event):
		return false
	if not is_instance_valid(_skip_button) or _skip_button.disabled:
		return false

	return _skip_button.get_global_rect().has_point(_get_press_position(event))


func _on_skip_pressed() -> void:
	if not _is_cutscene_running():
		return

	_skip_button.disabled = true
	_text_cutscene_hud.call("skip_cutscene")

	if _announce_text_hud != null:
		_announce_text_hud.show_message("Cutscene Skipped", 3.0)


func _on_skip_button_gui_input(event: InputEvent) -> void:
	if not event_targets_skip_button(event):
		return

	_skip_button.accept_event()
	get_viewport().set_input_as_handled()
	_on_skip_pressed()


func _is_cutscene_running() -> bool:
	return _text_cutscene_hud != null \
		and _text_cutscene_hud.has_method("is_cutscene_running") \
		and bool(_text_cutscene_hud.call("is_cutscene_running"))


func _is_primary_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		return mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT

	if event is InputEventScreenTouch:
		var screen_touch := event as InputEventScreenTouch
		return screen_touch.pressed

	return false


func _get_press_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position

	return Vector2.ZERO
