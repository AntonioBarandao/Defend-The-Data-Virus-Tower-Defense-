class_name CutsceneDemoDirector
extends Node

@export var game_path: NodePath = ^".."
@export var zombie_node_path: NodePath = ^"../ZombieNode"
@export_range(1, 20, 1) var zombie_node_first_visible_wave := 6

var _game: Node
var _zombie_node: ZombieNode


func _ready() -> void:
	_game = get_node_or_null(game_path)
	_zombie_node = get_node_or_null(zombie_node_path) as ZombieNode
	if _zombie_node != null:
		_zombie_node.deactivate()

	if _game == null:
		return

	if _game.has_signal("wave_started"):
		_game.connect("wave_started", Callable(self, "_on_wave_started"))
	if _game.has_signal("current_wave_changed"):
		_game.connect("current_wave_changed", Callable(self, "_on_current_wave_changed"))

	if _game.has_method("get_current_wave"):
		_update_zombie_node_for_wave(int(_game.call("get_current_wave")))


func _on_wave_started(wave_number: int) -> void:
	_update_zombie_node_for_wave(wave_number)


func _on_current_wave_changed(wave_number: int) -> void:
	_update_zombie_node_for_wave(wave_number)


func _update_zombie_node_for_wave(wave_number: int) -> void:
	if _zombie_node == null:
		return

	if wave_number < zombie_node_first_visible_wave:
		_zombie_node.deactivate()
		return

	_zombie_node.activate()
