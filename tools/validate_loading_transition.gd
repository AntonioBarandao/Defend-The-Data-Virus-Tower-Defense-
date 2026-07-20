extends SceneTree

const TARGET_SCENE_PATH := "res://Scenes/Gameplay/Normal_Game.tscn"
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
