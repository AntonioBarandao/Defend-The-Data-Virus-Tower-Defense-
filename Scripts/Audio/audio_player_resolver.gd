class_name AudioPlayerResolver
extends RefCounted


static func resolve(context: Node, player_path: NodePath) -> AudioStreamPlayer:
	if context == null or player_path.is_empty():
		return null

	var local_player := context.get_node_or_null(player_path) as AudioStreamPlayer
	if local_player != null:
		return local_player

	var tree := context.get_tree()
	if tree == null:
		return null

	var player_name := player_path.get_name(player_path.get_name_count() - 1)
	var current_scene := tree.current_scene
	if current_scene != null:
		var central_player := current_scene.get_node_or_null(NodePath("Sounds/%s" % player_name)) as AudioStreamPlayer
		if central_player != null:
			return central_player

	for candidate in tree.get_nodes_in_group(&"Sound"):
		var player := candidate as AudioStreamPlayer
		if player != null and player.name == player_name:
			return player

	return null
