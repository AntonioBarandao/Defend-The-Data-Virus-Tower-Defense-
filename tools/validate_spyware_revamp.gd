extends SceneTree

const SPYWARE_SCENE := preload("res://Scenes/Enemies/Spyware.tscn")
const TOWER_UPGRADE_HUD_SCENE := preload("res://Scenes/UI/TowerUpgradeHud.tscn")
const WaveManagerScript := preload("res://Scripts/Gameplay/wave_manager.gd")

var _failures: Array[String] = []


class KnowledgeTower:
	extends Node2D

	var placed := true
	var knowledge_source := true

	func is_placed() -> bool:
		return placed

	func is_spyware_knowledge_source() -> bool:
		return knowledge_source


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _validate_scene_tracks()
	await _validate_path_departure()
	await _validate_hijack_lifecycle()
	await _validate_sidebar_lock()
	_validate_wave_registration()
	await _validate_game_integration()

	if _failures.is_empty():
		print("Spyware revamp validation passed.")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _validate_scene_tracks() -> void:
	var spyware := SPYWARE_SCENE.instantiate() as Spyware
	root.add_child(spyware)
	await process_frame

	var expected_tracks := {
		"WalkingVisual": &"walking",
		"AppearVFX": &"vfx_appear",
		"ActiveVFX": &"vfx_active",
		"DisappearVFX": &"vfx_disappear",
	}
	for node_name in expected_tracks:
		var visual := spyware.get_node_or_null(node_name) as AnimatedSprite2D
		var animation_name: StringName = expected_tracks[node_name]
		_expect(
			visual != null
				and visual.get_parent() == spyware
				and visual.sprite_frames != null
				and visual.sprite_frames.has_animation(animation_name)
				and visual.sprite_frames.get_frame_count(animation_name) == 73,
			"Spyware %s is missing its editable 73-frame track." % node_name
		)

	var health_bar := spyware.get_node_or_null("MinibossHealthBar") as SpywareProgressBar
	var progress_bar := spyware.get_node_or_null(
		"MinibossHealthBar/ProgressBar"
	) as ProgressBar
	_expect(
		spyware.max_health == 25
			and health_bar != null
			and progress_bar != null
			and not progress_bar.show_percentage,
		"Spyware does not expose its 25-health black miniboss bar."
	)

	spyware.queue_free()
	await process_frame


func _validate_path_departure() -> void:
	var path := Path2D.new()
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(1000.0, 0.0))
	path.curve = curve
	root.add_child(path)

	var follow := PathFollow2D.new()
	follow.loop = false
	follow.progress = 100.0
	path.add_child(follow)
	var spyware := SPYWARE_SCENE.instantiate() as Spyware
	follow.add_child(spyware)

	var tower := KnowledgeTower.new()
	tower.global_position = Vector2(720.0, 160.0)
	root.add_child(tower)
	await process_frame

	var walking_visual := spyware.get_node(
		"WalkingVisual"
	) as AnimatedSprite2D
	_expect(
		is_equal_approx(walking_visual.rotation, -PI * 0.5),
		"South-facing Spyware did not turn right with the horizontal path."
	)

	spyware.activation_progress_ratio = 0.0
	spyware.invasion_front_offset = Vector2.ZERO
	spyware.path_exit_margin = 24.0
	spyware.path_departure_tolerance = 2.0
	var targets: Array[Node2D] = [tower]
	spyware.update_invasion(0.0, targets)
	var departure_progress := spyware.get_path_departure_progress()
	_expect(
		spyware.is_waiting_for_path_departure()
			and spyware.uses_path_movement()
			and departure_progress > 700.0
			and departure_progress < 740.0,
		"Spyware did not reserve its tower while remaining on the path."
	)

	follow.progress = departure_progress - 4.0
	spyware.update_invasion(0.0, targets)
	_expect(
		spyware.uses_path_movement(),
		"Spyware detached before reaching the path point closest to its tower."
	)

	follow.progress = departure_progress - 1.0
	spyware.update_invasion(0.0, targets)
	_expect(
		not spyware.uses_path_movement()
			and spyware.is_invading_tower()
			and not spyware.is_waiting_for_path_departure(),
		"Spyware did not detach at the path point closest to its tower."
	)

	var distance_before_invasion := spyware.global_position.distance_to(
		tower.global_position
	)
	var expected_invasion_rotation := (
		spyware.global_position.direction_to(tower.global_position).angle()
		- PI * 0.5
	)
	spyware.invasion_walk_speed = 100.0
	spyware.update_invasion(0.5, targets)
	await process_frame
	_expect(
		spyware.global_position.distance_to(follow.global_position) > 40.0
			and spyware.global_position.distance_to(tower.global_position)
				< distance_before_invasion,
		"Detached Spyware snapped back to its PathFollow2D instead of "
			+ "walking directly to the tower."
	)
	_expect(
		is_equal_approx(
			walking_visual.rotation,
			expected_invasion_rotation
		),
		"Spyware did not face its direct tower-invasion movement."
	)

	path.queue_free()
	tower.queue_free()
	await process_frame


func _validate_hijack_lifecycle() -> void:
	var path_follow := PathFollow2D.new()
	root.add_child(path_follow)
	var spyware := SPYWARE_SCENE.instantiate() as Spyware
	path_follow.add_child(spyware)
	var tower := KnowledgeTower.new()
	tower.global_position = Vector2(120.0, 80.0)
	root.add_child(tower)
	tower.set_process(true)
	tower.set_physics_process(true)
	await process_frame

	spyware.activation_progress_ratio = 0.0
	spyware.invasion_front_offset = Vector2(0.0, 78.0)
	spyware.invasion_walk_speed = 10000.0
	spyware.steal_interval_seconds = 1.0
	var drained := [0]
	var hijack_started := [false]
	var hijack_released := [false]
	spyware.knowledge_steal_requested.connect(
		func(_source: Spyware, amount: int) -> void:
			drained[0] += amount
	)
	spyware.hijack_started.connect(
		func(_source: Spyware, _target: Node2D) -> void:
			hijack_started[0] = true
	)
	spyware.hijack_released.connect(
		func(_source: Spyware, _target: Node2D) -> void:
			hijack_released[0] = true
	)

	var targets: Array[Node2D] = [tower]
	var appear_vfx := spyware.get_node_or_null(
		"AppearVFX"
	) as AnimatedSprite2D
	var active_vfx := spyware.get_node_or_null(
		"ActiveVFX"
	) as AnimatedSprite2D
	spyware.update_invasion(0.02, targets)
	_expect(
		bool(hijack_started[0])
			and spyware.has_reached_invasion_target()
			and tower.get_meta("spyware_locked", false)
			and tower.get_meta("spyware_owner", null) == spyware
			and not tower.is_processing(),
		"Spyware did not leave the path and lock its selected knowledge tower."
	)
	_expect(
		appear_vfx != null
			and active_vfx != null
			and appear_vfx.get_parent() == tower
			and active_vfx.get_parent() == tower
			and appear_vfx.global_position.is_equal_approx(
				tower.global_position
			)
			and active_vfx.global_position.is_equal_approx(
				tower.global_position
			)
			and not spyware.global_position.is_equal_approx(
				tower.global_position
			),
		"Spyware hijack square VFX did not attach to the tower center."
	)
	spyware.update_invasion(1.0, targets)
	_expect(
		int(drained[0]) == 1,
		"An attached Spyware did not request exactly one KP after one second."
	)
	_expect(
		spyware.is_high_priority_target() and not spyware.is_low_priority_target(),
		"Attached Spyware did not enter the high-priority targeting tier."
	)

	_expect(spyware.take_damage(25), "Spyware did not die at 25 total damage.")
	_expect(
		bool(hijack_released[0])
			and not tower.get_meta("spyware_locked", false)
			and not tower.has_meta("spyware_owner")
			and tower.is_processing(),
		"Destroyed Spyware left its target tower locked."
	)
	_expect(
		appear_vfx.get_parent() == spyware
			and active_vfx.get_parent() == spyware,
		"Released Spyware did not restore its editable VFX children."
	)

	var second_follow := PathFollow2D.new()
	root.add_child(second_follow)
	var second_spyware := SPYWARE_SCENE.instantiate() as Spyware
	second_follow.add_child(second_spyware)
	await process_frame
	second_spyware.activation_progress_ratio = 0.0
	second_spyware.invasion_front_offset = Vector2(0.0, 78.0)
	second_spyware.invasion_walk_speed = 10000.0
	var second_active_vfx := second_spyware.get_node_or_null(
		"ActiveVFX"
	) as AnimatedSprite2D
	second_spyware.update_invasion(0.02, targets)
	_expect(
		second_spyware.has_reached_invasion_target()
			and second_spyware.get_invasion_target() == tower
			and tower.get_meta("spyware_owner", null) == second_spyware,
		"A later Spyware could not hijack the same released tower again."
	)
	_expect(
		second_active_vfx != null
			and second_active_vfx.get_parent() == tower
			and second_active_vfx.global_position.is_equal_approx(
				tower.global_position
			),
		"Repeated hijack did not reattach the square VFX to the tower."
	)
	second_spyware.take_damage(25)

	path_follow.queue_free()
	second_follow.queue_free()
	tower.queue_free()
	await process_frame


func _validate_sidebar_lock() -> void:
	var hud := TOWER_UPGRADE_HUD_SCENE.instantiate() as TowerUpgradeHUD
	root.add_child(hud)
	await process_frame
	hud.show_siem_panel()
	hud.set_spyware_lock(true)

	var spyware_section := hud.get_node(
		"Root/MenuPanel/Margin/Content/SpywareSection"
	) as Control
	var upgrade_section := hud.get_node(
		"Root/MenuPanel/Margin/Content/VBoxContainer2"
	) as Control
	var sell_button := hud.get_node(
		"Root/MenuPanel/Margin/Content/SellButton"
	) as Button
	_expect(
		spyware_section.visible
			and not upgrade_section.visible
			and not sell_button.visible
			and hud.is_spyware_locked(),
		"Spyware hijack did not replace tower controls with the black lock UI."
	)

	hud.set_spyware_lock(false)
	_expect(
		not spyware_section.visible
			and upgrade_section.visible
			and sell_button.visible,
		"Tower controls did not return after the Spyware lock was released."
	)
	hud.queue_free()
	await process_frame


func _validate_wave_registration() -> void:
	var wave_manager := WaveManagerScript.new()
	var schedule := wave_manager.build_spawn_schedule(16)
	_expect(
		wave_manager.get_leading_virus_name(16, 1) == WaveManagerScript.SPYWARE
			and wave_manager.get_virus_amount(16, WaveManagerScript.SPYWARE) == 1
			and not schedule.is_empty()
			and StringName(schedule[0].get("virus_type", &""))
				== WaveManagerScript.SPYWARE,
		"Wave 16 does not begin with one leading Spyware."
	)


func _validate_game_integration() -> void:
	_expect(
		load("res://Scripts/Gameplay/game.gd") != null,
		"game.gd does not compile with the Spyware integration."
	)
	var normal_scene := load(
		"res://Scenes/Gameplay/Normal_Game.tscn"
	) as PackedScene
	var admin_scene := load(
		"res://Scenes/Gameplay/Admin_Sandbox.tscn"
	) as PackedScene
	_expect(
		normal_scene != null and admin_scene != null,
		"Spyware integration broke a gameplay scene dependency."
	)
	if admin_scene == null:
		return

	var game := admin_scene.instantiate()
	root.add_child(game)
	await process_frame
	game.call("set_current_wave_for_demo", 15)
	game.call("_start_next_wave")
	game.call("_update_wave_spawner", 0.0)
	var spawned_spyware: Spyware
	for follow_value in game.get("_active_viruses") as Array:
		var follow := follow_value as PathFollow2D
		var virus := game.call("_get_red_virus", follow) as RedVirus
		if virus is Spyware:
			spawned_spyware = virus as Spyware
			break
	_expect(
		int(game.call("get_current_wave")) == 16 and spawned_spyware != null,
		"The live Admin Sandbox wave path did not spawn the Wave 16 Spyware leader."
	)

	var lock_probe := Node2D.new()
	lock_probe.set_meta("spyware_locked", true)
	game.add_child(lock_probe)
	_expect(
		bool(game.call("_is_tower_action_locked", lock_probe)),
		"game.gd does not recognize Spyware tower locks as action locks."
	)
	game.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
