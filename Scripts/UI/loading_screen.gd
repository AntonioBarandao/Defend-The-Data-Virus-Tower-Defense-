class_name LoadingScreen
extends Control

const LOADING_SCREEN_SCENE_PATH := "res://Scenes/UI/LoadingScreen.tscn"
const TARGET_SCENE_META := &"loading_screen_target_scene"

@export_file("*.tscn") var target_scene_path := "res://Scenes/Gameplay/Cutscene_Test_Game.tscn"
@export_range(0.0, 5.0, 0.05) var minimum_visible_seconds := 0.8
@export var use_sub_threads := false
@export_range(30.0, 600.0, 1.0) var stall_timeout_seconds := 180.0
@export_group("Failure Recovery")
@export_file("*.tscn") var fallback_scene_path := "res://Scenes/Menus/MainMenu.tscn"
@export_range(0.5, 10.0, 0.1) var failure_return_delay_seconds := 3.0
@export_group("Artwork Entrance")
@export_node_path("Node2D") var towers_group_path := NodePath("ArtworkLayer/Towers")
@export_node_path("Node2D") var viruses_group_path := NodePath("ArtworkLayer/Viruses")
@export_range(0.0, 3000.0, 10.0) var artwork_slide_distance := 2050.0
@export_range(0.1, 3.0, 0.05) var artwork_slide_seconds := 0.9
@export_range(0.0, 1.0, 0.05) var virus_entrance_delay := 0.08

var _elapsed := 0.0
var _displayed_progress := 0.0
var _raw_progress := 0.0
var _progress_data: Array = []
var _load_failed := false
var _load_requested := false
var _load_complete := false
var _transition_started := false
var _artwork_entrance_finished := false
var _last_progress_change_msec := 0
var _last_reported_progress := -1.0
var _failure_message := ""
var _failure_return_remaining := 0.0
var _failure_countdown_second := -1

@onready var _loading_label: Label = $LoadingPanel/Margin/Content/LoadingLabel
@onready var _progress_bar: ProgressBar = $LoadingPanel/Margin/Content/ProgressWrap/ProgressBar
@onready var _progress_pulse: ColorRect = $LoadingPanel/Margin/Content/ProgressWrap/ProgressPulse


static func open_game_scene(scene_tree: SceneTree, destination_path: String) -> Error:
	if scene_tree == null or scene_tree.root == null:
		return ERR_UNCONFIGURED
	if destination_path.is_empty() or not ResourceLoader.exists(destination_path):
		return ERR_FILE_NOT_FOUND
	if destination_path == LOADING_SCREEN_SCENE_PATH:
		return ERR_INVALID_PARAMETER

	scene_tree.root.set_meta(TARGET_SCENE_META, destination_path)
	var change_error := scene_tree.change_scene_to_file(LOADING_SCREEN_SCENE_PATH)
	if change_error != OK:
		scene_tree.root.remove_meta(TARGET_SCENE_META)
	return change_error


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_requested_target_scene()
	_progress_bar.value = 0.0
	_update_loading_text()
	_play_artwork_entrance()

	if not ResourceLoader.exists(target_scene_path):
		_fail_loading()


func _process(delta: float) -> void:
	if _load_failed:
		_update_failure_return(delta)
		return
	if _transition_started:
		return

	_elapsed += delta
	if not _load_requested:
		_request_target_scene()
		if _load_failed:
			return

	_poll_loading_progress()
	if _load_failed:
		return
	_displayed_progress = _raw_progress
	_sync_progress_visuals()

	if (
		_load_complete
		and _elapsed >= minimum_visible_seconds
		and _artwork_entrance_finished
	):
		_transition_to_target_scene()


func _request_target_scene() -> void:
	var request_error := ResourceLoader.load_threaded_request(
		target_scene_path,
		"PackedScene",
		use_sub_threads
	)
	if request_error != OK and request_error != ERR_BUSY:
		_fail_loading()
		return
	_load_requested = true
	_last_progress_change_msec = Time.get_ticks_msec()
	_last_reported_progress = -1.0


func _apply_requested_target_scene() -> void:
	var scene_root := get_tree().root
	if not scene_root.has_meta(TARGET_SCENE_META):
		return

	var requested_path := str(scene_root.get_meta(TARGET_SCENE_META, ""))
	scene_root.remove_meta(TARGET_SCENE_META)
	if not requested_path.is_empty():
		target_scene_path = requested_path


func _play_artwork_entrance() -> void:
	var towers := get_node_or_null(towers_group_path) as Node2D
	var viruses := get_node_or_null(viruses_group_path) as Node2D
	if towers == null and viruses == null:
		_artwork_entrance_finished = true
		return

	var entrance_tween := create_tween().set_parallel(true)
	entrance_tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var resolved_virus_delay := minf(
		virus_entrance_delay,
		maxf(0.0, artwork_slide_seconds - 0.05)
	)
	var virus_slide_seconds := maxf(0.05, artwork_slide_seconds - resolved_virus_delay)
	if towers != null:
		var towers_target := towers.position
		towers.position = towers_target + Vector2.RIGHT * artwork_slide_distance
		towers.modulate.a = 0.15
		entrance_tween.tween_property(towers, "position", towers_target, artwork_slide_seconds)
		entrance_tween.tween_property(towers, "modulate:a", 1.0, artwork_slide_seconds)
	if viruses != null:
		var viruses_target := viruses.position
		viruses.position = viruses_target + Vector2.LEFT * artwork_slide_distance
		viruses.modulate.a = 0.15
		entrance_tween.tween_property(viruses, "position", viruses_target, virus_slide_seconds).set_delay(resolved_virus_delay)
		entrance_tween.tween_property(viruses, "modulate:a", 1.0, virus_slide_seconds).set_delay(resolved_virus_delay)

	entrance_tween.chain().tween_callback(func() -> void: _artwork_entrance_finished = true)


func _poll_loading_progress() -> void:
	_progress_data.clear()
	var status := ResourceLoader.load_threaded_get_status(target_scene_path, _progress_data)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not _progress_data.is_empty():
				var reported_progress := clampf(float(_progress_data[0]), 0.0, 1.0)
				if _last_reported_progress < 0.0 \
						or not is_equal_approx(
							reported_progress,
							_last_reported_progress
						):
					_last_progress_change_msec = Time.get_ticks_msec()
					_last_reported_progress = reported_progress
				_raw_progress = maxf(_raw_progress, reported_progress)
			if (
				_last_progress_change_msec > 0
				and Time.get_ticks_msec() - _last_progress_change_msec >= int(stall_timeout_seconds * 1000.0)
			):
				_fail_loading("Loading Stalled")
		ResourceLoader.THREAD_LOAD_LOADED:
			_raw_progress = 1.0
			_load_complete = true
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
	var packed_scene: PackedScene
	if _load_complete:
		packed_scene = ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
	if packed_scene == null:
		_fail_loading()
		return

	get_tree().change_scene_to_packed(packed_scene)


func _fail_loading(message := "Loading Failed") -> void:
	if _load_failed:
		return

	_load_failed = true
	_transition_started = false
	_failure_message = message
	_failure_return_remaining = failure_return_delay_seconds
	_failure_countdown_second = -1
	_loading_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.26, 1.0))
	if _progress_pulse != null:
		_progress_pulse.hide()
	_update_failure_return(0.0)


func _update_failure_return(delta: float) -> void:
	if not _load_failed or _transition_started:
		return

	_failure_return_remaining = maxf(
		0.0,
		_failure_return_remaining - maxf(0.0, delta)
	)
	var countdown_second := maxi(0, ceili(_failure_return_remaining))
	if countdown_second != _failure_countdown_second:
		_failure_countdown_second = countdown_second
		_loading_label.text = "%s - Returning to Main Menu in %d..." % [
			_failure_message,
			countdown_second,
		]
	if _failure_return_remaining <= 0.0:
		_return_to_fallback_scene()


func _return_to_fallback_scene() -> void:
	if _transition_started:
		return
	if fallback_scene_path.is_empty() \
			or fallback_scene_path == LOADING_SCREEN_SCENE_PATH \
			or not ResourceLoader.exists(fallback_scene_path):
		_loading_label.text = "Unable to return to Main Menu"
		push_error("Loading fallback scene is invalid: %s" % fallback_scene_path)
		return

	_transition_started = true
	get_tree().paused = false
	var change_error := get_tree().change_scene_to_file(fallback_scene_path)
	if change_error == OK:
		return

	_transition_started = false
	_loading_label.text = "Unable to return to Main Menu"
	push_error(
		"Could not open loading fallback scene %s (error %d)."
			% [fallback_scene_path, change_error]
	)
