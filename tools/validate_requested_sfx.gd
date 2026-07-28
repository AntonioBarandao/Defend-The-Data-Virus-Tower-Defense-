extends SceneTree

const CYBER_GUARDIAN := preload("res://Scenes/Towers/CyberGuardian.tscn")
const EDR_HUNTER := preload("res://Scenes/Towers/EDR_Hunter.tscn")
const HONEYPOT := preload("res://Scenes/Towers/Honeypot_Production.tscn")
const IDS_SCANNER := preload("res://Scenes/Towers/IDS_Scanner.tscn")
const TROJAN_HORSE := preload("res://Scenes/Enemies/TrojanHorse.tscn")
const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := NORMAL_GAME.instantiate()
	var text_cutscene := game.get_node_or_null("TextCutsceneHUD")
	if text_cutscene != null:
		text_cutscene.set("play_on_ready", false)
	root.add_child(game)
	await process_frame

	var sounds := game.get_node("Sounds")
	var authored_sound_volumes := {}
	for child in sounds.get_children():
		var player := child as AudioStreamPlayer
		_check(player != null, "NormalGame/Sounds contains a non-AudioStreamPlayer node: %s." % child.name)
		if player != null:
			authored_sound_volumes[player.name] = player.volume_db
			_check(not player.autoplay, "%s unexpectedly has autoplay enabled." % player.name)
			_check(not player.playing, "%s began playing before it was requested." % player.name)

	var guardian := CYBER_GUARDIAN.instantiate() as CyberGuardianTower
	game.add_child(guardian)
	await process_frame
	guardian.play_shoot()
	_check((sounds.get_node("CyberGuardianDefenderAttackSfx") as AudioStreamPlayer).playing, "Defender attack did not play its alternate SFX.")
	guardian.queue_free()

	var edr_hunter := EDR_HUNTER.instantiate() as EDRHunterTower
	game.add_child(edr_hunter)
	await process_frame
	edr_hunter.play_summon()
	_check((sounds.get_node("EDRHunterDeploySfx") as AudioStreamPlayer).playing, "EDR Hunter deployment did not play its SFX.")
	edr_hunter.play_shoot()
	_check((sounds.get_node("EDRHunterSniperShootSfx") as AudioStreamPlayer).playing, "EDR Hunter sniper shot did not play its SFX.")
	edr_hunter.fire_drone_at(Vector2.RIGHT * 100.0)
	_check((sounds.get_node("EDRHunterDroneShootSfx") as AudioStreamPlayer).playing, "EDR Hunter drone shot did not play its SFX.")
	edr_hunter.queue_free()

	var upgrade_hud := game.get_node("TowerUpgradeHUD") as TowerUpgradeHUD
	upgrade_hud.play_upgrade_sound()
	_check((sounds.get_node("UIUpgradeSfx") as AudioStreamPlayer).playing, "Successful tower upgrade SFX did not play.")

	var honeypot := HONEYPOT.instantiate() as HoneypotProductionTower
	game.add_child(honeypot)
	await process_frame
	honeypot.set("_placed", true)
	honeypot.play_summon()
	_check((sounds.get_node("HoneypotProductionDeploySfx") as AudioStreamPlayer).playing, "Honeypot deployment did not play its SFX.")
	honeypot.set("_production_pot", 10)
	honeypot.collect_production()
	_check((sounds.get_node("HoneypotProductionCollectSfx") as AudioStreamPlayer).playing, "Honeypot collection did not play its SFX.")
	honeypot.queue_free()

	var scanner := IDS_SCANNER.instantiate() as IDSScannerTower
	game.add_child(scanner)
	await process_frame
	scanner.deploy()
	_check((sounds.get_node("IDSScannerDeploySfx") as AudioStreamPlayer).playing, "IDS deployment did not play its SFX.")
	scanner.upgrade()
	_check(scanner.set_scanner_mode(IDSScannerTower.MODE_BURNER), "IDS test mode change was rejected.")
	_check((sounds.get_node("IDSScannerChangeModeSfx") as AudioStreamPlayer).playing, "IDS mode change did not play its SFX.")
	scanner.queue_free()

	var trojan := TROJAN_HORSE.instantiate() as TrojanHorse
	game.add_child(trojan)
	await process_frame
	_check(trojan.take_damage(trojan.max_health), "Trojan test damage did not destroy the virus.")
	_check((sounds.get_node("TrojanHorseDestroySfx") as AudioStreamPlayer).playing, "Trojan destruction did not play its SFX.")
	trojan.queue_free()

	var question_hud := game.get_node("CyberQuestionHUD") as CyberQuestionHUD
	question_hud.call("_trigger_phishing_decoy_failure")
	_check((sounds.get_node("PhishingEmailActivateSfx") as AudioStreamPlayer).playing, "Phishing activation SFX did not play.")
	_check((sounds.get_node("PhishingEmailDisplayedSfx") as AudioStreamPlayer).playing, "Phishing displayed SFX did not play after font corruption.")
	question_hud.end_phishing_effect()

	var button := Button.new()
	root.add_child(button)
	await process_frame
	button.pressed.emit()
	var ui_select_player := sounds.get_node("UISelectSfx") as AudioStreamPlayer
	_check(ui_select_player.playing, "Global UI selection SFX did not play for a button press.")
	button.queue_free()

	await process_frame
	for child in sounds.get_children():
		var player := child as AudioStreamPlayer
		if player != null:
			_check(
				is_equal_approx(player.volume_db, float(authored_sound_volumes[player.name])),
				"Playing %s overwrote its authored volume_db." % player.name
			)
	game.queue_free()
	await process_frame
	if _failures.is_empty():
		print("Requested SFX validation passed.")
	quit(0 if _failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)
