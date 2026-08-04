extends SceneTree

const TOWER_UPGRADE_HUD_SCENE := preload(
	"res://Scenes/UI/TowerUpgradeHud.tscn"
)
const DEFEAT_HUD_SCENE := preload("res://Scenes/UI/DefeatHUD.tscn")
const LOADING_SCREEN_SCENE := preload("res://Scenes/UI/LoadingScreen.tscn")
const MOBILE_ULTRAWIDE_SIZE := Vector2i(2520, 1080)
const POSITION_TOLERANCE := 1.0

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = MOBILE_ULTRAWIDE_SIZE
	await process_frame

	await _validate_tower_sidebar()
	await _validate_defeat_display()
	await _validate_loading_artwork()

	if _failed:
		quit(1)
	else:
		print("Mobile overlay layout validation passed.")
		quit(0)


func _validate_tower_sidebar() -> void:
	var hud := TOWER_UPGRADE_HUD_SCENE.instantiate() as TowerUpgradeHUD
	root.add_child(hud)
	await process_frame
	hud.show_laser_panel()
	await create_timer(hud.slide_seconds + 0.05).timeout

	var hud_root := hud.get_node("Root") as Control
	var panel := hud.get_node("Root/MenuPanel") as PanelContainer
	_check(
		hud_root.size.x > 1920.0,
		"Tower sidebar validation did not receive an ultrawide HUD."
	)
	var expected_position := Vector2(
		hud_root.size.x - panel.size.x - hud.right_margin,
		maxf(0.0, (hud_root.size.y - panel.size.y) * 0.5)
	)
	_check(
		panel.position.distance_to(expected_position) <= POSITION_TOLERANCE,
		"Tower sidebar must center vertically against the mobile HUD edge."
	)
	hud.queue_free()
	await process_frame


func _validate_defeat_display() -> void:
	var hud := DEFEAT_HUD_SCENE.instantiate() as DefeatHUD
	root.add_child(hud)
	await process_frame

	var hud_root := hud.get_node("Root") as Control
	var display_anchor := hud.get_node("Root/DisplayAnchor") as Control
	_check(
		display_anchor.position.distance_to(hud_root.size * 0.5)
			<= POSITION_TOLERANCE,
		"Defeat display must use the mobile viewport center."
	)
	hud.queue_free()
	await process_frame


func _validate_loading_artwork() -> void:
	var loading := LOADING_SCREEN_SCENE.instantiate() as LoadingScreen
	var towers := loading.get_node("ArtworkLayer/Towers") as Node2D
	var viruses := loading.get_node("ArtworkLayer/Viruses") as Node2D
	var authored_towers_position := towers.position
	var authored_viruses_position := viruses.position
	loading.target_scene_path = "res://Scenes/Menus/MainMenu.tscn"
	loading.minimum_visible_seconds = 120.0
	loading.artwork_slide_distance = 0.0
	root.add_child(loading)
	loading.set_process(false)
	await process_frame

	var expected_extension := maxf(
		0.0,
		loading.size.x - loading.artwork_design_width
	)
	_check(
		expected_extension > 0.0,
		"Loading-screen validation did not receive an ultrawide canvas."
	)
	_check(
		towers.position.distance_to(
			authored_towers_position + Vector2(expected_extension, 0.0)
		) <= POSITION_TOLERANCE,
		"Loading-screen towers must remain anchored to the right edge."
	)
	_check(
		viruses.position.distance_to(authored_viruses_position)
			<= POSITION_TOLERANCE,
		"Loading-screen viruses must retain their left-authored position."
	)
	loading.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
