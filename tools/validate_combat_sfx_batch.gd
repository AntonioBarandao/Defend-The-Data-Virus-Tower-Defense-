extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const CYBER_GUARDIAN := preload("res://Scenes/Towers/CyberGuardian.tscn")
const IDS_SCANNER := preload("res://Scenes/Towers/IDS_Scanner.tscn")
const SIEM_HAWK := preload("res://Scenes/Towers/SIEM_Hawk.tscn")
const IPS_INTRUSION := preload("res://Scenes/Towers/IPS_Intrusion.tscn")
const XDR_MECH := preload("res://Scenes/Towers/XDR_Mech.tscn")
const RED_VIRUS := preload("res://Scenes/Enemies/RedVirus.tscn")
const MUTANT_VIRUS := preload("res://Scenes/Enemies/MutantVirus.tscn")
const ARMORED_VIRUS := preload("res://Scenes/Enemies/ArmoredVirus.tscn")
const RANSOMWARE := preload("res://Scenes/Enemies/Ransomware.tscn")
const ADWARE := preload("res://Scenes/Enemies/Adware.tscn")
const SPYWARE := preload("res://Scenes/Enemies/Spyware.tscn")

const EXPECTED_PLAYERS: Array[StringName] = [
	&"SIEMHawkAttackSfx",
	&"SIEMHawkScanSfx",
	&"IPSIntrusionSpikeSfx",
	&"IPSIntrusionElectricitySfx",
	&"XDRMechDeploySfx",
	&"XDRMechClawSfx",
	&"XDRMechCannonSfx",
	&"XDRMechMinigunSfx",
	&"CyberGuardianFirewallActivateSfx",
	&"CyberGuardianFirewallChangeSfx",
	&"CyberGuardianSignalBoostChangeSfx",
	&"IDSScannerCamoSfx",
	&"IDSScannerBurnerSfx",
	&"IDSScannerBountySfx",
	&"IDSScannerSlownessSfx",
	&"IDSScannerNullifierSfx",
	&"MutantVirusDestroySfx",
	&"MutantVirusTransformSfx",
	&"MutantVirusMutatedSfx",
	&"ArmoredVirusDestroySfx",
	&"ArmoredVirusTransformSfx",
	&"CyberWormEntranceSfx",
	&"CyberWormDestroySfx",
	&"ZombieNodeEntranceSfx",
	&"ZombieNodeActivateSfx",
	&"ZombieNodeDestroySfx",
	&"ZombieNodeEvolutionSfx",
	&"RansomwareAppearSfx",
	&"RansomwarePaidSfx",
	&"RansomwareDeletedSfx",
	&"AdwarePopupSfx",
	&"SpywareHijackSfx",
	&"SpywareDestroySfx",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := NORMAL_GAME.instantiate()
	var text_cutscene := game.get_node_or_null("TextCutsceneHUD")
	if text_cutscene != null:
		text_cutscene.set("play_on_ready", false)
	root.add_child(game)
	current_scene = game
	await process_frame

	var sounds := game.get_node("Sounds")
	for player_name in EXPECTED_PLAYERS:
		var player := sounds.get_node_or_null(NodePath(player_name)) as AudioStreamPlayer
		_check(player != null, "%s is authored under NormalGame/Sounds." % player_name)
		if player == null:
			continue
		_check(player.stream != null, "%s has an imported WAV stream." % player_name)
		_check(player.bus == &"SFX", "%s is routed through the SFX bus." % player_name)
		_check(not player.autoplay, "%s does not autoplay." % player_name)

	await _validate_tower_sfx(game, sounds)
	await _validate_virus_sfx(game, sounds)
	await _validate_boss_sfx(game, sounds)

	game.queue_free()
	await process_frame
	if _failures.is_empty():
		print("Combat SFX batch validation passed.")
	quit(0 if _failures.is_empty() else 1)


func _validate_tower_sfx(game: Node, sounds: Node) -> void:
	var guardian := CYBER_GUARDIAN.instantiate()
	game.add_child(guardian)
	await process_frame
	guardian.set("_placed", true)
	guardian.set_guardian_mode(&"signal_boost")
	_expect_playing(sounds, &"CyberGuardianSignalBoostChangeSfx")
	_stop(sounds, &"CyberGuardianSignalBoostChangeSfx")
	guardian.set_guardian_mode(&"firewall")
	_expect_playing(sounds, &"CyberGuardianFirewallChangeSfx")
	_stop(sounds, &"CyberGuardianFirewallChangeSfx")
	guardian.activate_firewall()
	_expect_playing(sounds, &"CyberGuardianFirewallActivateSfx")
	guardian.queue_free()

	var hawk := SIEM_HAWK.instantiate()
	game.add_child(hawk)
	await process_frame
	hawk.play_shoot()
	_expect_playing(sounds, &"SIEMHawkAttackSfx")
	hawk.call("_play_audio_player_if_idle", sounds.get_node("SIEMHawkScanSfx"))
	_expect_playing(sounds, &"SIEMHawkScanSfx")
	hawk.queue_free()

	var ips := IPS_INTRUSION.instantiate()
	game.add_child(ips)
	await process_frame
	ips.call("_play_sfx_if_idle", sounds.get_node("IPSIntrusionSpikeSfx"))
	_expect_playing(sounds, &"IPSIntrusionSpikeSfx")
	ips.call("_play_sfx_if_idle", sounds.get_node("IPSIntrusionElectricitySfx"))
	_expect_playing(sounds, &"IPSIntrusionElectricitySfx")
	ips.queue_free()

	var mech := XDR_MECH.instantiate()
	game.add_child(mech)
	await process_frame
	mech.call("_play_deploy_sfx")
	_expect_playing(sounds, &"XDRMechDeploySfx")
	mech.call("_play_claw_sfx")
	_expect_playing(sounds, &"XDRMechClawSfx")
	mech.call("_fire_level_2_cannon")
	_expect_playing(sounds, &"XDRMechCannonSfx")
	mech.call("_fire_level_4_minigun_line")
	_expect_playing(sounds, &"XDRMechMinigunSfx")
	mech.call("_stop_attack_sfx")
	mech.queue_free()

	var scanner := IDS_SCANNER.instantiate()
	game.add_child(scanner)
	await process_frame
	scanner.level = 5
	scanner.call("_apply_level_stats")
	scanner.deploy()

	var follow := PathFollow2D.new()
	var virus := RED_VIRUS.instantiate()
	follow.add_child(virus)
	game.add_child(follow)
	await process_frame
	var active_viruses: Array[PathFollow2D] = [follow]
	var mode_players := {
		&"camo": &"IDSScannerCamoSfx",
		&"burner": &"IDSScannerBurnerSfx",
		&"bounty": &"IDSScannerBountySfx",
		&"quarantine": &"IDSScannerSlownessSfx",
		&"nullifier": &"IDSScannerNullifierSfx",
	}
	for mode_id in mode_players:
		virus.global_position = scanner.global_position + Vector2(10000.0, 0.0)
		scanner.update_support_scan(active_viruses, 0.0)
		_check(scanner.set_scanner_mode(mode_id), "IDS mode %s is available at LV5." % mode_id)
		var player_name: StringName = mode_players[mode_id]
		_stop(sounds, player_name)
		virus.global_position = scanner.global_position
		scanner.update_support_scan(active_viruses, 0.0)
		_expect_playing(sounds, player_name)
	scanner.queue_free()
	follow.queue_free()


func _validate_virus_sfx(game: Node, sounds: Node) -> void:
	var mutant := MUTANT_VIRUS.instantiate()
	game.add_child(mutant)
	await process_frame
	mutant.take_damage(mutant.max_health)
	_expect_playing(sounds, &"MutantVirusDestroySfx")
	mutant.queue_free()

	var armored := ARMORED_VIRUS.instantiate()
	game.add_child(armored)
	await process_frame
	armored.take_damage(armored.max_health)
	_expect_playing(sounds, &"ArmoredVirusDestroySfx")
	armored.queue_free()

	game.call("_play_named_sound", &"MutantVirusMutatedSfx")
	_expect_playing(sounds, &"MutantVirusMutatedSfx")
	game.call("_play_named_sound", &"MutantVirusTransformSfx")
	_expect_playing(sounds, &"MutantVirusTransformSfx")
	game.call("_play_named_sound", &"ArmoredVirusTransformSfx")
	_expect_playing(sounds, &"ArmoredVirusTransformSfx")

	var adware := ADWARE.instantiate()
	game.add_child(adware)
	await process_frame
	adware.setup(0)
	_expect_playing(sounds, &"AdwarePopupSfx")
	adware.queue_free()

	var spyware := SPYWARE.instantiate()
	var target := Node2D.new()
	target.name = "SFXHijackTarget"
	game.add_child(target)
	game.add_child(spyware)
	await process_frame
	spyware.set("_invasion_target", target)
	spyware.call("_activate_tower_hijack")
	_expect_playing(sounds, &"SpywareHijackSfx")
	spyware.take_damage(spyware.max_health)
	_expect_playing(sounds, &"SpywareDestroySfx")
	spyware.queue_free()
	target.queue_free()


func _validate_boss_sfx(game: Node, sounds: Node) -> void:
	var worm := game.get_node("WormBoss")
	worm.prepare_cutscene_preview(worm.global_position)
	_expect_playing(sounds, &"CyberWormEntranceSfx")
	worm.set("_state", &"active")
	worm.call("_begin_defeat")
	_expect_playing(sounds, &"CyberWormDestroySfx")

	var zombie := game.get_node("ZombieNode")
	zombie.prepare_entrance()
	zombie.play_entrance()
	_expect_playing(sounds, &"ZombieNodeEntranceSfx")
	zombie.finish_entrance_immediately()
	zombie.active = true
	_stop(sounds, &"ZombieNodeEvolutionSfx")
	zombie.set_level(2)
	_expect_playing(sounds, &"ZombieNodeEvolutionSfx")
	zombie.set_wave_active(true)
	zombie.call("_begin_timed_minion_spawn")
	_expect_playing(sounds, &"ZombieNodeActivateSfx")
	zombie.play_destroy_animation()
	_expect_playing(sounds, &"ZombieNodeDestroySfx")

	var target := Node2D.new()
	game.add_child(target)
	var ransomware := RANSOMWARE.instantiate()
	game.add_child(ransomware)
	await process_frame
	ransomware.configure(target, 30.0, 500)
	ransomware.play_appear()
	_expect_playing(sounds, &"RansomwareAppearSfx")
	ransomware.finish_appear_immediately()
	ransomware.release_from_payment()
	_expect_playing(sounds, &"RansomwarePaidSfx")
	ransomware.queue_free()

	var deleted_target := Node2D.new()
	game.add_child(deleted_target)
	var deleted_ransomware := RANSOMWARE.instantiate()
	game.add_child(deleted_ransomware)
	await process_frame
	deleted_ransomware.configure(deleted_target, 30.0, 500)
	deleted_ransomware.finish_appear_immediately()
	deleted_ransomware.take_damage(deleted_ransomware.maximum_health)
	_expect_playing(sounds, &"RansomwareDeletedSfx")
	deleted_ransomware.queue_free()
	target.queue_free()
	deleted_target.queue_free()


func _expect_playing(sounds: Node, player_name: StringName) -> void:
	var player := sounds.get_node_or_null(NodePath(player_name)) as AudioStreamPlayer
	_check(player != null and player.playing, "%s plays from its event hook." % player_name)


func _stop(sounds: Node, player_name: StringName) -> void:
	var player := sounds.get_node_or_null(NodePath(player_name)) as AudioStreamPlayer
	if player != null:
		player.stop()


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)
