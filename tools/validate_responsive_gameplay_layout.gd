extends SceneTree

const GAME_SCENE := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const GameplaySafeArea := preload("res://Scripts/Gameplay/gameplay_safe_area.gd")
const TEST_VIEWPORTS: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(2520, 1080)
]
const POSITION_TOLERANCE := 2.0

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for viewport_size in TEST_VIEWPORTS:
		await _validate_viewport(viewport_size)

	quit(1 if _failed else 0)


func _validate_viewport(viewport_size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	root.add_child(viewport)

	var game := GAME_SCENE.instantiate()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.set_script(null)
	viewport.add_child(game)
	await process_frame
	await process_frame

	var expected_width := float(viewport_size.x)
	var expected_center := Vector2(viewport_size) * 0.5
	var gameplay_safe_rect := GameplaySafeArea.get_centered_screen_rect(viewport)
	var store_root := game.get_node("TowerStoreHUD/TestDrag") as Control
	var store_background := game.get_node(
		"TowerStoreHUD/TestDrag/TowerTrayBackground"
	) as Control
	var hamburger := game.get_node(
		"CutsceneDemoMenuHUD/Root/HamburgerButton"
	) as Control
	var wave_set_panel := game.get_node(
		"CutsceneDemoMenuHUD/Root/WaveSetPanel"
	) as Control
	var wave_label := game.get_node("GameControlsHUD/Root/WavesLabel") as Control
	var wave_timer := game.get_node("GameControlsHUD/Root/WaveTimerLabel") as Control
	var lives_panel := game.get_node("GameControlsHUD/Root/LivesPanel") as Control
	var arena := game.get_node("CpuArena") as Sprite2D

	_expect_close(
		store_root.anchor_left,
		1.0,
		"Tower shop root must remain right-anchored at %s." % viewport_size
	)
	_expect_close(
		store_background.get_global_rect().end.x,
		expected_width + 1.146,
		"Tower shop did not follow the right edge at %s." % viewport_size
	)
	_expect_close(
		hamburger.get_global_rect().get_center().x,
		expected_center.x,
		"Hamburger button was not top-centered at %s." % viewport_size
	)
	_expect_close(
		wave_label.get_global_rect().end.x,
		expected_width - 373.0,
		"Wave label lost its top-right anchor at %s." % viewport_size
	)
	_expect_close(
		wave_timer.get_global_rect().end.x,
		expected_width - 373.0,
		"Wave timer lost its top-right anchor at %s." % viewport_size
	)
	_expect_close(
		lives_panel.get_global_rect().end.x,
		expected_width - 373.0,
		"Lives panel lost its top-right anchor at %s." % viewport_size
	)
	_expect_close(
		wave_set_panel.get_global_rect().end.x,
		expected_width - 362.0,
		"Wave-set panel lost its top-right anchor at %s." % viewport_size
	)

	var arena_screen_center := arena.get_global_transform_with_canvas() * Vector2.ZERO
	_expect_close(
		arena_screen_center.x,
		expected_center.x,
		"Gameplay map was not horizontally centered at %s." % viewport_size,
		6.0
	)
	_expect_close(
		gameplay_safe_rect.get_center().x,
		expected_center.x,
		"Gameplay safe area was not centered at %s." % viewport_size
	)
	_expect_close(
		gameplay_safe_rect.size.x / gameplay_safe_rect.size.y,
		16.0 / 9.0,
		"Gameplay safe area did not retain 16:9 at %s." % viewport_size,
		0.001
	)

	viewport.queue_free()
	await process_frame


func _expect_close(
	actual: float,
	expected: float,
	message: String,
	tolerance := POSITION_TOLERANCE
) -> void:
	if absf(actual - expected) <= tolerance:
		return

	_failed = true
	push_error("%s Expected %.3f, got %.3f." % [message, expected, actual])
