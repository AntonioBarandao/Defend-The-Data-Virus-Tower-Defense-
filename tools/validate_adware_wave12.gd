extends SceneTree

const ADWARE_SCENE := preload("res://Scenes/Enemies/Adware.tscn")
const ADMIN_SANDBOX := preload("res://Scenes/Gameplay/Admin_Sandbox.tscn")
const WaveManagerScript := preload("res://Scripts/Gameplay/wave_manager.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var wave_manager := WaveManagerScript.new()
	var schedule := wave_manager.build_spawn_schedule(12)
	if not _require(
		wave_manager.get_leading_virus_name(12, 1)
				== WaveManagerScript.ADWARE
			and wave_manager.get_virus_amount(
				12,
				WaveManagerScript.ADWARE
			) == 1
			and wave_manager.get_total_pathway_virus_count(12) == 27
			and not schedule.is_empty()
			and StringName(schedule[0].get("virus_type", &""))
				== WaveManagerScript.ADWARE,
		"Wave 12 does not begin with exactly one leading Adware."
	):
		return

	var adware := ADWARE_SCENE.instantiate() as Adware
	root.add_child(adware)
	await process_frame
	var authored_popup := adware.get_node_or_null(
		"Popups/Popup01"
	) as Sprite2D
	var authored_close_button := adware.get_node_or_null(
		"Popups/RedButtonCollision"
	) as Area2D
	var expected_close_button_transform := Transform2D.IDENTITY
	if authored_popup != null and authored_close_button != null:
		expected_close_button_transform = (
			authored_popup.global_transform.affine_inverse()
			* authored_close_button.global_transform
		)
	adware.process_mode = Node.PROCESS_MODE_DISABLED
	adware.reset_for_spawn()
	adware.lifespan_seconds = 0.0
	adware.max_active_popups = 5
	adware.damage_flash_duration = 0.01
	adware.popup_shield_flash_duration = 0.01

	var first_tower := Node2D.new()
	first_tower.name = "FirstDeployedTower"
	first_tower.global_position = Vector2(300, 220)
	root.add_child(first_tower)
	var second_tower := Node2D.new()
	second_tower.name = "SecondDeployedTower"
	second_tower.global_position = Vector2(760, 420)
	root.add_child(second_tower)

	adware.start_popup_cycle(
		[0, 1, 2, 3, 4, 5],
		4.0,
		[first_tower, second_tower]
	)
	adware.call("_update_popup_burst", 0.0)
	var anchors := adware.get("_popup_anchors") as Dictionary
	if not _require(
		adware.get_active_popup_count() == 1
			and anchors.size() == 1,
		"Adware did not create one initial popup on a deployed tower."
	):
		return

	adware.call("_update_popup_burst", 3.99)
	if not _require(
		adware.get_active_popup_count() == 1,
		"Adware created another popup before the four-second interval."
	):
		return
	adware.call("_update_popup_burst", 0.02)
	anchors = adware.get("_popup_anchors") as Dictionary
	if not _require(
		adware.get_active_popup_count() == 2
			and anchors.values().has(first_tower)
			and anchors.values().has(second_tower),
		"Adware did not select another available deployed tower."
	):
		return

	var shielded_health := adware.current_health
	if not _require(
		not adware.take_damage(5)
			and adware.current_health == shielded_health
			and adware.get("_hit_flash_tween") != null,
		"An active popup did not shield Adware with a white hit response."
	):
		return

	for _cycle in range(6):
		adware.call("_update_popup_burst", 4.0)
	if not _require(
		adware.get_active_popup_count() == 5,
		"Adware exceeded or failed to reach its five-popup maximum."
	):
		return

	var active_indices := (
		adware.get("_active_popup_indices") as Array
	).duplicate()
	var close_test_index := int(active_indices[0])
	var popup_buttons := adware.get("_popup_buttons") as Dictionary
	var runtime_close_button := popup_buttons.get(
		close_test_index
	) as Area2D
	var runtime_close_shape := (
		runtime_close_button.get_node_or_null("CollisionShape2D")
			as CollisionShape2D
		if runtime_close_button != null
		else null
	)
	if not _require(
		authored_popup != null
			and authored_close_button != null
			and runtime_close_button != null
			and runtime_close_shape != null
			and runtime_close_shape.shape != null
			and runtime_close_button.input_pickable
			and runtime_close_button.transform.is_equal_approx(
				expected_close_button_transform
			)
			and adware.try_press_popup_close_at(
				runtime_close_shape.global_position
			),
		"The runtime Adware close hitbox did not preserve or respond at its "
			+ "viewport-authored transform."
	):
		return
	for popup_index in active_indices:
		adware.call("_finalize_popup_hidden", int(popup_index))
	if not _require(
		not adware.has_active_popups()
			and not adware.take_damage(1)
			and adware.current_health == shielded_health - 1
			and adware.get("_hit_flash_tween") != null,
		"Adware did not become vulnerable with a red flash after its ads closed."
	):
		return

	adware.call("_hide_all_popups")
	adware.call("_stop_hit_flash")
	await process_frame
	await process_frame
	adware.free()
	first_tower.free()
	second_tower.free()

	var game := ADMIN_SANDBOX.instantiate()
	root.add_child(game)
	await process_frame
	game.call("set_current_wave_for_demo", 11)
	game.call("_start_next_wave")
	game.call("_update_wave_spawner", 0.0)
	var active_viruses := game.get("_active_viruses") as Array
	var spawned_adware: Adware
	for follow_value in active_viruses:
		var follow := follow_value as PathFollow2D
		var virus := game.call("_get_red_virus", follow) as RedVirus
		if virus is Adware:
			spawned_adware = virus as Adware
			break
	if not _require(
		int(game.call("get_current_wave")) == 12
			and spawned_adware != null
			and is_equal_approx(
				spawned_adware.popup_interval_seconds,
				4.0
			)
			and bool(spawned_adware.get("_popup_cycle_running")),
		"The live Admin Sandbox Wave 12 path did not spawn cycling Adware."
	):
		return
	spawned_adware.call("_update_popup_burst", 0.0)
	var live_active_indices := (
		spawned_adware.get("_active_popup_indices") as Array
	)
	var live_close_button: Area2D
	if not live_active_indices.is_empty():
		live_close_button = (
			spawned_adware.get("_popup_buttons") as Dictionary
		).get(int(live_active_indices[0])) as Area2D
	if not _require(
		live_close_button != null
			and bool(
				game.call(
					"_handle_adware_popup_press",
					live_close_button.global_position
				)
			),
		"The live game input route did not activate the Adware popup close "
			+ "hitbox."
	):
		return
	game.queue_free()
	await process_frame
	await process_frame

	print(
		"Adware Wave 12 validation passed: leader spawn, four-second tower "
		+ "popups, authored close-button hitboxes, five-ad cap, popup shield, "
		+ "damage flash, and live game input."
	)
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
