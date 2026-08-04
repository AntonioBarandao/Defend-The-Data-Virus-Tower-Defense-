extends SceneTree

const ADMIN_SCENE := preload("res://Scenes/Gameplay/Admin_Sandbox.tscn")
const TEST_VIEWPORT_SIZE := Vector2i(2520, 1080)
const POSITION_TOLERANCE := 3.0

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = TEST_VIEWPORT_SIZE
	root.add_child(viewport)

	var game := ADMIN_SCENE.instantiate()
	viewport.add_child(game)
	await process_frame
	await process_frame

	var store_canvases := game.find_children("TowerStoreHUD", "CanvasLayer", true, true)
	var store_panels := game.find_children("TestDrag", "Control", true, true)
	var generated_store_panels := game.find_children("TowerStorePanel", "Control", true, true)
	var authored_store := game.get_node("TowerStoreHUD/TestDrag") as Control
	var direct_card_count := 0
	var direct_title_count := 0
	for child in authored_store.get_children():
		if child is TowerShopCard:
			direct_card_count += 1
		var label := child as Label
		if label != null and label.text == "TOWER SHOP":
			direct_title_count += 1
	_expect(
		store_canvases.size() == 1,
		"Tower shop startup created a duplicate TowerStoreHUD."
	)
	_expect(
		store_panels.size() == 1,
		"Tower shop scene contains an inherited proxy TestDrag panel."
	)
	_expect(
		generated_store_panels.is_empty(),
		"Tower shop startup created a fallback proxy instead of using the authored shop."
	)
	_expect(direct_card_count == 8, "Tower shop does not contain exactly eight authored cards.")
	_expect(direct_title_count == 1, "Tower shop contains a duplicate title.")

	var background := game.get_node(
		"TowerStoreHUD/TestDrag/TowerTrayBackground"
	) as Control
	var toggle := game.get_node(
		"TowerStoreHUD/TestDrag/TowerStoreToggleButton"
	) as Control
	var wave_label := game.get_node("GameControlsHUD/Root/WavesLabel") as Control
	var lives_panel := game.get_node("GameControlsHUD/Root/LivesPanel") as Control
	var wave_set_panel := game.get_node(
		"CutsceneDemoMenuHUD/Root/WaveSetPanel"
	) as Control
	var guardian_card := game.get_node(
		"TowerStoreHUD/TestDrag/CyberGuardianCard"
	) as Control

	var background_center := background.get_global_rect().get_center()
	_expect(
		bool(game.call("_tower_store_blocks_point", background_center)),
		"Tower shop no longer blocks world input at its screen-space position."
	)
	var card_screen_position := guardian_card.get_global_rect().get_center()
	var card_world_position := game.call(
		"_screen_to_canvas_position",
		card_screen_position
	) as Vector2
	_expect(
		bool(
			game.call(
				"_try_begin_any_store_tower_drag",
				card_screen_position,
				card_world_position
			)
		),
		"Tower-card drag did not accept screen-space card input."
	)
	game.call("_clear_pending_store_tower_drag")

	game.call("_set_tower_store_open", false)
	await create_timer(0.5).timeout

	_expect_close(
		toggle.get_global_rect().end.x,
		float(TEST_VIEWPORT_SIZE.x) - 8.0,
		"Closed tower-shop toggle did not stop at the phone's right inset."
	)
	_expect_close(
		wave_label.get_global_rect().end.x,
		float(TEST_VIEWPORT_SIZE.x) - 13.0,
		"Wave label did not occupy the freed top-right space."
	)
	_expect_close(
		lives_panel.get_global_rect().end.x,
		float(TEST_VIEWPORT_SIZE.x) - 13.0,
		"Lives panel did not follow the wave label."
	)
	_expect_close(
		wave_set_panel.get_global_rect().end.x,
		float(TEST_VIEWPORT_SIZE.x) - 2.0,
		"Wave-set panel did not follow the closed shop."
	)

	game.call("_set_tower_store_open", true)
	await create_timer(0.5).timeout
	_expect_close(
		background.get_global_rect().end.x,
		float(TEST_VIEWPORT_SIZE.x) + 1.146,
		"Tower shop did not return to the ultrawide right edge."
	)

	game.call("_show_laser_upgrade_panel")
	await create_timer(0.35).timeout
	var upgrade_hud := game.get_node("TowerUpgradeHUD") as TowerUpgradeHUD
	_expect(
		upgrade_hud.is_laser_panel_visible(),
		"Tower selection did not reveal the inherited upgrade sidebar."
	)
	_expect(
		not bool(game.get("_tower_store_open")),
		"Tower shop stayed open behind the upgrade sidebar."
	)

	var emulated_touch_mouse := InputEventMouseButton.new()
	emulated_touch_mouse.device = InputEvent.DEVICE_ID_EMULATION
	emulated_touch_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_touch_mouse.position = Vector2(120.0, 120.0)
	emulated_touch_mouse.pressed = true
	game.call("_input", emulated_touch_mouse)
	await process_frame
	_expect(
		upgrade_hud.is_laser_panel_visible(),
		"Emulated touch mouse input immediately closed the tower sidebar."
	)
	_expect(
		not bool(game.get("_tower_store_open")),
		"Emulated touch mouse input immediately restored the tower shop."
	)

	game.call("_close_tower_upgrade_sidebar")
	await create_timer(0.55).timeout
	_expect(
		not upgrade_hud.is_any_panel_visible(),
		"Tower sidebar did not close through its normal lifecycle."
	)
	_expect(
		bool(game.get("_tower_store_open")),
		"Tower shop did not return after the sidebar closed."
	)

	viewport.queue_free()
	await process_frame
	quit(1 if _failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _expect_close(actual: float, expected: float, message: String) -> void:
	if absf(actual - expected) <= POSITION_TOLERANCE:
		return
	_failed = true
	push_error("%s Expected %.3f, got %.3f." % [message, expected, actual])
