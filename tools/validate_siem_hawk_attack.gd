extends SceneTree

const SIEM_HAWK := preload("res://Scenes/Towers/SIEM_Hawk.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hawk := SIEM_HAWK.instantiate() as SIEMHawkTower
	root.add_child(hawk)
	await process_frame
	hawk.global_position = Vector2(600, 400)
	hawk.set("_station_position", hawk.global_position)
	hawk.set("_placed", true)
	hawk.set_dispatched(true)
	hawk.global_position = Vector2(600, 280)

	var inside_target := PathFollow2D.new()
	inside_target.name = "InsideScanArc"
	root.add_child(inside_target)
	var outside_target := PathFollow2D.new()
	outside_target.name = "OutsideScanArc"
	root.add_child(outside_target)
	var scan_origin := hawk.call(
		"_get_scan_origin_global_position"
	) as Vector2
	inside_target.global_position = scan_origin + Vector2(0, 120)
	outside_target.global_position = scan_origin + Vector2(120, 0)
	var inside_targets: Array[PathFollow2D] = [inside_target]
	var outside_targets: Array[PathFollow2D] = [outside_target]

	hawk.set_dispatch_destination(hawk.global_position + Vector2(120, 0))
	hawk.level = 2
	hawk.set("_shot_cooldown_remaining", 0.0)
	var travel_rotation := hawk.global_rotation
	_check(
		hawk.is_scan_attack_enabled()
			and not hawk.is_stationary_scan_attack_enabled()
			and hawk.update_attack(10.0, inside_targets) == inside_target,
		"The Hawk attacks scanned targets while traveling to a destination."
	)
	hawk.aim_at(inside_target.global_position)
	_check(
		is_equal_approx(hawk.global_rotation, travel_rotation),
		"Attacking while traveling preserves the destination-facing rotation."
	)
	hawk.call("_clear_dispatch_destination")

	var remembered_follow := PathFollow2D.new()
	remembered_follow.name = "RememberedScanTarget"
	root.add_child(remembered_follow)
	var remembered_virus := RedVirus.new()
	remembered_follow.add_child(remembered_virus)
	remembered_virus.global_position = outside_target.global_position
	var scanned_virus_ids := hawk.get("_scanned_virus_ids") as Dictionary
	scanned_virus_ids[remembered_virus.get_instance_id()] = true
	hawk.set("_scanned_virus_ids", scanned_virus_ids)
	hawk.set("_shot_cooldown_remaining", 0.0)
	var remembered_targets: Array[PathFollow2D] = [remembered_follow]
	_check(
		hawk.update_attack(0.0, remembered_targets) == remembered_follow,
		"A previously scanned virus remains targetable inside the scanner radius."
	)

	hawk.level = 1
	hawk.call("_sync_level_visuals", true)
	_check(
		hawk.update_attack(10.0, inside_targets) == null,
		"LV1 cannot attack a virus inside its scan arc."
	)
	_check(hawk.get_shot_power() == 0, "LV1 reports zero attack damage.")

	var expected_cooldowns := {
		2: 1.0,
		3: 0.5,
		4: 0.2,
		5: 0.05,
	}
	for level_number in range(2, 6):
		hawk.call("_set_attack_visual_active", false)
		hawk.level = level_number
		hawk.set("_shot_cooldown_remaining", 0.0)
		hawk.call("_sync_level_visuals", true)
		var attack_visual := hawk.get_node_or_null(
			"LV%dAttackVisual" % level_number
		) as AnimatedSprite2D
		var idle_visual := hawk.get_node_or_null(
			"LevelVisuals/LV%dVisual" % level_number
		) as AnimatedSprite2D
		var animation_name := StringName("attack_lv%d" % level_number)
		_check(
			attack_visual != null
				and attack_visual.get_parent() == hawk
				and attack_visual.sprite_frames != null
				and attack_visual.sprite_frames.has_animation(animation_name)
				and attack_visual.sprite_frames.get_frame_count(
					animation_name
				) > 0
				and attack_visual.sprite_frames.get_animation_loop(
					animation_name
				),
			"LV%d has an independent looping attack sibling."
				% level_number
		)
		_check(
			hawk.get_shot_power() == 1,
			"LV%d deals one damage per shot." % level_number
		)
		_check(
			is_equal_approx(
				hawk.get_shot_cooldown(),
				float(expected_cooldowns[level_number])
			),
			"LV%d uses a %.2f-second attack cooldown."
				% [level_number, expected_cooldowns[level_number]]
		)
		_check(
			hawk.update_attack(0.0, outside_targets) == null,
			"LV%d ignores a virus outside the scan arc." % level_number
		)
		var target := hawk.update_attack(0.0, inside_targets)
		_check(
			target == inside_target,
			"LV%d acquires a virus inside the scan arc." % level_number
		)
		_check(
			attack_visual != null
				and attack_visual.visible
				and attack_visual.is_playing()
				and idle_visual != null
				and not idle_visual.visible,
			"LV%d switches from its idle sibling to its attack sibling."
				% level_number
		)
		var cooldown := float(expected_cooldowns[level_number])
		_check(
			hawk.update_attack(cooldown * 0.5, inside_targets) == null,
			"LV%d waits for its cooldown before the next shot."
				% level_number
		)
		_check(
			hawk.update_attack(cooldown * 0.5 + 0.001, inside_targets)
				== inside_target,
			"LV%d attacks again when its cooldown elapses."
				% level_number
		)
		var no_targets: Array[PathFollow2D] = []
		hawk.update_attack(0.0, no_targets)
		_check(
			attack_visual != null
				and not attack_visual.visible
				and idle_visual != null
				and idle_visual.visible,
			"LV%d returns to its idle sibling when the scan arc is clear."
				% level_number
		)

	hawk.level = 5
	hawk.set("_shot_cooldown_remaining", 0.0)
	hawk.set_dispatched(false)
	_check(
		hawk.is_stationary_scan_attack_enabled()
			and hawk.has_attack_target_in_scan(inside_targets)
			and hawk.update_attack(1.0, inside_targets) == inside_target,
		"The airborne Hawk continues attacking while frozen."
	)
	hawk.global_position = hawk.get_headquarters_position()
	hawk.set("_shot_cooldown_remaining", 0.0)
	_check(
		not hawk.is_scan_attack_enabled()
			and not hawk.is_stationary_scan_attack_enabled()
			and hawk.update_attack(1.0, inside_targets) == null,
		"The Hawk cannot attack after landing on headquarters."
	)

	hawk.reset_tower()
	for level_number in range(2, 6):
		var attack_visual := hawk.get_node_or_null(
			"LV%dAttackVisual" % level_number
		) as AnimatedSprite2D
		if attack_visual != null:
			attack_visual.stop()
			attack_visual.sprite_frames = null
	await process_frame
	hawk.queue_free()
	inside_target.queue_free()
	outside_target.queue_free()
	remembered_follow.queue_free()
	for _frame in range(30):
		await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print(
			"SIEM Hawk attack validation passed: LV2-LV5 tracks, "
			+ "destination/freeze targeting, damage, and cooldowns."
		)
		quit(0)
	else:
		quit(1)
