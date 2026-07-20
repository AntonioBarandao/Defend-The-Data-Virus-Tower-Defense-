extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")


func _init() -> void:
	var game := NORMAL_GAME.instantiate()
	var old_menu_button := game.get_node_or_null("GameControlsHUD/Root/MainMenuButton") as Button
	var old_menu_panel := game.get_node_or_null("GameControlsHUD/Root/MainMenuPanel") as PanelContainer
	var clean_menu := game.get_node_or_null("CutsceneDemoMenuHUD") as CanvasLayer
	var hamburger := game.get_node_or_null("CutsceneDemoMenuHUD/Root/HamburgerButton") as Button
	var master_slider := game.get_node_or_null("CutsceneDemoMenuHUD/Root/MenuPanel/Margin/Content/SettingsPanel/Margin/Sliders/MasterRow/MasterSlider") as HSlider
	var music_slider := game.get_node_or_null("CutsceneDemoMenuHUD/Root/MenuPanel/Margin/Content/SettingsPanel/Margin/Sliders/MusicRow/MusicSlider") as HSlider
	var sound_slider := game.get_node_or_null("CutsceneDemoMenuHUD/Root/MenuPanel/Margin/Content/SettingsPanel/Margin/Sliders/SoundRow/SoundSlider") as HSlider

	if old_menu_button == null or old_menu_button.visible:
		_fail("Normal Game still exposes the legacy hamburger button.", game)
		return
	if old_menu_panel == null or old_menu_panel.visible:
		_fail("Normal Game still exposes the legacy menu panel.", game)
		return
	if clean_menu == null or not clean_menu.visible or hamburger == null or not hamburger.visible:
		_fail("Normal Game does not expose the cutscene hamburger menu.", game)
		return
	if master_slider == null or music_slider == null or sound_slider == null:
		_fail("Normal Game cutscene menu is missing one or more volume sliders.", game)
		return

	game.free()
	print("Normal Game hamburger menu validation passed.")
	quit(0)


func _fail(message: String, game: Node) -> void:
	push_error(message)
	game.free()
	quit(1)
