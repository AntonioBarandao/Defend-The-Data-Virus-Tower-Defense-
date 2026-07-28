extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load("res://Resources/CyberInfo/CyberInfoCatalog.tres") as CyberInfoCatalog
	_expect(catalog != null, "Cyber-Info catalog loads")
	if catalog == null:
		_finish()
		return

	_expect(catalog.tower_entries.size() == 8, "Catalog contains all 8 towers")
	_expect(catalog.virus_entries.size() >= 10, "Catalog contains notable virus families")
	_expect(_find_entry(catalog.virus_entries, &"armored_virus").images.size() > 1, "Armored Virus has a variant slideshow")
	_expect(_find_entry(catalog.virus_entries, &"red_virus").images.size() > 1, "Red Virus has an Anti-Charged slide")
	_expect(_find_entry(catalog.virus_entries, &"zombie_node").images.size() == 3, "Zombie Node has three progressive slides")

	var card_scene := load("res://Scenes/UI/CyberInfoCard.tscn") as PackedScene
	_expect(card_scene != null, "Cyber-Info card scene loads")
	if card_scene != null:
		var tower_card := card_scene.instantiate() as CyberInfoCard
		var manually_authored_texture := load(
			"res://assets/Enemies/Ransomware/RansomwareFrontHead.png"
		) as Texture2D
		var display_image := tower_card.get_node(
			"Margin/Content/ImageAspect/ImageFrame/DisplayImage"
		) as TextureRect
		tower_card.set_entry(catalog.tower_entries[0])
		display_image.texture = manually_authored_texture
		root.add_child(tower_card)
		await process_frame
		var image_aspect := tower_card.get_node("Margin/Content/ImageAspect") as AspectRatioContainer
		_expect(is_equal_approx(image_aspect.ratio, 1.0), "Card image uses a 1:1 aspect ratio")
		_expect(
			display_image.texture == manually_authored_texture,
			"Card preserves its manually authored display image at runtime"
		)
		catalog.tower_entries[0].emit_changed()
		await process_frame
		_expect(
			display_image.texture == manually_authored_texture,
			"Card preserves its display image after entry resource refresh"
		)
		var tower_style := (tower_card.get_node("Margin/Content/ImageAspect/ImageFrame") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
		_expect(tower_style.border_color.b > tower_style.border_color.r, "Tower image border is blue")
		tower_card.queue_free()

		var virus_card := card_scene.instantiate() as CyberInfoCard
		root.add_child(virus_card)
		virus_card.set_entry(catalog.virus_entries[0])
		await process_frame
		var virus_style := (virus_card.get_node("Margin/Content/ImageAspect/ImageFrame") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
		_expect(virus_style.border_color.r > virus_style.border_color.b, "Virus image border is red")
		virus_card.queue_free()

	var hud_scene := load("res://Scenes/UI/CyberInfoHUD.tscn") as PackedScene
	_expect(hud_scene != null, "Cyber-Info HUD scene loads")
	if hud_scene != null:
		var hud := hud_scene.instantiate() as CyberInfoHUD
		root.add_child(hud)
		await process_frame
		var tower_section := hud.get_node(
			"Root/Panel/Margin/Layout/Scroll/Pages/TowerSection"
		) as VBoxContainer
		var virus_section := hud.get_node(
			"Root/Panel/Margin/Layout/Scroll/Pages/VirusSection"
		) as VBoxContainer
		var tower_grid := hud.get_node(
			"Root/Panel/Margin/Layout/Scroll/Pages/TowerSection/TowerGrid"
		) as GridContainer
		var virus_grid := hud.get_node(
			"Root/Panel/Margin/Layout/Scroll/Pages/VirusSection/VirusGrid"
		) as GridContainer
		_expect(
			tower_grid.get_child_count() == catalog.tower_entries.size(),
			"Viewport contains every authored tower card"
		)
		_expect(
			virus_grid.get_child_count() == catalog.virus_entries.size(),
			"Viewport contains every authored virus card"
		)
		_validate_authored_cards(tower_grid, catalog.tower_entries, "tower")
		_validate_authored_cards(virus_grid, catalog.virus_entries, "virus")

		var hud_source := FileAccess.get_file_as_string("res://Scenes/UI/CyberInfoHUD.tscn")
		_expect(
			hud_source.count("[editable path=") == (
				catalog.tower_entries.size() + catalog.virus_entries.size()
			),
			"Every authored card instance exposes editable children"
		)

		hud.open()
		_expect(paused, "Opening Cyber-Info pauses the scene tree")
		_expect(hud.is_open(), "Cyber-Info reports its open state")
		_expect(tower_section.visible, "Tower tab shows the authored tower section")
		_expect(not virus_section.visible, "Tower tab hides the authored virus section")
		hud.show_page(CyberInfoHUD.Page.VIRUSES)
		await process_frame
		_expect(not tower_section.visible, "Virus tab hides the authored tower section")
		_expect(virus_section.visible, "Virus tab shows the authored virus section")
		hud.close()
		await create_timer(0.5, true).timeout
		_expect(not paused, "Closing Cyber-Info restores the prior pause state")
		hud.queue_free()

	_validate_entry_point("res://Scenes/UI/CutsceneDemoMenuHUD.tscn", "Root/MenuPanel/Margin/Content/CyberInfoButton")
	_validate_entry_point("res://Scenes/Menus/MainMenu.tscn", "MenuPanel/VBox/CyberInfoButton")
	_finish()


func _find_entry(entries: Array[CyberInfoEntry], entry_id: StringName) -> CyberInfoEntry:
	for info_entry in entries:
		if info_entry.entry_id == entry_id:
			return info_entry
	return null


func _validate_authored_cards(
	grid: GridContainer,
	expected_entries: Array[CyberInfoEntry],
	category_name: String
) -> void:
	var authored_ids: Array[StringName] = []
	for child in grid.get_children():
		var card := child as CyberInfoCard
		_expect(card != null, "Every authored %s item is a CyberInfoCard" % category_name)
		if card == null:
			continue
		_expect(card.entry != null, "%s has an editable entry resource" % card.name)
		if card.entry == null:
			continue
		authored_ids.append(card.entry.entry_id)
		var display_image := card.get_node(
			"Margin/Content/ImageAspect/ImageFrame/DisplayImage"
		) as TextureRect
		var name_label := card.get_node("Margin/Content/NameLabel") as Label
		_expect(display_image.texture != null, "%s previews its image in the viewport" % card.name)
		_expect(name_label.text == card.entry.display_name, "%s previews its name in the viewport" % card.name)

	for expected_entry in expected_entries:
		_expect(
			authored_ids.has(expected_entry.entry_id),
			"Authored %s cards include %s" % [category_name, expected_entry.display_name]
		)


func _validate_entry_point(scene_path: String, button_path: NodePath) -> void:
	var scene := load(scene_path) as PackedScene
	_expect(scene != null, "%s loads" % scene_path.get_file())
	if scene == null:
		return
	var instance := scene.instantiate()
	_expect(instance.get_node_or_null(button_path) is Button, "%s exposes Cyber-Info button" % scene_path.get_file())
	_expect(instance.get_node_or_null("CyberInfoHUD") is CyberInfoHUD, "%s includes shared Cyber-Info HUD" % scene_path.get_file())
	instance.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("Cyber-Info validation passed.")
		quit(0)
	else:
		print("Cyber-Info validation failed: ", ", ".join(_failures))
		quit(1)
