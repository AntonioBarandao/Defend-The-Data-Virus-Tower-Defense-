extends SceneTree

const WORM_BOSS := preload("res://Scenes/Enemies/WormBoss.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var worm := WORM_BOSS.instantiate() as WormBoss
	root.add_child(worm)
	await process_frame

	var head := worm.get_node_or_null("HeadAnimation") as AnimatedSprite2D
	if not _require(head != null, "Worm Boss is missing HeadAnimation."):
		return
	var authored_transforms := worm.get(
		"_part_authored_transforms"
	) as Array[Transform2D]
	var authored_global_scales := worm.get(
		"_part_authored_global_scales"
	) as Array[Vector2]
	var authored_scale := authored_transforms[0].get_scale()
	var authored_global_scale := authored_global_scales[0]
	head.show()
	worm.shield_flash_duration = 0.2

	head.scale = authored_scale * 1.05
	worm.call("_play_part_flash", 0, true)
	if not _require(
		head.scale.is_equal_approx(authored_scale),
		"Starting a flash did not first restore the authored head scale."
	):
		return

	await create_timer(0.05).timeout
	worm.call("_play_part_flash", 0, true)
	if not _require(
		head.scale.is_equal_approx(authored_scale),
		"Restarting an active flash retained its enlarged tween scale."
	):
		return

	await create_timer(0.25).timeout
	if not _require(
		head.scale.is_equal_approx(authored_scale)
			and head.modulate.is_equal_approx(Color.WHITE)
			and not (worm.get("_part_flash_tweens") as Dictionary).has(0),
		"The restarted flash did not finish at the authored appearance."
	):
		return

	head.top_level = true
	head.global_scale = authored_global_scale * 1.05
	worm.call("_play_part_flash", 0, true)
	if not _require(
		head.global_scale.is_equal_approx(authored_global_scale),
		"A path-following part did not reset to its authored global scale."
	):
		return
	await create_timer(0.05).timeout
	worm.call("_play_part_flash", 0, true)
	if not _require(
		head.global_scale.is_equal_approx(authored_global_scale),
		"A repeated path-following flash retained its enlarged scale."
	):
		return
	await create_timer(0.25).timeout
	if not _require(
		head.global_scale.is_equal_approx(authored_global_scale),
		"The path-following flash did not finish at its authored scale."
	):
		return

	print("Worm rapid-hit flash reset validation passed.")
	worm.queue_free()
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
