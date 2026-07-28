extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const EDR_HUNTER := preload("res://Scenes/Towers/EDR_Hunter.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := NORMAL_GAME.instantiate()
	root.add_child(game)
	await process_frame

	var cutscene := game.get_node_or_null("TextCutsceneHUD") as TextCutsceneHUD
	if cutscene != null and cutscene.is_cutscene_running():
		cutscene.skip_cutscene()
		await process_frame
	game.set_process(false)

	var authored_edr := game.get_node_or_null("Sprites/EDR_Hunter") as EDRHunterTower
	var sniper_sfx := game.get_node_or_null(
		"Sounds/EDRHunterSniperShootSfx"
	) as AudioStreamPlayer
	if not _require(
		authored_edr != null and sniper_sfx != null,
		"Normal Game is missing its authored EDR Hunter or sniper SFX player."
	):
		return
	authored_edr.play_shoot()
	await process_frame
	if not _require(
		authored_edr.get("_defender_attack_sfx") == sniper_sfx
			and sniper_sfx.playing,
		"The first authored EDR Hunter did not resolve and play its sniper SFX."
	):
		return
	sniper_sfx.stop()

	var sprites := game.get_node_or_null("Sprites") as Node2D
	if not _require(sprites != null, "Normal Game is missing its Sprites node."):
		return

	var edr := EDR_HUNTER.instantiate() as EDRHunterTower
	sprites.add_child(edr)
	await process_frame
	edr.set("_placed", true)
	game.call("_on_edr_store_tower_placed", edr)

	for level in range(1, 6):
		_prepare_edr_level(edr, level)
		game.call("_spawn_virus", 0.0, false)
		var follow := _last_active_virus(game)
		var virus := _get_virus(follow)
		if not _require(
			follow != null and virus != null,
			"Could not create the level %d EDR target." % level
		):
			return

		virus.max_health = 100
		virus.reset_for_spawn()
		var health_before := virus.current_health
		for tick in range(4):
			game.call("_update_edr_hunter_attack", 0.1)

		var level_visual := edr.get_node_or_null(
			"RotatingVisual/LevelVisuals/LV%dVisual" % level
		) as AnimatedSprite2D
		if not _require(
			virus.current_health <= health_before - edr.get_shot_power()
				and level_visual != null
				and level_visual.visible
				and level_visual.animation == StringName("shoot_lv%d" % level),
			"EDR level %d did not damage its target with the matching shoot track." % level
		):
			return

		game.call("_despawn_virus", follow, false)
		await process_frame

	_prepare_edr_level(edr, 5)
	game.call("_spawn_cloaked_trojan_horse")
	var cloaked_follow := _last_active_virus(game)
	var cloaked_virus := _get_virus(cloaked_follow)
	if not _require(
		cloaked_follow != null and cloaked_virus != null,
		"Could not create the cloaked EDR targeting check."
	):
		return
	var cloaked_health_before := cloaked_virus.current_health
	for tick in range(5):
		game.call("_update_edr_hunter_attack", 0.1)
	if not _require(
		cloaked_virus.current_health == cloaked_health_before,
		"EDR Hunter incorrectly attacked a cloaked virus."
	):
		return

	print(
		"EDR Hunter attack validation passed: the first authored Hunter plays "
		+ "its sniper SFX; levels 1-5 aim, fire the matching animation, deal "
		+ "damage, and still ignore cloaked viruses."
	)
	game.queue_free()
	quit(0)


func _prepare_edr_level(edr: EDRHunterTower, level: int) -> void:
	edr.call("_return_to_rest_state")
	edr.level = level
	edr.set("_shot_cooldown_remaining", 0.0)
	edr.set("_hunter_is_aiming", false)
	edr.set("_hunter_aim_remaining", 0.0)
	edr.call("_sync_level_visual")


func _last_active_virus(game: Node) -> PathFollow2D:
	var active_viruses: Array = game.get("_active_viruses")
	if active_viruses.is_empty():
		return null
	return active_viruses.back() as PathFollow2D


func _get_virus(follow: PathFollow2D) -> RedVirus:
	if follow == null:
		return null
	for child in follow.get_children():
		var virus := child as RedVirus
		if virus != null:
			return virus
	return null


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
