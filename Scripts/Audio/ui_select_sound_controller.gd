extends Node

const CentralAudioResolver := preload("res://Scripts/Audio/audio_player_resolver.gd")

@export var select_sound_player_path: NodePath = ^"Sounds/UISelectSfx"

var _select_sound_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	_connect_buttons_recursive(get_tree().root)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node as BaseButton)


func _connect_buttons_recursive(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node as BaseButton)

	for child in node.get_children():
		_connect_buttons_recursive(child)


func _connect_button(button: BaseButton) -> void:
	var callback := Callable(self, "_play_select_sound")
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _play_select_sound() -> void:
	if not is_instance_valid(_select_sound_player):
		_select_sound_player = CentralAudioResolver.resolve(self, select_sound_player_path)
	if not is_instance_valid(_select_sound_player):
		return

	_select_sound_player.play()
