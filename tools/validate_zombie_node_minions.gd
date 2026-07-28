extends SceneTree


func _initialize() -> void:
	var scene := load("res://Scenes/Gameplay/Normal_Game.tscn") as PackedScene
	if not _require(scene != null, "Normal Game could not be loaded."):
		return

	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame

	var cutscene := game.get_node_or_null("TextCutsceneHUD") as TextCutsceneHUD
	if cutscene != null and cutscene.is_cutscene_running():
		cutscene.skip_cutscene()
		await process_frame

	var zombie := game.get_node_or_null("ZombieNode") as ZombieNode
	var director := game.get_node_or_null("CutsceneDemoDirector") as CutsceneDemoDirector
	if not _require(zombie != null and director != null, "Zombie Node runtime nodes are missing."):
		return

	var minion_scene := load("res://Scenes/Enemies/ZombieNodeMinion.tscn") as PackedScene
	var mutation_scene := load("res://Scenes/Enemies/RedMutantTransform.tscn") as PackedScene
	if not _require(minion_scene != null and mutation_scene != null, "Zombie minion or mutation scene could not be loaded."):
		return

	var minion_preview := minion_scene.instantiate() as ZombieNodeMinion
	var mutation_preview := mutation_scene.instantiate() as AnimatedSprite2D
	if not _require(minion_preview != null and mutation_preview != null, "Zombie minion scenes instantiate with the wrong root type."):
		return
	if not _require(minion_preview.sprite_frames.get_animation_names().size() == 9, "The minion scene does not expose all nine visual variants."):
		return
	if not _require(
		mutation_preview.sprite_frames.get_frame_count(&"transform") == 73,
		"The red-to-mutant transition does not contain all 73 frames."
	):
		return
	minion_preview.free()
	mutation_preview.free()

	if not _require(is_equal_approx(zombie.minion_spawn_interval, 20.0), "Zombie minions are not configured for a 20-second interval."):
		return
	var idle_nodes: Array[AnimatedSprite2D] = [
		zombie.get_node_or_null("LV1IdleAnimation") as AnimatedSprite2D,
		zombie.get_node_or_null("LV2IdleAnimation") as AnimatedSprite2D,
		zombie.get_node_or_null("LV3IdleAnimation") as AnimatedSprite2D,
	]
	var activation_nodes: Array[AnimatedSprite2D] = [
		zombie.get_node_or_null("LV1ActivateAnimation") as AnimatedSprite2D,
		zombie.get_node_or_null("LV2ActivateAnimation") as AnimatedSprite2D,
		zombie.get_node_or_null("LV3ActivateAnimation") as AnimatedSprite2D,
	]
	var idle_names: Array[StringName] = [
		&"idle_lv1",
		&"idle_lv2",
		&"idle_lv3",
	]
	var activation_names: Array[StringName] = [
		&"activate_lv1",
		&"activate_lv2",
		&"activate_lv3",
	]
	var expected_idle_frames: Array[int] = [73, 73, 73]
	var expected_activation_frames: Array[int] = [145, 73, 145]
	for index in range(3):
		var idle := idle_nodes[index]
		var activation := activation_nodes[index]
		if not _require(
			idle != null
				and activation != null
				and idle.get_parent() == zombie
				and activation.get_parent() == zombie
				and idle.sprite_frames.get_frame_count(
					idle_names[index]
				) == expected_idle_frames[index]
				and activation.sprite_frames.get_frame_count(
					activation_names[index]
				) == expected_activation_frames[index]
				and idle.sprite_frames.get_animation_loop(
					idle_names[index]
				)
				and not activation.sprite_frames.get_animation_loop(
					activation_names[index]
				),
			"Zombie Node stage %d does not expose valid sibling idle/activate tracks." % (index + 1)
		):
			return
	if not _require(
		is_equal_approx(zombie.ability_activation_lead_seconds, 2.0),
		"Zombie Node abilities are not configured with a two-second activation lead."
	):
		return
	for level in [1, 4, 5]:
		zombie.set_level(level)
		var activation_duration := zombie.get_minion_activation_duration()
		var trigger_delay := zombie.get_minion_spawn_trigger_delay()
		if not _require(
			is_equal_approx(activation_duration, 2.0)
				and is_equal_approx(
					trigger_delay + activation_duration,
					zombie.get_current_minion_spawn_interval()
				),
			"Zombie Node level %d is not activating two seconds before its ability." % level
		):
			return
	if not _require(
		zombie.get_minion_spawn_count(1) == 5
			and zombie.get_minion_spawn_count(4) == 8
			and zombie.get_minion_spawn_count(5) == 17,
		"Zombie Node level spawn counts are incorrect."
	):
		return
	if not _require(
		int(director.call("_get_zombie_level_for_wave", 13)) == 4
			and int(director.call("_get_zombie_level_for_wave", 15)) == 5,
		"Zombie Node LV4/LV5 wave progression is unavailable."
	):
		return

	game.call("set_current_wave_for_demo", 11)
	game.set("_wave_in_progress", true)
	game.set("_wave_spawns_remaining", 0)
	zombie.set_wave_active(true)
	var spawned_count := zombie.request_minion_batch()
	if not _require(spawned_count == 5, "LV1 did not request five Zombie Node minions."):
		return

	var active_viruses: Array = game.get("_active_viruses")
	var minion_follows := _get_minion_follows(game, active_viruses)
	if not _require(minion_follows.size() == 5, "The game did not register all five minions as live viruses."):
		return
	if not _require(_have_unique_minion_positions(game, minion_follows), "Two minions spawned on the same authored marker."):
		return
	if not _require(_have_spaced_path_progress(minion_follows, 55.9), "Two minions were assigned stacking path positions."):
		return

	for follow in minion_follows:
		var minion := game.call("_get_red_virus", follow) as ZombieNodeMinion
		if not _require(
			minion != null
				and minion.max_health == 1
				and is_equal_approx(minion.get_path_speed(), 180.0)
				and minion.is_entering_path(),
			"A spawned minion has incorrect health, speed, or path-entry state."
		):
			return

	game.call("_update_wave_spawner", 0.0)
	if not _require(bool(game.get("_wave_in_progress")), "The wave ended while Zombie Node minions were alive."):
		return

	var before_timed_batch := active_viruses.size()
	zombie.ability_activation_lead_seconds = 0.05
	zombie.call("_process", zombie.minion_spawn_interval)
	active_viruses = game.get("_active_viruses")
	if not _require(
		zombie.is_minion_spawn_pending()
			and activation_nodes[0].visible
			and not idle_nodes[0].visible
			and active_viruses.size() == before_timed_batch,
		"The LV1 timer spawned minions before its activation animation finished."
	):
		return
	for _frame in range(30):
		await process_frame
		if not zombie.is_minion_spawn_pending():
			break
	active_viruses = game.get("_active_viruses")
	if not _require(
		not zombie.is_minion_spawn_pending()
			and not activation_nodes[0].visible
			and idle_nodes[0].visible
			and active_viruses.size() == before_timed_batch + 5,
		"The LV1 activation animation did not spawn five minions after playback."
	):
		return
	zombie.ability_activation_lead_seconds = 2.0

	for _frame in range(130):
		await process_frame

	active_viruses = game.get("_active_viruses")
	minion_follows = _get_minion_follows(game, active_viruses)
	if not _require(not minion_follows.is_empty(), "All minions disappeared before path-entry validation."):
		return
	var mutation_source_follow := minion_follows[0] as PathFollow2D
	var mutation_source := game.call("_get_red_virus", mutation_source_follow) as ZombieNodeMinion
	if not _require(mutation_source != null and not mutation_source.is_entering_path(), "A minion never completed its curved path entry."):
		return

	game.call("_spawn_virus", mutation_source_follow.progress, false)
	active_viruses = game.get("_active_viruses")
	var red_follow := active_viruses[active_viruses.size() - 1] as PathFollow2D
	var red_virus := game.call("_get_red_virus", red_follow) as RedVirus
	if not _require(red_virus != null and red_virus.get_script() == preload("res://Scripts/Enemies/red_virus.gd"), "A plain red virus was not created for mutation."):
		return

	game.call("_update_zombie_minion_contacts")
	await process_frame
	await process_frame
	if not _require(
		red_virus.is_external_transformation_active()
			and not red_virus.visible
			and not red_virus.uses_path_movement(),
		"The contacted red virus did not freeze during its mutation."
	):
		return

	for _frame in range(210):
		await process_frame
		var transformed := game.call("_get_red_virus", red_follow) as RedVirus
		if transformed != null and transformed.get_script() != preload("res://Scripts/Enemies/red_virus.gd"):
			break

	var mutant := game.call("_get_red_virus", red_follow) as RedVirus
	if not _require(
		mutant != null
			and mutant.name == "SpawnedMutantVirus"
			and mutant.max_health == 7,
		"The mutation animation did not replace the red virus with MutantVirus.tscn."
	):
		return

	var destroy_follow := minion_follows[1] as PathFollow2D
	if not _require(bool(game.call("_damage_virus", destroy_follow, 1, false)), "A one-health minion did not die from one damage."):
		return
	var destroy_effect := game.get_node_or_null("ZombieMinionDestroyEffect") as ZombieMinionDestroyEffect
	if not _require(destroy_effect != null, "The green line-only minion destruction effect was not created."):
		return
	for child in destroy_effect.get_children():
		if not _require(child is Line2D, "The minion destruction effect contains a non-line visual."):
			return

	for stage_data in [[4, 1, 8], [5, 2, 17]]:
		var level: int = stage_data[0]
		var visual_index: int = stage_data[1]
		var expected_count: int = stage_data[2]
		zombie.set_wave_active(false)
		zombie.set_level(level)
		zombie.ability_activation_lead_seconds = 0.05
		zombie.set_wave_active(true)
		active_viruses = game.get("_active_viruses")
		var before_stage_batch := active_viruses.size()
		zombie.call(
			"_process",
			zombie.get_current_minion_spawn_interval()
		)
		if not _require(
			zombie.is_minion_spawn_pending()
				and activation_nodes[visual_index].visible
				and not idle_nodes[visual_index].visible,
			"Zombie Node level %d did not switch to its activation sibling." % level
		):
			return
		for _frame in range(30):
			await process_frame
			if not zombie.is_minion_spawn_pending():
				break
		active_viruses = game.get("_active_viruses")
		if not _require(
			not zombie.is_minion_spawn_pending()
				and not activation_nodes[visual_index].visible
				and idle_nodes[visual_index].visible
				and active_viruses.size()
					== before_stage_batch + expected_count,
			"Zombie Node level %d did not spawn its batch after activation." % level
		):
			return
	zombie.set_wave_active(false)
	zombie.ability_activation_lead_seconds = 2.0

	game.free()
	print("Zombie Node minion validation passed: all stage activations, spawning, path entry, wave hold, mutation, and green destruction lines.")
	quit(0)


func _get_minion_follows(game: Node, active_viruses: Array) -> Array[PathFollow2D]:
	var result: Array[PathFollow2D] = []
	for follow_value in active_viruses:
		var follow := follow_value as PathFollow2D
		if follow == null:
			continue
		if game.call("_get_red_virus", follow) is ZombieNodeMinion:
			result.append(follow)
	return result


func _have_unique_minion_positions(game: Node, follows: Array[PathFollow2D]) -> bool:
	var positions := {}
	for follow in follows:
		var minion := game.call("_get_red_virus", follow) as ZombieNodeMinion
		if minion == null:
			return false
		var key := Vector2i(roundi(minion.global_position.x * 10.0), roundi(minion.global_position.y * 10.0))
		if positions.has(key):
			return false
		positions[key] = true
	return true


func _have_spaced_path_progress(follows: Array[PathFollow2D], minimum_spacing: float) -> bool:
	for left_index in range(follows.size()):
		for right_index in range(left_index + 1, follows.size()):
			if absf(follows[left_index].progress - follows[right_index].progress) < minimum_spacing:
				return false
	return true


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
