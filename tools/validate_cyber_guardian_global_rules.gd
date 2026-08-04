extends SceneTree

const NORMAL_GAME := preload("res://Scenes/Gameplay/Normal_Game.tscn")
const GUARDIAN_CARD := preload(
	"res://Resources/TowerShopCards/CyberGuardianCard.tres"
)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := NORMAL_GAME.instantiate()
	root.add_child(game)
	await process_frame

	var cutscene := game.get_node_or_null(
		"TextCutsceneHUD"
	) as TextCutsceneHUD
	if cutscene != null and cutscene.is_cutscene_running():
		cutscene.skip_cutscene()
		await process_frame

	var guardian := game.get_node_or_null(
		"Sprites/Cybersec Guardian"
	) as CyberGuardianTower
	var card := game.get_node_or_null(
		"TowerStoreHUD/TestDrag/CyberGuardianCard"
	) as TowerShopCard
	var upgrade_hud := game.get_node_or_null(
		"TowerUpgradeHUD"
	) as TowerUpgradeHUD
	var question_hud := game.get_node_or_null(
		"CyberQuestionHUD"
	) as CyberQuestionHUD
	if not _require(
		guardian != null
			and card != null
			and upgrade_hud != null
			and question_hud != null,
		"Cyber Guardian economy validation nodes are incomplete."
	):
		return

	var cost_label := card.get_node_or_null("CostLabel") as Label
	var guardian_card_resource := GUARDIAN_CARD as TowerShopCardResource
	if not _require(
		guardian_card_resource.deploy_cost == 0
			and card.get_deploy_cost() == 0
			and cost_label != null
			and cost_label.text == "FREE"
			and int(game.call(
				"_get_default_tower_deploy_cost",
				guardian
			)) == 0
			and int(game.call(
				"_get_tower_deploy_cost",
				guardian
			)) == 0,
		"The Cyber Guardian is not globally presented and resolved as free."
	):
		return

	guardian_card_resource.deploy_cost = 999
	var protected_cost := int(game.call(
		"_get_tower_deploy_cost",
		guardian
	))
	guardian_card_resource.deploy_cost = 0
	if not _require(
		protected_cost == 0,
		"Custom card data was able to charge for the Cyber Guardian."
	):
		return

	upgrade_hud.show_guardian_panel()
	await process_frame
	if not _require(
		not upgrade_hud.is_sell_available()
			and not bool(game.call("_is_tower_sellable", guardian)),
		"The Cyber Guardian sidebar still exposes a sell action."
	):
		return

	var sell_signal_count := 0
	upgrade_hud.sell_pressed.connect(func() -> void:
		sell_signal_count += 1
	)
	upgrade_hud.call("_on_sell_button_pressed")
	if not _require(
		sell_signal_count == 0,
		"The hidden Guardian sell control emitted a sell request."
	):
		return

	var bucks_before := question_hud.get_cyberbucks()
	game.call("_sell_selected_tower")
	await process_frame
	if not _require(
		is_instance_valid(guardian)
			and not guardian.is_queued_for_deletion()
			and question_hud.get_cyberbucks() == bucks_before,
		"The gameplay sell path removed or refunded the Cyber Guardian."
	):
		return

	upgrade_hud.show_laser_panel()
	if not _require(
		upgrade_hud.is_sell_available(),
		"Disabling Guardian sales also disabled selling other towers."
	):
		return

	print(
		"Cyber Guardian global-rule validation passed: always free, "
		+ "card override protected, and selling blocked in UI and gameplay."
	)
	game.queue_free()
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
