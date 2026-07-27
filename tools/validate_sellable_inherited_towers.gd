extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const EDR_HUNTER := preload("res://Scenes/Towers/EDR_Hunter.tscn")
const IPS_INTRUSION := preload("res://Scenes/Towers/IPS_Intrusion.tscn")


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

	var sprites := game.get_node_or_null("Sprites") as Node2D
	var upgrade_hud := game.get_node_or_null("TowerUpgradeHUD") as TowerUpgradeHUD
	var question_hud := game.get_node_or_null("CyberQuestionHUD") as CyberQuestionHUD
	if not _require(
		sprites != null and upgrade_hud != null and question_hud != null,
		"Tower sell validation nodes are incomplete."
	):
		return

	var edr := EDR_HUNTER.instantiate() as EDRHunterTower
	var ips := IPS_INTRUSION.instantiate() as IPSIntrusionTower
	sprites.add_child(edr)
	sprites.add_child(ips)
	await process_frame

	if not _require(
		bool(game.call("_is_tower_sellable", edr))
			and bool(game.call("_is_tower_sellable", ips))
			and StringName(game.call("_get_tower_id", edr)) == &"edr"
			and StringName(game.call("_get_tower_id", ips)) == &"ips",
		"EDR Hunter or IPS Intrusion still inherits the Guardian sell restriction."
	):
		return

	for tower in [edr, ips]:
		var deploy_cost := int(game.call("_get_tower_deploy_cost", tower))
		var timer_seconds := float(game.call(
			"_get_ransomware_timer_seconds",
			tower
		))
		var payment_cost := int(game.call(
			"_get_ransomware_payment_cost",
			tower
		))
		if not _require(
			deploy_cost > 0
				and is_equal_approx(timer_seconds, roundf(float(deploy_cost) / 10.0))
				and payment_cost == deploy_cost * 10,
			"An inherited tower still resolves Guardian economy or ransomware rules."
		):
			return

	game.call("_on_edr_store_tower_placed", edr)
	var edr_hit := bool(game.call(
		"_handle_edr_hunter_press",
		edr.global_position,
		edr.global_position
	))
	if not _require(
		edr_hit
			and upgrade_hud.is_edr_panel_visible()
			and upgrade_hud.is_sell_available()
			and _content_alpha(upgrade_hud) == 0.0,
		"EDR tower hit detection did not open a clean, sellable sidebar."
	):
		return
	await create_timer(0.2, true).timeout
	if not _require(
		_content_alpha(upgrade_hud) > 0.99
			and _sidebar_title(upgrade_hud) == "EDR Hunter",
		"EDR sidebar did not reveal the synchronized content."
	):
		return

	var edr_bucks_before := question_hud.get_cyberbucks()
	game.call("_sell_selected_tower")
	await process_frame
	if not _require(
		not is_instance_valid(edr)
			and question_hud.get_cyberbucks() > edr_bucks_before,
		"EDR Hunter was not removed and refunded through the real sell path."
	):
		return

	game.call("_on_ips_store_tower_placed", ips)
	var ips_hit := bool(game.call(
		"_handle_ips_intrusion_press",
		ips.global_position,
		ips.global_position
	))
	if not _require(
		ips_hit
			and upgrade_hud.is_ips_panel_visible()
			and upgrade_hud.is_sell_available()
			and _content_alpha(upgrade_hud) == 0.0,
		"IPS tower hit detection did not open a clean, sellable sidebar."
	):
		return
	await create_timer(0.2, true).timeout
	if not _require(
		_content_alpha(upgrade_hud) > 0.99
			and _sidebar_title(upgrade_hud) == "IPS Intrusion",
		"IPS sidebar did not reveal the synchronized content."
	):
		return

	var ips_bucks_before := question_hud.get_cyberbucks()
	game.call("_sell_selected_tower")
	await process_frame
	if not _require(
		not is_instance_valid(ips)
			and question_hud.get_cyberbucks() > ips_bucks_before,
		"IPS Intrusion was not removed and refunded through the real sell path."
	):
		return

	print(
		"Inherited tower sell validation passed: EDR and IPS are sellable, "
		+ "retain their own economy rules, and swap sidebar content cleanly."
	)
	game.queue_free()
	quit(0)


func _content_alpha(upgrade_hud: TowerUpgradeHUD) -> float:
	var content := upgrade_hud.get_node_or_null(
		"Root/MenuPanel/Margin/Content"
	) as Control
	return content.modulate.a if content != null else -1.0


func _sidebar_title(upgrade_hud: TowerUpgradeHUD) -> String:
	var title := upgrade_hud.get_node_or_null(
		"Root/MenuPanel/Margin/Content/Title"
	) as Label
	return title.text if title != null else ""


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
