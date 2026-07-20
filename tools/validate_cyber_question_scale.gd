extends SceneTree

const HUD_SCENE := preload("res://Scenes/UI/CyberQuestionHud.tscn")
const TOLERANCE := 0.01
const EXPECTED_BUTTON_FONT_SIZES := {
	"Root/QuestionPanel/Margin/Content/SelectionView/CategoryButtons/CybersecurityButton": 40,
	"Root/QuestionPanel/Margin/Content/SelectionView/CategoryButtons/NetworkingButton": 40,
	"Root/QuestionPanel/Margin/Content/SelectionView/DifficultyRow/EasyCard/EasyButton": 30,
	"Root/QuestionPanel/Margin/Content/SelectionView/DifficultyRow/MediumCard/MediumButton": 30,
	"Root/QuestionPanel/Margin/Content/SelectionView/DifficultyRow/HardCard/HardButton": 30,
	"Root/QuestionPanel/Margin/Content/QuestionView/AnswerButtons/AnswerButton1": 28,
	"Root/QuestionPanel/Margin/Content/QuestionView/AnswerButtons/AnswerButton2": 28,
	"Root/QuestionPanel/Margin/Content/QuestionView/AnswerButtons/AnswerButton3": 28,
	"Root/QuestionPanel/Margin/Content/QuestionView/AnswerButtons/AnswerButton4": 28,
	"Root/QuestionPanel/Margin/Content/QuestionView/BackButton": 26,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var reference_hud := HUD_SCENE.instantiate() as CyberQuestionHUD
	var authored_panel := reference_hud.get_node("Root/QuestionPanel") as PanelContainer
	var authored_scale := authored_panel.scale
	reference_hud.free()

	var hud := HUD_SCENE.instantiate() as CyberQuestionHUD
	root.add_child(hud)
	await process_frame

	var panel := hud.get_node("Root/QuestionPanel") as PanelContainer
	var input_blocker := hud.get_node("Root/InputBlocker") as ColorRect
	var content := panel.get_node("Margin/Content") as VBoxContainer
	var expected_scale := authored_scale * hud.ui_scale_multiplier
	var expected_pivot := Vector2(panel.size.x * 0.5, panel.size.y)
	if authored_scale.distance_to(Vector2(1.25, 1.25)) > TOLERANCE:
		push_error("Cyber question HUD does not show the 25% scale in the authored scene.")
		quit(1)
		return
	if panel.size.distance_to(Vector2(1280.0, 293.0)) > TOLERANCE:
		push_error("Cyber question selection panel does not preserve the authored 1280x293 layout.")
		quit(1)
		return
	if not is_equal_approx(panel.anchor_left, 0.5) or not is_equal_approx(panel.anchor_right, 0.5) or not is_equal_approx(panel.anchor_top, 1.0) or not is_equal_approx(panel.anchor_bottom, 1.0):
		push_error("Cyber question panel is not anchored to the bottom center.")
		quit(1)
		return
	if content.alignment != BoxContainer.ALIGNMENT_CENTER:
		push_error("Cyber question content is not centered inside the panel.")
		quit(1)
		return
	if hud.layer < 3000:
		push_error("Cyber question HUD is not above the gameplay HUD layers.")
		quit(1)
		return
	if input_blocker.visible or input_blocker.mouse_filter != Control.MOUSE_FILTER_STOP:
		push_error("Cyber question input blocker is not configured as an inactive full-screen shield.")
		quit(1)
		return
	if panel.z_index <= input_blocker.z_index:
		push_error("Cyber question panel must render and receive input above its input blocker.")
		quit(1)
		return
	if panel.scale.distance_to(expected_scale) > TOLERANCE:
		push_error("Cyber question HUD did not apply the 25% UI scale.")
		quit(1)
		return
	if panel.pivot_offset.distance_to(expected_pivot) > TOLERANCE:
		push_error("Cyber question HUD is not scaling upward from its bottom-center pivot.")
		quit(1)
		return
	for node_path: String in EXPECTED_BUTTON_FONT_SIZES:
		var button := hud.get_node(node_path) as Button
		var expected_font_size: int = EXPECTED_BUTTON_FONT_SIZES[node_path]
		if button.get_theme_font_size("font_size") != expected_font_size:
			push_error("Cyber question button font size is incorrect: %s" % node_path)
			quit(1)
			return

	hud.show_wave_question(1)
	await process_frame
	await process_frame
	if not input_blocker.visible or not hud.is_question_open():
		push_error("Cyber question input blocker did not activate with the questionnaire.")
		quit(1)
		return
	var selection_height := panel.size.y
	var selection_bottom := panel.get_global_rect().end.y
	hud.call("_start_question", "easy")
	await process_frame
	await process_frame
	var expanded_rect := panel.get_global_rect()
	var back_button := hud.get_node("Root/QuestionPanel/Margin/Content/QuestionView/BackButton") as Button
	if panel.size.y <= selection_height:
		push_error("Cyber question panel did not expand for the question view.")
		quit(1)
		return
	if absf(expanded_rect.end.y - selection_bottom) > TOLERANCE:
		push_error("Cyber question panel did not remain pinned to the bottom while expanding.")
		quit(1)
		return
	if back_button.get_global_rect().end.y > expanded_rect.end.y + TOLERANCE:
		push_error("Change Difficulty is cropped outside the expanded question panel.")
		quit(1)
		return

	print("Cyber question HUD layout and typography validation passed.")
	quit(0)
