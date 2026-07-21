extends SceneTree

const HUNTER_SCENE := preload("res://Scenes/Towers/EDR_Hunter.tscn")
const RED_VIRUS_SCENE := preload("res://Scenes/Enemies/RedVirus.tscn")
const TROJAN_HORSE_SCENE := preload("res://Scenes/Enemies/TrojanHorse.tscn")
const HUNTER_FRAMES_PATH := "res://assets/Towers/EDR_Hunter/EDRHunterSpriteFrames.tres"
const DRONE_FRAMES_PATH := "res://assets/Towers/EDR_Hunter/EDRHunterDroneSpriteFrames.tres"

const EXPECTED_HUNTER_FRAMES := {
	&"idle_lv1": 145, &"aim_lv1": 73, &"shoot_lv1": 73,
	&"idle_lv2": 145, &"aim_lv2": 73, &"shoot_lv2": 73,
	&"idle_lv3": 145, &"aim_lv3": 145, &"shoot_lv3": 73,
	&"idle_lv4": 145, &"aim_lv4": 73, &"shoot_lv4": 73,
	&"idle_lv5": 1, &"aim_lv5": 1, &"shoot_lv5": 1
}


func _init() -> void:
	call_deferred("_validate")


func _validate() -> void:
	var hunter_frames := load(HUNTER_FRAMES_PATH) as SpriteFrames
	assert(hunter_frames != null, "EDR Hunter SpriteFrames did not load.")
	for animation_name in EXPECTED_HUNTER_FRAMES:
		assert(hunter_frames.has_animation(animation_name), "%s is missing." % animation_name)
		assert(
			hunter_frames.get_frame_count(animation_name) == EXPECTED_HUNTER_FRAMES[animation_name],
			"%s has an incorrect frame count." % animation_name
		)

	var drone_frames := load(DRONE_FRAMES_PATH) as SpriteFrames
	assert(drone_frames != null, "EDR Drone SpriteFrames did not load.")
	for animation_name in [&"idle", &"aim", &"shoot"]:
		assert(drone_frames.has_animation(animation_name), "Drone %s is missing." % animation_name)
		assert(drone_frames.get_frame_count(animation_name) == 73, "Drone %s must contain 73 frames." % animation_name)

	var hunter := HUNTER_SCENE.instantiate() as EDRHunterTower
	root.add_child(hunter)
	await process_frame
	assert(hunter.get_level() == 1, "EDR Hunter must start at LV1.")
	assert(not hunter.can_scan_cloaked_viruses(), "EDR Hunter must not detect camouflaged viruses.")
	var cloaked_trojan := TROJAN_HORSE_SCENE.instantiate() as TrojanHorse
	root.add_child(cloaked_trojan)
	await process_frame
	cloaked_trojan.spawn_as_cloaked()
	assert(cloaked_trojan.is_cloaked(), "Trojan Horse camo test setup failed.")
	assert(not cloaked_trojan.can_be_targeted_by(hunter), "EDR Hunter can still target a camouflaged Trojan Horse.")
	_assert_active_level_visual(hunter, 1)

	assert(hunter.upgrade(), "EDR Hunter failed to upgrade to LV2.")
	hunter.play_aim()
	_assert_active_animation(hunter, 2, &"aim_lv2")
	hunter.play_shoot()
	_assert_active_animation(hunter, 2, &"shoot_lv2")

	assert(hunter.upgrade(), "EDR Hunter failed to upgrade to LV3.")
	assert(not hunter.is_drone_unlocked(), "Drone unlocked before LV4.")
	hunter.set("_placed", true)
	assert(hunter.upgrade(), "EDR Hunter failed to upgrade to LV4.")
	assert(hunter.is_drone_unlocked(), "Drone did not unlock at LV4.")
	_assert_active_level_visual(hunter, 4)
	var drone := hunter.get_node("DronePath/DronePathFollow/EDR_Hunter_Drone") as EDRHunterDrone
	assert(drone != null and drone.visible, "LV4 drone is not active.")
	var second_drone := hunter.get_node("DronePath/DronePathFollow2/EDR_Hunter_Drone2") as EDRHunterDrone
	assert(second_drone != null and not second_drone.visible, "Second drone must remain inactive at LV4.")
	assert(hunter.get_active_drone_count() == 1, "LV4 must have exactly one active drone.")
	assert(hunter.get_drone_shot_power() == 1, "Drone damage must be 1.")

	var path_follow := hunter.get_node("DronePath/DronePathFollow") as PathFollow2D
	var initial_progress := path_follow.progress
	await create_timer(0.1).timeout
	assert(path_follow.progress > initial_progress, "Drone did not move along its manual path.")
	var target_path := Path2D.new()
	var target_curve := Curve2D.new()
	target_curve.add_point(Vector2.ZERO)
	target_curve.add_point(Vector2(200.0, 0.0))
	target_path.curve = target_curve
	root.add_child(target_path)
	var target_follow := PathFollow2D.new()
	target_path.add_child(target_follow)
	target_follow.progress = 100.0
	var virus := RED_VIRUS_SCENE.instantiate() as RedVirus
	target_follow.add_child(virus)
	await process_frame
	var active_viruses: Array[PathFollow2D] = [target_follow]
	assert(hunter.update_attack(0.1, active_viruses) == null, "Hunter skipped its aim state.")
	_assert_active_animation(hunter, 4, &"aim_lv4")
	assert(hunter.update_attack(0.3, active_viruses) == target_follow, "Hunter did not fire after aiming.")
	assert(hunter.update_drone_attack(0.0, active_viruses) == target_follow, "Drone did not acquire the virus.")
	hunter.fire_drone_at(virus.global_position)
	var drone_sprite := drone.get_node("VisualPivot/AnimatedSprite2D") as AnimatedSprite2D
	assert(drone_sprite.animation == &"shoot", "Drone shoot animation did not play.")
	assert(hunter.update_drone_attack(0.1, active_viruses) == null, "Drone ignored its one-second cooldown.")

	assert(hunter.upgrade(), "EDR Hunter failed to upgrade to LV5.")
	_assert_active_level_visual(hunter, 5)
	assert(hunter.get_active_drone_count() == 2, "LV5 must have two active drones.")
	assert(drone.visible and second_drone.visible, "Both LV5 drones must be visible.")
	assert(not drone.global_position.is_equal_approx(second_drone.global_position), "LV5 drones must begin in different places around the tower.")
	var first_path_follow := hunter.get_node("DronePath/DronePathFollow") as PathFollow2D
	var second_path_follow := hunter.get_node("DronePath/DronePathFollow2") as PathFollow2D
	var first_progress := first_path_follow.progress
	var second_progress := second_path_follow.progress
	await create_timer(0.1).timeout
	assert(first_path_follow.progress > first_progress, "First LV5 drone did not continue its patrol.")
	assert(second_path_follow.progress > second_progress, "Second LV5 drone did not move on its patrol.")
	var lv5_attacks := hunter.update_drone_attacks(1.0, active_viruses)
	assert(lv5_attacks.size() == 2, "Both LV5 drones must acquire and fire on targets independently.")
	for drone_attack in lv5_attacks:
		hunter.fire_drone_at(virus.global_position, int(drone_attack.get("drone_index", 0)))
	hunter.reset_tower()
	assert(hunter.get_level() == 1, "EDR Hunter reset did not restore LV1.")
	assert(not drone.visible and not second_drone.visible, "A drone remained visible after reset.")

	print("EDR validation passed: LV1-LV5 tracks, one LV4 drone, and two independent LV5 drones.")
	quit()


func _assert_active_level_visual(hunter: EDRHunterTower, expected_level: int) -> void:
	for level in range(1, 6):
		var visual := hunter.get_node("RotatingVisual/LevelVisuals/LV%dVisual" % level) as AnimatedSprite2D
		assert(visual != null, "LV%d visual is missing." % level)
		assert(visual.visible == (level == expected_level), "Incorrect visual active for LV%d." % expected_level)


func _assert_active_animation(hunter: EDRHunterTower, expected_level: int, expected_animation: StringName) -> void:
	_assert_active_level_visual(hunter, expected_level)
	var visual := hunter.get_node("RotatingVisual/LevelVisuals/LV%dVisual" % expected_level) as AnimatedSprite2D
	assert(visual.animation == expected_animation, "Expected %s, found %s." % [expected_animation, visual.animation])
