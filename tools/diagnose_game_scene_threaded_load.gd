extends SceneTree

const DEFAULT_TARGET_SCENE_PATH := "res://Scenes/Gameplay/Normal_Game.tscn"
const STALL_TIMEOUT_MSEC := 60000
const TOTAL_TIMEOUT_MSEC := 180000


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var target_scene_path := DEFAULT_TARGET_SCENE_PATH
	var user_arguments := OS.get_cmdline_user_args()
	if not user_arguments.is_empty():
		target_scene_path = user_arguments[0]
	var request_error := ResourceLoader.load_threaded_request(
		target_scene_path,
		"PackedScene",
		false
	)
	if request_error != OK and request_error != ERR_BUSY:
		push_error("Threaded game load request failed: %s" % request_error)
		quit(1)
		return

	var progress_data: Array = []
	var last_progress := -1.0
	var last_change_msec := Time.get_ticks_msec()
	var deadline_msec := last_change_msec + TOTAL_TIMEOUT_MSEC
	while Time.get_ticks_msec() < deadline_msec:
		progress_data.clear()
		var status := ResourceLoader.load_threaded_get_status(target_scene_path, progress_data)
		var progress := float(progress_data[0]) if not progress_data.is_empty() else last_progress
		if not is_equal_approx(progress, last_progress):
			last_progress = progress
			last_change_msec = Time.get_ticks_msec()
			print("%s threaded load: %d%%" % [target_scene_path, roundi(progress * 100.0)])

		match status:
			ResourceLoader.THREAD_LOAD_LOADED:
				var packed_scene := ResourceLoader.load_threaded_get(target_scene_path) as PackedScene
				if packed_scene == null:
					push_error("Threaded game load returned a non-scene resource.")
					quit(1)
					return
				print("%s threaded load completed." % target_scene_path)
				quit(0)
				return
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("Threaded game load failed with status %s." % status)
				quit(1)
				return

		if Time.get_ticks_msec() - last_change_msec >= STALL_TIMEOUT_MSEC:
			push_error("Threaded game load stalled at %d%%." % roundi(last_progress * 100.0))
			quit(2)
			return
		await process_frame

	push_error("Threaded game load exceeded its total timeout.")
	quit(3)
