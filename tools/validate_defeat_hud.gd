extends SceneTree

const DEFEAT_HUD_SCENE := preload("res://Scenes/UI/DefeatHUD.tscn")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var hud := DEFEAT_HUD_SCENE.instantiate() as DefeatHUD
	root.add_child(hud)
	await process_frame

	var overlay := hud.get_node("Root/DimOverlay") as ColorRect
	var animation := hud.get_node("Root/AnimatedDisplay") as AnimatedSprite2D
	var play_again := hud.get_node("Root/PlayAgainButton") as Button
	var quit_game := hud.get_node("Root/QuitGameButton") as Button
	var frames := animation.sprite_frames

	_check(frames.get_frame_count(&"defeat") == 145, "Defeat animation must contain 145 frames.")
	_check(is_equal_approx(frames.get_animation_speed(&"defeat"), 24.0), "Defeat animation must play at the source 24 FPS.")
	_check(not frames.get_animation_loop(&"defeat"), "Defeat animation must not loop.")

	paused = true
	hud.show_defeat()
	_check(hud.get_node("Root").visible, "Defeat HUD did not become visible.")
	_check(hud.get_node("Root").mouse_filter == Control.MOUSE_FILTER_STOP, "Defeat HUD does not block gameplay input.")
	_check(not play_again.visible and not quit_game.visible, "Defeat actions appeared before the animation.")

	await animation.animation_finished
	await process_frame
	_check(overlay.modulate.a > 0.99, "Defeat dim overlay did not finish fading in.")
	_check(animation.visible and animation.modulate.a > 0.99, "Defeat animation was hidden after finishing.")
	_check(animation.frame == frames.get_frame_count(&"defeat") - 1, "Defeat animation did not hold its exact last frame.")
	_check(not animation.is_playing(), "Defeat animation continued playing after its last frame.")

	await create_timer(0.42, true, false, true).timeout
	_check(play_again.visible and not play_again.disabled, "Play Again did not appear first.")
	_check(not quit_game.visible, "Quit Game appeared before its stagger delay.")

	await create_timer(0.25, true, false, true).timeout
	_check(quit_game.visible and not quit_game.disabled, "Quit Game did not appear second.")

	paused = false
	hud.queue_free()
	await process_frame
	if _failures.is_empty():
		print("Defeat HUD validation passed.")
	quit(0 if _failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failures.append(message)
	push_error(message)
