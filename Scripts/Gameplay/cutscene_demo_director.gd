class_name CutsceneDemoDirector
extends Node

const WaveManagerScript := preload("res://Scripts/Gameplay/wave_manager.gd")

@export var game_path: NodePath = ^".."
@export var zombie_node_path: NodePath = ^"../ZombieNode"
@export var botnet_node_path: NodePath = ^"../BotnetNode"
@export var worm_boss_path: NodePath = ^"../WormBoss"
@export var text_cutscene_hud_path: NodePath = ^"../TextCutsceneHUD"
@export_group("Zombie Node Waves")
@export_range(1, 25, 1) var zombie_node_first_visible_wave := 11
@export_range(1, 25, 1) var zombie_node_middle_form_wave := 13
@export_range(1, 25, 1) var zombie_node_final_form_wave := 15
@export_range(1, 25, 1) var worm_boss_wave := 20
@export_group("Botnet Node Waves")
@export_range(1, 25, 1) var botnet_node_first_visible_wave := 21
@export_range(1, 25, 1) var botnet_node_middle_form_wave := 23
@export_range(1, 25, 1) var botnet_node_final_form_wave := 25
@export_group("")

var _wave_manager := WaveManagerScript.new()
var _game: Node
var _zombie_node: ZombieNode
var _botnet_node: BotnetNode
var _worm_boss: WormBoss
var _text_cutscene_hud: TextCutsceneHUD
var _entrance_played := false
var _middle_transform_played := false
var _final_transform_played := false
var _defeat_cutscene_played := false
var _worm_intro_played := false
var _worm_defeat_cutscene_played := false
var _botnet_middle_transform_played := false
var _botnet_final_transform_played := false
var _cutscene_running := false


func _ready() -> void:
	_game = get_node_or_null(game_path)
	_zombie_node = get_node_or_null(zombie_node_path) as ZombieNode
	_botnet_node = get_node_or_null(botnet_node_path) as BotnetNode
	_worm_boss = get_node_or_null(worm_boss_path) as WormBoss
	_text_cutscene_hud = get_node_or_null(text_cutscene_hud_path) as TextCutsceneHUD
	if _zombie_node != null:
		_zombie_node.deactivate()
	if _botnet_node != null:
		_botnet_node.deactivate()
	if _worm_boss != null:
		_worm_boss.deactivate()

	if _game == null:
		return

	if _game.has_signal("wave_started"):
		_game.connect("wave_started", Callable(self, "_on_wave_started"))
	if _game.has_signal("current_wave_changed"):
		_game.connect("current_wave_changed", Callable(self, "_on_current_wave_changed"))

	if _game.has_method("get_current_wave"):
		_update_bosses_for_wave(int(_game.call("get_current_wave")))


func _on_wave_started(wave_number: int) -> void:
	_update_bosses_for_wave(wave_number)


func _on_current_wave_changed(wave_number: int) -> void:
	_update_bosses_for_wave(wave_number)


func _update_bosses_for_wave(wave_number: int) -> void:
	_update_zombie_node_for_wave(wave_number)
	_update_botnet_node_for_wave(wave_number)
	_update_worm_boss_for_wave(wave_number)


func _update_zombie_node_for_wave(wave_number: int) -> void:
	if _zombie_node == null:
		return
	if _cutscene_running:
		return

	if _wave_manager.get_progressive_boss_name(wave_number) \
			!= WaveManagerScript.ZOMBIE_NODE:
		_zombie_node.deactivate()
		return
	if _zombie_node.is_defeated():
		_zombie_node.complete_defeat()
		return

	_zombie_node.set_level(
		_wave_manager.get_progressive_boss_level(wave_number)
	)
	if not _zombie_node.active:
		_zombie_node.activate()
	_zombie_node.set_combat_unlocked(
		wave_number >= zombie_node_final_form_wave
	)


func _update_botnet_node_for_wave(wave_number: int) -> void:
	if _botnet_node == null:
		return
	if _cutscene_running:
		return

	if _wave_manager.get_progressive_boss_name(wave_number) \
			!= WaveManagerScript.BOTNET_NODE:
		_botnet_node.deactivate()
		return

	_botnet_node.set_level(
		_wave_manager.get_progressive_boss_level(wave_number)
	)
	if not _botnet_node.active:
		_botnet_node.activate()


func should_play_botnet_middle_transform(next_wave: int) -> bool:
	return not _botnet_middle_transform_played \
		and not _cutscene_running \
		and next_wave == botnet_node_middle_form_wave \
		and _wave_manager.get_progressive_boss_name(next_wave) \
			== WaveManagerScript.BOTNET_NODE \
		and is_instance_valid(_botnet_node)


func play_botnet_middle_transform() -> void:
	if not should_play_botnet_middle_transform(
		botnet_node_middle_form_wave
	):
		return

	_botnet_middle_transform_played = true
	_cutscene_running = true
	var target_level := _wave_manager.get_progressive_boss_level(
		botnet_node_middle_form_wave
	)
	await _botnet_node.play_evolution_to_level(target_level)
	if is_instance_valid(_botnet_node) \
			and _botnet_node.get_level() != target_level:
		_botnet_node.finish_evolution_immediately(target_level)
	_cutscene_running = false


func should_play_botnet_final_transform(next_wave: int) -> bool:
	return not _botnet_final_transform_played \
		and not _cutscene_running \
		and next_wave == botnet_node_final_form_wave \
		and _wave_manager.get_progressive_boss_name(next_wave) \
			== WaveManagerScript.BOTNET_NODE \
		and is_instance_valid(_botnet_node)


func play_botnet_final_transform() -> void:
	if not should_play_botnet_final_transform(
		botnet_node_final_form_wave
	):
		return

	_botnet_final_transform_played = true
	_cutscene_running = true
	var target_level := _wave_manager.get_progressive_boss_level(
		botnet_node_final_form_wave
	)
	await _botnet_node.play_evolution_to_level(target_level)
	if is_instance_valid(_botnet_node) \
			and _botnet_node.get_level() != target_level:
		_botnet_node.finish_evolution_immediately(target_level)
	_cutscene_running = false


func _update_worm_boss_for_wave(wave_number: int) -> void:
	if _worm_boss == null or _cutscene_running:
		return
	if _wave_manager.get_progressive_boss_name(wave_number) \
			== WaveManagerScript.WORM_BOSS:
		return
	_worm_boss.deactivate()


func should_play_zombie_entrance(next_wave: int) -> bool:
	return not _entrance_played \
		and not _cutscene_running \
		and next_wave == zombie_node_first_visible_wave \
		and _wave_manager.get_progressive_boss_name(next_wave) \
			== WaveManagerScript.ZOMBIE_NODE \
		and is_instance_valid(_zombie_node)


func play_zombie_entrance_cutscene() -> void:
	if not should_play_zombie_entrance(zombie_node_first_visible_wave):
		return

	_entrance_played = true
	_cutscene_running = true
	if _text_cutscene_hud != null:
		_text_cutscene_hud.start_wave11_cutscene()
		await _text_cutscene_hud.cutscene_finished
	else:
		_zombie_node.set_level(1)
		_zombie_node.prepare_entrance()
		await _zombie_node.play_entrance()
	_cutscene_running = false


func should_play_zombie_middle_transform(next_wave: int) -> bool:
	return not _middle_transform_played \
		and not _cutscene_running \
		and next_wave == zombie_node_middle_form_wave \
		and _wave_manager.get_progressive_boss_name(next_wave) \
			== WaveManagerScript.ZOMBIE_NODE \
		and is_instance_valid(_zombie_node)


func play_zombie_middle_transform() -> void:
	if not should_play_zombie_middle_transform(
		zombie_node_middle_form_wave
	):
		return

	_middle_transform_played = true
	_cutscene_running = true
	var target_level := _wave_manager.get_progressive_boss_level(
		zombie_node_middle_form_wave
	)
	await _zombie_node.play_evolution_to_level(target_level)
	if is_instance_valid(_zombie_node) \
			and _zombie_node.get_level() != target_level:
		_zombie_node.finish_evolution_immediately(target_level)
	_cutscene_running = false


func should_play_zombie_final_transform(next_wave: int) -> bool:
	return not _final_transform_played \
		and not _cutscene_running \
		and next_wave == zombie_node_final_form_wave \
		and _wave_manager.get_progressive_boss_name(next_wave) \
			== WaveManagerScript.ZOMBIE_NODE \
		and is_instance_valid(_zombie_node)


func play_zombie_final_transform_cutscene() -> void:
	if not should_play_zombie_final_transform(zombie_node_final_form_wave):
		return

	_final_transform_played = true
	_cutscene_running = true
	var target_level := _wave_manager.get_progressive_boss_level(
		zombie_node_final_form_wave
	)
	if _text_cutscene_hud != null:
		_text_cutscene_hud.start_wave15_zombie_transform_cutscene()
		await _text_cutscene_hud.cutscene_finished
	else:
		_zombie_node.prepare_evolution_for_cutscene()
		await _zombie_node.play_evolution_to_level(target_level)
	if is_instance_valid(_zombie_node) \
			and _zombie_node.get_level() != target_level:
		_zombie_node.finish_evolution_immediately(target_level)
	_cutscene_running = false


func play_zombie_defeat_cutscene() -> void:
	if _defeat_cutscene_played \
			or _cutscene_running \
			or not is_instance_valid(_zombie_node):
		return

	_defeat_cutscene_played = true
	_cutscene_running = true
	if _text_cutscene_hud != null:
		_text_cutscene_hud.start_zombie_node_defeat_cutscene()
		await _text_cutscene_hud.cutscene_finished
	_zombie_node.complete_defeat()
	_cutscene_running = false


func should_play_worm_boss_intro(next_wave: int) -> bool:
	return not _worm_intro_played \
		and not _cutscene_running \
		and next_wave == worm_boss_wave \
		and _wave_manager.get_progressive_boss_name(next_wave) \
			== WaveManagerScript.WORM_BOSS \
		and is_instance_valid(_worm_boss)


func play_worm_boss_intro_cutscene() -> void:
	if not should_play_worm_boss_intro(worm_boss_wave):
		return

	_worm_intro_played = true
	_cutscene_running = true
	if _text_cutscene_hud != null:
		_text_cutscene_hud.start_wave20_worm_boss_cutscene()
		await _text_cutscene_hud.cutscene_finished
	_cutscene_running = false


func play_worm_boss_defeat_cutscene() -> void:
	if _worm_defeat_cutscene_played or _cutscene_running:
		return

	_worm_defeat_cutscene_played = true
	_cutscene_running = true
	if _text_cutscene_hud != null:
		_text_cutscene_hud.start_worm_boss_defeat_cutscene()
		await _text_cutscene_hud.cutscene_finished
	_cutscene_running = false


func is_cutscene_running() -> bool:
	return _cutscene_running


func mark_entrance_played_for_wave(wave_number: int) -> void:
	_entrance_played = wave_number >= zombie_node_first_visible_wave
	_middle_transform_played = wave_number >= zombie_node_middle_form_wave
	_final_transform_played = wave_number >= zombie_node_final_form_wave
	_defeat_cutscene_played = wave_number >= zombie_node_final_form_wave
	_worm_intro_played = wave_number >= worm_boss_wave
	_botnet_middle_transform_played = (
		wave_number >= botnet_node_middle_form_wave
	)
	_botnet_final_transform_played = (
		wave_number >= botnet_node_final_form_wave
	)


func _get_zombie_level_for_wave(wave_number: int) -> int:
	if _wave_manager.get_progressive_boss_name(wave_number) \
			!= WaveManagerScript.ZOMBIE_NODE:
		return 0
	return _wave_manager.get_progressive_boss_level(wave_number)


func _get_botnet_level_for_wave(wave_number: int) -> int:
	if _wave_manager.get_progressive_boss_name(wave_number) \
			!= WaveManagerScript.BOTNET_NODE:
		return 0
	return _wave_manager.get_progressive_boss_level(wave_number)
