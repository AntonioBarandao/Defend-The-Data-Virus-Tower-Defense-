extends SceneTree

const IDS_SCANNER := preload("res://Scenes/Towers/IDS_Scanner.tscn")
const ADWARE := preload("res://Scenes/Enemies/Adware.tscn")
const TROJAN_HORSE := preload("res://Scenes/Enemies/TrojanHorse.tscn")
const WORM_BOSS := preload("res://Scenes/Enemies/WormBoss.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scanner := IDS_SCANNER.instantiate() as IDSScannerTower
	root.add_child(scanner)
	await process_frame
	scanner.level = 5
	scanner.call("_apply_level_stats")
	scanner.deploy()
	scanner.global_position = Vector2(500, 400)
	if not _require(
		scanner.set_scanner_mode(IDSScannerTower.MODE_NULLIFIER),
		"Level 5 IDS Scanner could not enter Nullifier mode."
	):
		return

	var attacker := Node.new()
	root.add_child(attacker)

	var adware := ADWARE.instantiate() as Adware
	var adware_follow := _add_path_virus(adware, Vector2(500, 400))
	await process_frame
	adware.process_mode = Node.PROCESS_MODE_DISABLED
	adware.reset_for_spawn()
	adware.setup(0)
	var adware_targets: Array[PathFollow2D] = [adware_follow]
	scanner.update_support_scan(adware_targets, 0.0)
	if not _require(
		adware.is_nullifier_suppressed()
			and adware.has_active_popups()
			and adware.self_modulate.is_equal_approx(
				adware.nullifier_highlight_color
			),
		"Nullifier did not temporarily suppress and highlight shielded Adware."
	):
		return

	scanner.global_position = Vector2(1500, 1400)
	scanner.update_support_scan(adware_targets, 0.0)
	var shielded_health := adware.current_health
	if not _require(
		not adware.is_nullifier_suppressed()
			and not adware.take_damage(1)
			and adware.current_health == shielded_health,
		"Adware popup invincibility did not return outside Nullifier range."
	):
		return

	adware.call("_stop_hit_flash")
	scanner.global_position = adware.global_position
	scanner.update_support_scan(adware_targets, 0.0)
	if not _require(
		adware.take_damage(adware.current_health)
			and not adware.has_active_popups(),
		"Nullifier did not bypass Adware popup invincibility or clear ads on defeat."
	):
		return

	var trojan := TROJAN_HORSE.instantiate() as TrojanHorse
	var trojan_follow := _add_path_virus(trojan, Vector2(500, 400))
	await process_frame
	trojan.process_mode = Node.PROCESS_MODE_DISABLED
	trojan.reset_for_spawn()
	trojan.spawn_as_cloaked()
	var trojan_targets: Array[PathFollow2D] = [trojan_follow]
	scanner.global_position = trojan.global_position
	scanner.update_support_scan(trojan_targets, 0.0)
	if not _require(
		trojan.is_cloaked()
			and trojan.is_nullifier_suppressed()
			and trojan.can_be_targeted_by(attacker)
			and trojan.self_modulate.is_equal_approx(
				trojan.nullifier_highlight_color
			),
		"Nullifier did not grant temporary targetability without decloaking Trojan Horse."
	):
		return

	scanner.global_position = Vector2(1500, 1400)
	scanner.update_support_scan(trojan_targets, 0.0)
	if not _require(
		trojan.is_cloaked()
			and not trojan.is_nullifier_suppressed()
			and not trojan.can_be_targeted_by(attacker),
		"Trojan Horse did not regain cloaked protection after leaving Nullifier."
	):
		return

	if not _require(
		scanner.set_scanner_mode(IDSScannerTower.MODE_CAMO),
		"IDS Scanner could not return to Camo mode."
	):
		return
	scanner.global_position = trojan.global_position
	scanner.update_support_scan(trojan_targets, 0.0)
	if not _require(
		not trojan.is_cloaked(),
		"Camo mode was not the mode that permanently revealed Trojan Horse."
	):
		return

	var path := Path2D.new()
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(2400, 0))
	path.curve = curve
	path.global_position = Vector2(100, 900)
	root.add_child(path)
	var worm := WORM_BOSS.instantiate() as WormBoss
	root.add_child(worm)
	await process_frame
	worm.process_mode = Node.PROCESS_MODE_DISABLED
	worm.begin_path_spawn(path, 900.0)
	worm.set_wave_active(true)
	var worm_targets := worm.get_attack_targets()
	if not _require(
		worm_targets.size() == 7,
		"Worm setup did not expose all seven part targets for Nullifier validation."
	):
		return

	var head_target := worm_targets[0]
	scanner.refresh_mode_lock([])
	if not _require(
		scanner.set_scanner_mode(IDSScannerTower.MODE_NULLIFIER),
		"IDS Scanner could not re-enter Nullifier mode for Worm validation."
	):
		return
	scanner.global_position = head_target.global_position
	scanner.update_support_scan(worm_targets, 0.0)
	var head := worm.get_node_or_null("HeadAnimation") as AnimatedSprite2D
	var health_before_nullifier := worm.current_health
	head_target.take_damage(10)
	if not _require(
		head_target.call("is_nullifier_suppressed")
			and worm.is_part_nullifier_suppressed(0)
			and worm.current_health == health_before_nullifier - 10
			and head != null
			and head.modulate.is_equal_approx(
				worm.nullifier_highlight_color
			),
		"Nullifier did not suppress and highlight the Worm head shield."
	):
		return

	scanner.global_position = Vector2(2200, 1800)
	scanner.update_support_scan(worm_targets, 0.0)
	var health_after_exit := worm.current_health
	head_target.take_damage(10)
	if not _require(
		not bool(head_target.call("is_nullifier_suppressed"))
			and not worm.is_part_nullifier_suppressed(0)
			and worm.current_health == health_after_exit,
		"Worm head shield did not return after leaving Nullifier range."
	):
		return

	print(
		"IDS Nullifier validation passed: temporary Adware and Worm shield "
		+ "suppression, popup cleanup, purple highlights, and Camo-only "
		+ "Trojan reveal."
	)
	quit(0)


func _add_path_virus(
	virus: RedVirus,
	path_position: Vector2
) -> PathFollow2D:
	var path := Path2D.new()
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(200, 0))
	path.curve = curve
	path.global_position = path_position
	root.add_child(path)
	var follow := PathFollow2D.new()
	follow.loop = false
	path.add_child(follow)
	follow.add_child(virus)
	return follow


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
