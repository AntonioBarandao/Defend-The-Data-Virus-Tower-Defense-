class_name LoadingScreen
extends Control

@export_file("*.tscn") var target_scene_path := "res://Scenes/Gameplay/Cutscene_Test_Game.tscn"
@export_range(0.0, 5.0, 0.05) var minimum_visible_seconds := 0.8
@export_range(0.1, 6.0, 0.1) var progress_fill_speed := 1.8

var _elapsed := 0.0
var _displayed_progress := 0.0
var _raw_progress := 0.0
var _progress_data: Array = []
var _load_failed := false
var _transition_started := false

@onready var _loading_label: Label = $LoadingPanel/Margin/Content/LoadingLabel
@onready var _progress_bar: ProgressBar = $LoadingPanel/Margin/Content/ProgressWrap/ProgressBar
@onready var _progress_pulse: ColorRect = $LoadingPanel/Margin/Content/ProgressWrap/ProgressPulse


func _ready() -> void:
	_progress_bar.value = 0.0
	_update_loading_text()

	if not ResourceLoader.exists(target_scene_path):
		_fail_loading()
		return

	var request_error := ResourceLoader.load_threaded_request(target_scene_path)
	if request_error != OK:
		_fail_loading()


func _process(delta: float) -> void:
	if _load_failed or _transition_started:
		return

	_elapsed += delta
	_poll_loading_progress()
	_displayed_progress = move_toward(_displayed_progress, _raw_progress, progress_fill_speed * delta)
	_sync_progress_visuals()

	if _raw_progress >= 1.0 and _displayed_progress >= 0.995 and _elapsed >= minimum_visible_seconds:
		_transition_to_target_scene()


func _poll_loading_progress() -> void:
	_progress_data.clear()
	var status := ResourceLoader.load_threaded_get_status(target_scene_path, _progress_data)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not _progress_data.is_empty():
				_raw_progress = maxf(_raw_progress, clampf(float(_progress_data[0]), 0.0, 1.0))
		ResourceLoader.THREAD_LOAD_LOADED:
			_raw_progress = 1.0
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail_loading()


func _sync_progress_visuals() -> void:
	var percentage := clampi(roundi(_displayed_progress * 100.0), 0, 100)
	_progress_bar.value = percentage
	_update_loading_text(percentage)
	_sync_progress_pulse()


func _update_loading_text(percentage := 0) -> void:
	_loading_label.text = "Loading Game... %d%%" % percentage


func _sync_progress_pulse() -> void:
	if _progress_pulse == null or _progress_bar == null:
		return

	_progress_pulse.visible = _displayed_progress > 0.02
	var bar_width := _progress_bar.size.x
	var pulse_width := _progress_pulse.size.x
	_progress_pulse.position.x = clampf((_displayed_progress * bar_width) - pulse_width * 0.5, 0.0, maxf(0.0, bar_width - pulse_width))


func _transition_to_target_scene() -> void:
	_transition_started = true
	var loaded_resource := ResourceLoader.load_threaded_get(target_scene_path)
	var packed_scene := loaded_resource as PackedScene
	if packed_scene == null:
		_fail_loading()
		return

	get_tree().change_scene_to_packed(packed_scene)


func _fail_loading() -> void:
	_load_failed = true
	_loading_label.text = "Loading Failed"
	_loading_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.26, 1.0))
	_progress_bar.value = 0.0
	if _progress_pulse != null:
		_progress_pulse.hide()
