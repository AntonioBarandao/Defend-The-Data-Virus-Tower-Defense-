extends SceneTree

const TARGET_SCENE_PATH := "res://Scenes/Gameplay/Normal_Game.tscn"
const MAIN_MENU_SCENE_PATH := "res://Scenes/Menus/MainMenu.tscn"
const INVALID_TARGET_SCENE_PATH := "res://Scenes/Gameplay/Missing_Load_Target.tscn"
const POSITION_TOLERANCE := 0.5

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var loading_scene := load(LoadingScreen.LOADING_SCREEN_SCENE_PATH) as PackedScene
	var reference_screen := loading_scene.instantiate() as LoadingScreen
	var towers_target := (reference_screen.get_node("ArtworkLayer/Towers") as Node2D).position
	var viruses_target := (reference_screen.get_node("ArtworkLayer/Viruses") as Node2D).position
	reference_screen.free()

	var placeholder := Node.new()
	root.add_child(placeholder)
	current_scene = placeholder

	var change_error := LoadingScreen.open_game_scene(self, TARGET_SCENE_PATH)
	_check(change_error == OK, "Loading screen route should start successfully.")
	await process_frame
	await process_frame

	var loading_screen := current_scene as LoadingScreen
	_check(loading_screen != null, "The loading screen should become the current scene.")
	if loading_screen == null:
		quit(1)
		return
	loading_screen.minimum_visible_seconds = 180.0

	_check(
		loading_screen.target_scene_path == TARGET_SCENE_PATH,
		"The requested destination should be passed to the loading screen."
	)
	_check(not loading_screen.use_sub_threads, "Gameplay loading should avoid nested worker sub-threads.")
	_check(
		loading_screen.stall_timeout_seconds >= 180.0,
		"Slow first-time imports should not trigger the old 60-second false stall."
	)
	_check(
		is_equal_approx(loading_screen.failure_return_delay_seconds, 3.0),
		"Loading failures should use a three-second return countdown."
	)
	var towers := loading_screen.get_node("ArtworkLayer/Towers") as Node2D
	var viruses := loading_screen.get_node("ArtworkLayer/Viruses") as Node2D
	_check(towers.position.x > towers_target.x, "Towers should enter from the right.")
	_check(viruses.position.x < viruses_target.x, "Viruses should enter from the left.")

	var load_deadline_msec := Time.get_ticks_msec() + 60000
	while not bool(loading_screen.get("_load_complete")) and Time.get_ticks_msec() < load_deadline_msec:
		await process_frame
	_check(bool(loading_screen.get("_load_requested")), "The target scene should be requested through the threaded loader.")
	_check(bool(loading_screen.get("_load_complete")), "The threaded target scene load should complete.")
	_check(
		is_equal_approx(float(loading_screen.get("_displayed_progress")), float(loading_screen.get("_raw_progress"))),
		"The displayed percentage should match the loader's reported progress."
	)

	await create_timer(
		loading_screen.artwork_slide_seconds + 0.04
	).timeout
	_check(towers.position.distance_to(towers_target) <= POSITION_TOLERANCE, "Towers should finish at their authored position.")
	_check(viruses.position.distance_to(viruses_target) <= POSITION_TOLERANCE, "Viruses should finish at their authored position.")

	loading_screen.minimum_visible_seconds = 0.0
	var transition_deadline_msec := Time.get_ticks_msec() + 30000
	while current_scene == loading_screen and Time.get_ticks_msec() < transition_deadline_msec:
		await process_frame
	_check(
		current_scene != null and current_scene.scene_file_path == TARGET_SCENE_PATH,
		"The destination scene should open after loading and the entrance animation finish."
	)

	root.set_meta(
		LoadingScreen.TARGET_SCENE_META,
		INVALID_TARGET_SCENE_PATH
	)
	var failure_route_error := change_scene_to_file(
		LoadingScreen.LOADING_SCREEN_SCENE_PATH
	)
	_check(
		failure_route_error == OK,
		"The loading failure test should open the loading screen."
	)
	await process_frame
	await process_frame
	var failed_loading_screen := current_scene as LoadingScreen
	_check(
		failed_loading_screen != null
			and bool(failed_loading_screen.get("_load_failed")),
		"An invalid destination should enter loading failure recovery."
	)
	if failed_loading_screen != null:
		var failed_label := failed_loading_screen.get_node(
			"LoadingPanel/Margin/Content/LoadingLabel"
		) as Label
		_check(
			"Returning to Main Menu in 3" in failed_label.text,
			"The loading failure should display the three-second countdown."
		)
	var fallback_deadline_msec := Time.get_ticks_msec() + 5000
	while current_scene == failed_loading_screen \
			and Time.get_ticks_msec() < fallback_deadline_msec:
		await process_frame
	_check(
		current_scene != null
			and current_scene.scene_file_path == MAIN_MENU_SCENE_PATH,
		"A stalled or failed load should return to Main Menu."
	)

	if _failed:
		quit(1)
	else:
		print("Loading transition validation passed.")
		quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
