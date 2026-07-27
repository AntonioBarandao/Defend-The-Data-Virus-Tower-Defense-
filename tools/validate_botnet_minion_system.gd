extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const BOTNET_MINION_SCENE := preload("res://Scenes/Enemies/BotnetMinion.tscn")
const MUTANT_SCENE := preload("res://Scenes/Enemies/MutantVirus.tscn")
const ANTI_RED_SCENE := preload("res://Scenes/Enemies/AntiChargedRedVirus.tscn")
const ANTI_ARMORED_SCENE := preload(
	"res://Scenes/Enemies/AntiChargedArmoredVirus.tscn"
)
const ANTI_MUTANT_SCENE := preload(
	"res://Scenes/Enemies/AntiChargedMutantVirus.tscn"
)
const ANIMATION_RESOURCES := {
	&"begin": "res://assets/Enemies/BotnetNode/AntiCharge/AntiChargeBeginSpriteFrames.tres",
	&"end": "res://assets/Enemies/BotnetNode/AntiCharge/AntiChargeEndSpriteFrames.tres",
	&"red_transform": "res://assets/Enemies/BotnetNode/AntiCharge/RedVirusAntiTransformSpriteFrames.tres",
	&"armored_transform": "res://assets/Enemies/BotnetNode/AntiCharge/ArmoredVirusAntiTransformSpriteFrames.tres",
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _validate_asset_resources():
		return
	if not await _validate_botnet_profile():
		return
	if not await _validate_game_integration():
		return

	print(
		"Botnet minion validation passed: timed 1/2/3 batches, spaced path "
		+ "scanners, entrance immunity, stationary scan lighting, and "
		+ "Anti-Charged conversion."
	)
	quit(0)


func _validate_asset_resources() -> bool:
	for animation_name in ANIMATION_RESOURCES:
		var frames := load(
			ANIMATION_RESOURCES[animation_name]
		) as SpriteFrames
		if not _require(
			frames != null
				and frames.get_frame_count(
					&"transform"
						if String(animation_name).contains("transform")
						else animation_name
				) == 73,
			"%s does not contain all 73 optimized frames." % animation_name
		):
			return false

	for texture_name in [
		"BotnetMinion.png",
		"BotnetMinionAntiCharged.png",
		"RedVirusAntiCharged.png",
		"ArmoredVirusAntiCharged.png",
		"MutantVirusAntiCharged.png",
	]:
		var texture := load(
			"res://assets/Enemies/BotnetNode/AntiCharge/%s" % texture_name
		) as Texture2D
		var image := texture.get_image() if texture != null else null
		if not _require(
			image != null
				and image.detect_alpha() != Image.ALPHA_NONE
				and image.get_pixel(0, 0).a < 0.05,
			"%s still has an opaque green background." % texture_name
		):
			return false

	var minion := BOTNET_MINION_SCENE.instantiate() as BotnetMinion
	var anti_red := ANTI_RED_SCENE.instantiate() as AntiChargedRedVirus
	var anti_armored := (
		ANTI_ARMORED_SCENE.instantiate() as AntiChargedArmoredVirus
	)
	var anti_mutant := (
		ANTI_MUTANT_SCENE.instantiate() as AntiChargedMutantVirus
	)
	if not _require(
		minion != null
			and anti_red != null
			and anti_armored != null
			and anti_mutant != null
			and anti_red.max_health == 2
			and anti_armored.max_health == 30
			and anti_mutant.max_health == 14,
		"Anti-Charged scenes have incorrect root types or doubled health."
	):
		return false
	minion.free()
	anti_red.free()
	anti_armored.free()
	anti_mutant.free()
	return true


func _validate_botnet_profile() -> bool:
	var scene := load("res://Scenes/Enemies/BotnetNode.tscn") as PackedScene
	var botnet := scene.instantiate() as BotnetNode if scene != null else null
	if not _require(botnet != null, "BotnetNode.tscn could not be instantiated."):
		return false
	root.add_child(botnet)
	await process_frame

	var spawned_positions: Array[Vector2] = []
	var spawned_indices: Array[int] = []
	botnet.minion_spawn_requested.connect(
		func(position: Vector2, index: int) -> void:
			spawned_positions.append(position)
			spawned_indices.append(index)
	)
	if not _require(
		is_equal_approx(botnet.minion_spawn_interval, 20.0)
			and botnet.get_minion_spawn_count(1) == 1
			and botnet.get_minion_spawn_count(2) == 2
			and botnet.get_minion_spawn_count(3) == 3
			and botnet.get_maximum_health() == 25,
		"Botnet spawn cadence, level counts, or boss health is incorrect."
	):
		return false

	for level in range(1, 4):
		var activate_sprite := botnet.get_node(
			"LV%dActivateAnimation" % level
		) as AnimatedSprite2D
		activate_sprite.speed_scale = 120.0

	for level in range(1, 4):
		botnet.set_level(level)
		botnet.activate()
		botnet.set_wave_active(true)
		spawned_positions.clear()
		spawned_indices.clear()
		botnet.update_boss(19.9)
		if not _require(
			spawned_positions.is_empty(),
			"Botnet LV%d spawned before 20 seconds." % level
		):
			return false
		botnet.update_boss(0.1)
		for _frame in range(120):
			await process_frame
			if spawned_positions.size() == level:
				break
		if not _require(
			spawned_positions.size() == level
				and spawned_indices.size() == level
				and _positions_are_unique(spawned_positions),
			"Botnet LV%d did not emit %d distinct marker spawns." % [
				level,
				level,
			]
		):
			return false
		botnet.set_wave_active(false)

	for level in [1, 2]:
		botnet.set_level(level)
		botnet.activate()
		var health_before := botnet.get_current_health()
		if not _require(
			not botnet.can_be_targeted()
				and not botnet.take_damage(health_before)
				and botnet.get_current_health() == health_before,
			"Botnet LV%d accepted damage before its LV3 combat unlock." % level
		):
			return false

	botnet.set_level(3)
	botnet.activate()
	if not _require(
		botnet.can_be_targeted()
			and not botnet.take_damage(24)
			and botnet.get_current_health() == 1
			and botnet.take_damage(1)
			and botnet.is_defeated(),
		"Botnet LV3 did not unlock and deplete from its 25-health profile."
	):
		return false
	botnet.queue_free()
	await process_frame
	return true


func _validate_game_integration() -> bool:
	var game := NORMAL_GAME.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var cutscene := game.get_node_or_null("TextCutsceneHUD") as TextCutsceneHUD
	if cutscene != null and cutscene.is_cutscene_running():
		cutscene.skip_cutscene()
		await process_frame

	game.call("_unlock_extended_waves")
	game.call("set_current_wave_for_demo", 20)
	game.call("_start_next_wave")
	await process_frame
	var botnet := game.get_node_or_null("BotnetNode") as BotnetNode
	var botnet_target := game.get_node_or_null(
		"BotnetNodeCombatTarget"
	) as PathFollow2D
	if not _require(
		botnet != null
			and botnet_target != null
			and botnet.active
			and botnet.get_level() == 1
			and bool(game.get("_wave_in_progress")),
		"Wave 21 did not activate the Botnet combat profile."
	):
		return false

	var low_priority_targets: Array = game.call(
		"_get_botnet_low_priority_attack_targets"
	)
	var standard_targets: Array = game.call("_get_offensive_attack_targets")
	if not _require(
		low_priority_targets.is_empty()
			and not standard_targets.has(botnet_target),
		"Botnet LV1 was exposed as an attack target."
	):
		return false

	botnet.set_level(3)
	botnet.activate()
	low_priority_targets = game.call("_get_botnet_low_priority_attack_targets")
	if not _require(
		low_priority_targets == [botnet_target],
		"Botnet LV3 did not unlock as a low-priority attack target."
	):
		return false

	var markers := botnet.get_node("PossibleSpawnMarkers2").get_children()
	var spawned_follows: Array[PathFollow2D] = []
	for index in range(3):
		var marker := markers[index] as Marker2D
		var follow := game.call(
			"_spawn_botnet_minion",
			marker.global_position,
			index
		) as PathFollow2D
		spawned_follows.append(follow)
	if not _require(
		_have_spaced_path_progress(spawned_follows, 63.9),
		"Botnet minions were assigned stacking path positions."
	):
		return false
	for follow in spawned_follows:
		var minion := game.call("_get_red_virus", follow) as BotnetMinion
		if not _require(
			minion != null
				and minion.is_entering_path()
				and not minion.has_reached_path()
				and not minion.can_be_targeted()
				and not minion.can_apply_anti_charge()
				and not minion.get_scan_spotlight().visible
				and minion.max_health == 1,
			"A Botnet minion did not begin its non-targetable path entrance."
		):
			return false

	var source_follow := spawned_follows[0]
	var source_minion := game.call(
		"_get_red_virus",
		source_follow
	) as BotnetMinion
	standard_targets = game.call("_get_offensive_attack_targets")
	if not _require(
		not standard_targets.has(source_follow)
			and not bool(game.call("_damage_virus", source_follow, 1, false))
			and source_minion.current_health == 1,
		"A flying Botnet scanner could be targeted or damaged before landing."
	):
		return false

	Engine.time_scale = 24.0
	for _frame in range(30):
		await process_frame
		var all_settled := true
		for follow in spawned_follows:
			var minion := game.call("_get_red_virus", follow) as BotnetMinion
			if minion == null or not minion.has_reached_path():
				all_settled = false
				break
		if all_settled:
			break
	Engine.time_scale = 1.0

	standard_targets = game.call("_get_offensive_attack_targets")
	for follow in spawned_follows:
		var minion := game.call("_get_red_virus", follow) as BotnetMinion
		var spotlight := minion.get_scan_spotlight()
		var expected_anchor := follow.global_position
		if not _require(
			minion.has_reached_path()
				and not minion.is_entering_path()
				and minion.can_be_targeted()
				and minion.can_apply_anti_charge()
				and not minion.uses_path_movement()
				and standard_targets.has(follow)
				and minion.global_position.is_equal_approx(
					expected_anchor + Vector2(0, -50)
				)
				and spotlight != null
				and spotlight.visible
				and spotlight.global_position.is_equal_approx(expected_anchor)
				and is_equal_approx(spotlight.modulate.a, 0.5)
				and spotlight.get_node_or_null("OuterGlow") is Polygon2D
				and spotlight.get_node_or_null("ScanRing") is Line2D,
			"A landed Botnet scanner is not stationary, elevated, lit, or targetable."
		):
			return false

	var stationary_progress := source_follow.progress
	await process_frame
	await process_frame
	if not _require(
		is_equal_approx(source_follow.progress, stationary_progress),
		"A landed Botnet scanner resumed normal virus path movement."
	):
		return false

	game.call("_spawn_virus", source_follow.progress, false)
	var active_viruses: Array = game.get("_active_viruses")
	var red_follow := active_viruses.back() as PathFollow2D
	var red_virus := game.call("_get_red_virus", red_follow) as RedVirus
	game.call("_update_botnet_minion_contacts")
	await process_frame
	await process_frame
	if not _require(
		source_minion.is_anti_charged()
			and red_virus.is_external_transformation_active()
			and not red_virus.visible,
		"Botnet contact did not freeze Red Virus and begin Anti-Charge."
	):
		return false

	Engine.time_scale = 24.0
	for _frame in range(90):
		await process_frame
		var current_virus := game.call(
			"_get_red_virus",
			red_follow
		) as RedVirus
		if current_virus is AntiChargedRedVirus:
			break
	Engine.time_scale = 1.0
	var charged_red := game.call(
		"_get_red_virus",
		red_follow
	) as AntiChargedRedVirus
	if not _require(
		charged_red != null
			and charged_red.max_health == 2
			and charged_red.current_health == 2,
		"Red Virus was not replaced by its double-health Anti-Charged scene."
	):
		return false

	if not _require(
		bool(game.call("_damage_virus", red_follow, 2, false)),
		"Anti-Charged Red Virus did not die after two damage."
	):
		return false
	var star_effect := game.get_node_or_null(
		"AntiChargedDestroyEffect"
	) as AntiChargedDestroyEffect
	if not _require(
		star_effect != null
			and star_effect.get_child_count() == 11
			and star_effect.get_child(0) is Polygon2D,
		"Anti-Charged death did not create the red-star effect."
	):
		return false

	var mutant_minion_follow := spawned_follows[1]
	var mutant_minion := game.call(
		"_get_red_virus",
		mutant_minion_follow
	) as BotnetMinion
	game.call(
		"_spawn_evolved_virus",
		MUTANT_SCENE,
		"MutantVirus",
		Vector2(0.11, 0.11)
	)
	active_viruses = game.get("_active_viruses")
	var mutant_follow := active_viruses.back() as PathFollow2D
	var mutant := game.call("_get_red_virus", mutant_follow) as RedVirus
	mutant_follow.progress = mutant_minion_follow.progress
	mutant.global_position = mutant_minion.get_scan_origin_global_position()
	game.call("_update_botnet_minion_contacts")
	await process_frame
	await process_frame
	if not _require(
		mutant_minion.is_anti_charged()
			and mutant.is_external_transformation_active(),
		"Botnet contact did not begin Mutant Virus Anti-Charge."
	):
		return false

	Engine.time_scale = 24.0
	for _frame in range(60):
		await process_frame
		var current_mutant := game.call(
			"_get_red_virus",
			mutant_follow
		) as RedVirus
		if current_mutant is AntiChargedMutantVirus \
				and not mutant_follow.has_meta("anti_charge_transform_pending"):
			break
	Engine.time_scale = 1.0
	var charged_mutant := game.call(
		"_get_red_virus",
		mutant_follow
	) as AntiChargedMutantVirus
	if not _require(
		charged_mutant != null
			and charged_mutant.max_health == 14
			and charged_mutant.current_health == 14
			and not mutant_follow.has_meta("anti_charge_transform_pending"),
		"Mutant Virus was not replaced by its double-health Anti-Charged scene."
	):
		return false

	game.queue_free()
	await process_frame
	return true


func _positions_are_unique(positions: Array[Vector2]) -> bool:
	var occupied := {}
	for position in positions:
		var key := Vector2i(roundi(position.x), roundi(position.y))
		if occupied.has(key):
			return false
		occupied[key] = true
	return true


func _have_spaced_path_progress(
	follows: Array[PathFollow2D],
	minimum_spacing: float
) -> bool:
	for left_index in range(follows.size()):
		for right_index in range(left_index + 1, follows.size()):
			if absf(
				follows[left_index].progress - follows[right_index].progress
			) < minimum_spacing:
				return false
	return true


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	Engine.time_scale = 1.0
	push_error(message)
	quit(1)
	return false
