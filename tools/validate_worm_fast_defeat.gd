extends SceneTree

const WORM_BOSS := preload("res://Scenes/Enemies/WormBoss.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	root.add_child(host)
	current_scene = host

	var path := Path2D.new()
	path.curve = Curve2D.new()
	path.curve.add_point(Vector2.ZERO)
	path.curve.add_point(Vector2(2400.0, 0.0))
	host.add_child(path)

	var worm := WORM_BOSS.instantiate() as WormBoss
	host.add_child(worm)
	await process_frame
	_prepare_fast_destroy_visuals(worm)
	worm.begin_path_spawn(path, 0.0)
	worm.set_wave_active(true)

	var offsets: Array = worm.get("_part_offsets")
	worm.call(
		"_process",
		(float(offsets[1]) + 1.0) / worm.path_speed
	)
	var emerged_targets := worm.get_attack_targets()
	_check(
		emerged_targets.size() == 2
			and worm.get_emerged_segment_count() == 2,
		"Fast-defeat setup exposes only the head and first body segment."
	)
	if emerged_targets.size() < 2:
		_finish(host)
		return

	var stale_head_target := emerged_targets[0]
	var body_target := emerged_targets[1]
	_check(
		body_target.take_damage(worm.max_health)
			and worm.is_destroying()
			and worm.current_health == 0,
		"An emerged body segment can defeat the Worm before full emergence."
	)
	_check(
		worm.get_attack_targets().is_empty()
			and not stale_head_target.is_targetable()
			and stale_head_target.is_queued_for_deletion(),
		"Defeat immediately invalidates and queues every cached part target."
	)

	worm.set("_head_progress", 2200.0)
	worm.call("_sync_parts_to_path")
	_check(
		_count_visible_source_parts(worm) == 2,
		"Pending path movement cannot reveal another source part after defeat."
	)

	await process_frame
	_check(
		_count_visible_destroy_parts(worm) == 2,
		"Only the two emerged parts start destroy animations."
	)
	_check(
		not _has_unemerged_part_visible(worm, 2),
		"Unemerged source and destroy parts stay hidden during defeat."
	)

	for _frame in range(240):
		await process_frame
		if worm.is_defeated():
			break
	_check(
		worm.is_defeated()
			and not worm.visible
			and _count_visible_source_parts(worm) == 0
			and _count_visible_destroy_parts(worm) == 0,
		"Defeat is confirmed only after current animations finish and all parts hide."
	)

	worm.set("_head_progress", 2400.0)
	worm.call("_sync_parts_to_path")
	await process_frame
	_check(
		_count_visible_source_parts(worm) == 0
			and _count_visible_destroy_parts(worm) == 0,
		"No delayed emergence can show a Worm part after confirmed defeat."
	)

	_finish(host)


func _prepare_fast_destroy_visuals(worm: WormBoss) -> void:
	worm.destroy_fade_duration = 0.01
	for visual in worm.get("_destroy_visuals"):
		var destroy_visual := visual as AnimatedSprite2D
		if destroy_visual != null:
			destroy_visual.speed_scale = 1000.0


func _count_visible_source_parts(worm: WormBoss) -> int:
	var count := 0
	for visual in worm.get("_part_visuals"):
		var part := visual as Node2D
		if is_instance_valid(part) and part.visible:
			count += 1
	return count


func _count_visible_destroy_parts(worm: WormBoss) -> int:
	var count := 0
	for visual in worm.get("_destroy_visuals"):
		var part := visual as AnimatedSprite2D
		if is_instance_valid(part) and part.visible:
			count += 1
	return count


func _has_unemerged_part_visible(worm: WormBoss, first_unemerged_index: int) -> bool:
	var source_parts: Array = worm.get("_part_visuals")
	var destroy_parts: Array = worm.get("_destroy_visuals")
	for index in range(first_unemerged_index, source_parts.size()):
		var source := source_parts[index] as Node2D
		if is_instance_valid(source) and source.visible:
			return true
		if index < destroy_parts.size():
			var destroy := destroy_parts[index] as AnimatedSprite2D
			if is_instance_valid(destroy) and destroy.visible:
				return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures.append(message)
	push_error("FAIL: %s" % message)


func _finish(host: Node) -> void:
	current_scene = null
	host.queue_free()
	for _frame in range(3):
		await process_frame
	if _failures.is_empty():
		print("Worm fast-defeat validation passed.")
	quit(0 if _failures.is_empty() else 1)
