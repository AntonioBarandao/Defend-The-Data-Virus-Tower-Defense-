extends SceneTree

const GAME_SCENE := preload("res://Scenes/Gameplay/Cutscene_Test_Game.tscn")
const RED_VIRUS_SCENE := preload("res://Scenes/Enemies/RedVirus.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GAME_SCENE.instantiate()
	root.add_child(game)
	await process_frame

	var cutscene := game.get_node_or_null("TextCutsceneHUD") as TextCutsceneHUD
	if cutscene != null and cutscene.is_cutscene_running():
		cutscene.skip_cutscene()
		await process_frame

	var laser_turret := game.get_node_or_null("Sprites/Laser Turret") as LaserTurret
	var follow := PathFollow2D.new()
	var virus := RED_VIRUS_SCENE.instantiate() as RedVirus
	if laser_turret == null or virus == null:
		push_error("Laser reference validation could not instantiate its fixtures.")
		quit(1)
		return

	game.add_child(follow)
	follow.add_child(virus)
	await process_frame

	game.set("_utility_overlay_hud", null)
	game.set("_laser_turret", null)
	var targets: Array[PathFollow2D] = [follow]
	game.call("_shoot_laser_turret_targets", laser_turret, targets)
	if virus.current_health != 0 or not virus.is_destroying():
		push_error("Laser damage still depends on the mutable selected-turret reference.")
		quit(1)
		return

	print("Laser attack reference validation passed: firing uses the supplied turret instance.")
	game.queue_free()
	await process_frame
	quit(0)
