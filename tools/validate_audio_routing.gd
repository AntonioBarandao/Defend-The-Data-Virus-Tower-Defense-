extends SceneTree

const AUDIO_SCENES := [
	"res://Scenes/Audio/UISelectSoundController.tscn",
	"res://Scenes/UI/CyberQuestionHud.tscn",
	"res://Scenes/UI/TextCutsceneHUD.tscn",
	"res://Scenes/UI/TowerUpgradeHud.tscn",
	"res://Scenes/Enemies/Adware.tscn",
	"res://Scenes/Enemies/ArmoredVirus.tscn",
	"res://Scenes/Enemies/MutantVirus.tscn",
	"res://Scenes/Enemies/RedVirus.tscn",
	"res://Scenes/Enemies/Spyware.tscn",
	"res://Scenes/Enemies/TrojanHorse.tscn",
	"res://Scenes/Towers/CyberGuardian.tscn",
	"res://Scenes/Towers/EDR_Hunter.tscn",
	"res://Scenes/Towers/Honeypot_Production.tscn",
	"res://Scenes/Towers/IDS_Scanner.tscn",
	"res://Scenes/Towers/LaserTurret.tscn",
]
const NORMAL_GAME_SCENE := "res://Scenes/Gameplay/Normal_Game.tscn"
const CUTSCENE_TEST_GAME_SCENE := "res://Scenes/Gameplay/Cutscene_Test_Game.tscn"
const ADMIN_GAME_SCENE := "res://Scenes/Gameplay/Admin_Sandbox.tscn"
const MUSIC_GAME_SCENES := [NORMAL_GAME_SCENE, ADMIN_GAME_SCENE]
const NORMAL_GAME_SOUNDTRACK := "res://assets/soundtrack/Cyber-Business-Soundtrack.wav"
const ADMIN_GAME_SOUNDTRACK := "res://assets/soundtrack/Virtual Business.wav"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(AudioServer.get_bus_index("Master") >= 0, "Master audio bus is missing.")
	_check(AudioServer.get_bus_index("Music") >= 0, "Music audio bus is missing.")
	_check(AudioServer.get_bus_index("SFX") >= 0, "SFX audio bus is missing.")

	for scene_path in AUDIO_SCENES:
		var packed_scene := load(scene_path) as PackedScene
		_check(packed_scene != null, "Could not load %s." % scene_path)
		if packed_scene == null:
			continue
		var instance := packed_scene.instantiate()
		_validate_no_audio_players(instance, scene_path, String(instance.name))
		instance.free()

	var packed_normal_game := load(NORMAL_GAME_SCENE) as PackedScene
	_check(packed_normal_game != null, "Could not load %s." % NORMAL_GAME_SCENE)
	if packed_normal_game != null:
		var normal_game := packed_normal_game.instantiate()
		var sounds := normal_game.get_node_or_null("Sounds")
		_check(sounds != null, "Normal_Game.tscn does not contain a Sounds node.")
		if sounds != null:
			_validate_sound_players(sounds, NORMAL_GAME_SCENE, "NormalGame/Sounds")
			_validate_sfx_asset_coverage(sounds)
		normal_game.free()

	for scene_path in MUSIC_GAME_SCENES:
		var packed_game := load(scene_path) as PackedScene
		_check(packed_game != null, "Could not load %s." % scene_path)
		if packed_game == null:
			continue
		var game := packed_game.instantiate()
		var music := game.get_node_or_null("Music/CyberBusiness") as AudioStreamPlayer
		_check(music != null, "%s does not own Music/CyberBusiness as an AudioStreamPlayer." % scene_path)
		if music != null:
			_check(music.bus == &"Music", "%s CyberBusiness is not routed to Music." % scene_path)
			_check(music.is_in_group(&"Music"), "%s CyberBusiness is not in the Music group." % scene_path)
			if scene_path == NORMAL_GAME_SCENE:
				_check(music.stream.resource_path == NORMAL_GAME_SOUNDTRACK, "Normal Game is not using the Cyber Business soundtrack.")
			elif scene_path == ADMIN_GAME_SCENE:
				_check(music.stream.resource_path == ADMIN_GAME_SOUNDTRACK, "Admin Sandbox is not using the Virtual Business soundtrack.")
		game.free()

	var packed_runtime_game := load(NORMAL_GAME_SCENE) as PackedScene
	var game: Node = packed_runtime_game.instantiate()
	var text_cutscene: Node = game.get_node_or_null("TextCutsceneHUD")
	if text_cutscene != null:
		text_cutscene.set("play_on_ready", false)
	var music_before_start := game.get_node_or_null("Music/CyberBusiness") as AudioStreamPlayer
	_check(music_before_start != null and not music_before_start.playing, "CyberBusiness was already playing before Normal Game entered the scene tree.")
	var authored_music_volume_db := music_before_start.volume_db if music_before_start != null else 0.0
	var authored_sound_volumes := {}
	var runtime_sounds := game.get_node_or_null("Sounds")
	if runtime_sounds != null:
		for child in runtime_sounds.get_children():
			var player := child as AudioStreamPlayer
			if player != null:
				authored_sound_volumes[player.name] = player.volume_db
	root.add_child(game)
	await process_frame
	var music := game.get_node_or_null("Music/CyberBusiness") as AudioStreamPlayer
	_check(music != null and music.playing, "CyberBusiness did not begin playing when the game started.")
	if music != null and text_cutscene != null:
		music.stop()
		text_cutscene.call("start_cutscene")
		await process_frame
		_check(str(text_cutscene.get("current_phase")) == "phase_1", "Opening cutscene did not enter Phase 1.")
		_check(music.playing, "CyberBusiness did not restart for cutscene Phase 1.")
		text_cutscene.call("skip_cutscene")

	var menu: Node = game.get_node_or_null("CutsceneDemoMenuHUD")
	_check(menu != null, "Settings menu was not found.")
	if menu != null:
		menu.call("_set_music_volume", 0.4)
		menu.call("_set_sound_volume", 0.25)
		menu.call("_set_bus_volume", "Master", 0.6)
		_check(is_equal_approx(_get_bus_linear("Music"), 0.4), "Music slider did not update the Music bus.")
		_check(is_equal_approx(_get_bus_linear("SFX"), 0.25), "Sound slider did not update the SFX bus.")
		_check(is_equal_approx(_get_bus_linear("Master"), 0.6), "Master slider did not update the Master bus.")
		_check(is_equal_approx(music.volume_db, authored_music_volume_db), "Music slider overwrote the soundtrack's authored volume_db.")
		for child in runtime_sounds.get_children():
			var player := child as AudioStreamPlayer
			if player == null:
				continue
			_check(player.bus == &"SFX", "%s was not connected to the SFX bus." % player.name)
			_check(
				is_equal_approx(player.volume_db, float(authored_sound_volumes.get(player.name, player.volume_db))),
				"Sound slider overwrote %s's authored volume_db." % player.name
			)
		var sample_player := runtime_sounds.get_child(0) as AudioStreamPlayer
		var sfx_bus_index := AudioServer.get_bus_index("SFX")
		_check(
			is_equal_approx(
				sample_player.volume_db + AudioServer.get_bus_volume_db(sfx_bus_index),
				float(authored_sound_volumes[sample_player.name]) + linear_to_db(0.25)
			),
			"SFX bus volume was not combined with the player's authored volume_db."
		)

	_set_bus_linear("Music", 1.0)
	_set_bus_linear("SFX", 1.0)
	_set_bus_linear("Master", 1.0)
	game.queue_free()
	await process_frame

	var packed_cutscene_game := load(CUTSCENE_TEST_GAME_SCENE) as PackedScene
	var cutscene_game := packed_cutscene_game.instantiate()
	var standalone_cutscene := cutscene_game.get_node_or_null("TextCutsceneHUD")
	if standalone_cutscene != null:
		standalone_cutscene.set("play_on_ready", false)
	root.add_child(cutscene_game)
	await process_frame
	if standalone_cutscene != null:
		standalone_cutscene.call("start_cutscene")
		await process_frame
	var cutscene_music := cutscene_game.get_node_or_null("Music/CyberBusiness") as AudioStreamPlayer
	_check(cutscene_music != null, "The standalone cutscene did not create its CyberBusiness AudioStreamPlayer.")
	if cutscene_music != null:
		_check(cutscene_music.playing, "The standalone cutscene did not start CyberBusiness in Phase 1.")
		_check(cutscene_music.stream.resource_path == NORMAL_GAME_SOUNDTRACK, "The standalone cutscene is not playing Cyber Business.")
	if standalone_cutscene != null:
		standalone_cutscene.call("skip_cutscene")
	cutscene_game.queue_free()
	await process_frame

	if _failures.is_empty():
		print("CyberBusiness playback and settings audio routing validation passed.")
	quit(0 if _failures.is_empty() else 1)


func _validate_sound_players(node: Node, scene_path: String, node_path: String) -> void:
	if node is AudioStreamPlayer:
		var player := node as AudioStreamPlayer
		_check(player.bus == &"SFX", "%s:%s is not routed to SFX." % [scene_path, node_path])
		_check(player.is_in_group(&"Sound"), "%s:%s is not in the Sound group." % [scene_path, node_path])
		_check(player.get_parent().name == &"Sounds", "%s:%s is not inside a Sounds node." % [scene_path, node_path])
		_check(not player.autoplay, "%s:%s has autoplay enabled." % [scene_path, node_path])
		_check(not player.playing, "%s:%s is playing before being requested." % [scene_path, node_path])
	for child in node.get_children():
		_validate_sound_players(child, scene_path, "%s/%s" % [node_path, child.name])


func _validate_no_audio_players(node: Node, scene_path: String, node_path: String) -> void:
	_check(not node is AudioStreamPlayer, "%s:%s owns an AudioStreamPlayer instead of using NormalGame/Sounds." % [scene_path, node_path])
	for child in node.get_children():
		_validate_no_audio_players(child, scene_path, "%s/%s" % [node_path, child.name])


func _validate_sfx_asset_coverage(sounds: Node) -> void:
	var referenced_streams := {}
	for child in sounds.get_children():
		var player := child as AudioStreamPlayer
		_check(player != null, "NormalGame/Sounds contains a non-AudioStreamPlayer node: %s." % child.name)
		if player != null and player.stream != null:
			referenced_streams[player.stream.resource_path] = true

	for file_name in DirAccess.get_files_at("res://assets/sfx"):
		if file_name.get_extension().to_lower() not in ["wav", "ogg", "mp3"]:
			continue
		var asset_path := "res://assets/sfx/%s" % file_name
		_check(referenced_streams.has(asset_path), "%s has no AudioStreamPlayer in NormalGame/Sounds." % asset_path)


func _get_bus_linear(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0 or AudioServer.is_bus_mute(bus_index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))


func _set_bus_linear(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)
