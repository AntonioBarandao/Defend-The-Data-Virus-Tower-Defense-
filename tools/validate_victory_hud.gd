extends SceneTree

const VICTORY_HUD_SCENE := "res://Scenes/UI/VictoryHUD.tscn"
const BASE_GAME_SCENE := "res://Scenes/Gameplay/Cutscene_Test_Game.tscn"
const VICTORY_FRAMES := "res://assets/UI/Victory/DefendedTheDataFrames.tres"
const VICTORY_ANIMATION := &"victory"
const EXPECTED_FRAME_COUNT := 73
const EXPECTED_FPS := 24.0

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sprite_frames := load(VICTORY_FRAMES) as SpriteFrames
	_check(sprite_frames != null, "Victory SpriteFrames could not be loaded.")
	if sprite_frames != null:
		_check(sprite_frames.has_animation(VICTORY_ANIMATION), "Victory animation is missing.")
		if sprite_frames.has_animation(VICTORY_ANIMATION):
			_check(
				sprite_frames.get_frame_count(VICTORY_ANIMATION) == EXPECTED_FRAME_COUNT,
				"Victory animation must have %d frames." % EXPECTED_FRAME_COUNT
			)
			_check(
				is_equal_approx(
					sprite_frames.get_animation_speed(VICTORY_ANIMATION),
					EXPECTED_FPS
				),
				"Victory animation must run at %.0f FPS." % EXPECTED_FPS
			)
			_check(
				not sprite_frames.get_animation_loop(VICTORY_ANIMATION),
				"Victory animation must stop on its final frame."
			)

	var victory_hud_scene := load(VICTORY_HUD_SCENE) as PackedScene
	_check(victory_hud_scene != null, "VictoryHUD scene could not be loaded.")
	var base_scene := load(BASE_GAME_SCENE) as PackedScene
	_check(base_scene != null, "Cutscene test game could not be loaded.")
	if base_scene != null:
		var base_game := base_scene.instantiate()
		_check(base_game.get_node_or_null("VictoryHUD") != null, "Base gameplay scene is missing VictoryHUD.")
		base_game.free()

	if _failed:
		quit(1)
		return
	print("Victory HUD validation passed.")
	quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
