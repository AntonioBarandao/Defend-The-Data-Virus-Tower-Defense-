extends SceneTree

const PhishingEmailScript := preload("res://Scripts/Enemies/phishing_email.gd")
const CYBER_QUESTION_HUD := preload("res://Scenes/UI/CyberQuestionHud.tscn")
const GAME_SCRIPT := preload("res://Scripts/Gameplay/game.gd")
const TEST_FONT_ROOT := "res://assets/Fonts/naked_power"
const LABEL_COLOR := Color(0.25, 0.78, 1.0, 1.0)
const BUTTON_COLOR := Color(1.0, 0.82, 0.22, 1.0)
const LABEL_FONT_SIZE := 31
const BUTTON_FONT_SIZE := 27

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var test_root := Control.new()
	root.add_child(test_root)

	var colored_label := Label.new()
	colored_label.text = "Colored Label"
	colored_label.add_theme_color_override("font_color", LABEL_COLOR)
	colored_label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	test_root.add_child(colored_label)

	var colored_button := Button.new()
	colored_button.text = "Colored Button"
	colored_button.add_theme_color_override("font_color", BUTTON_COLOR)
	colored_button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	test_root.add_child(colored_button)

	var rich_text := RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.text = "[color=#3fc7ff]Blue[/color] / [color=#ffd23f]Yellow[/color]"
	rich_text.add_theme_font_size_override("normal_font_size", LABEL_FONT_SIZE)
	var original_rich_text := rich_text.text
	test_root.add_child(rich_text)
	await process_frame

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for wave_number in range(1, PhishingEmailScript.GUARANTEED_TRIGGER_WAVE):
		_check(not PhishingEmailScript.should_attack_wave(wave_number, rng), "Phishing triggered before wave 6 ended.")
	for attempt in range(100):
		_check(PhishingEmailScript.should_attack_wave(PhishingEmailScript.GUARANTEED_TRIGGER_WAVE, rng), "Wave 6 phishing was not guaranteed.")
	PhishingEmailScript.apply_font_corruption(test_root, rng, TEST_FONT_ROOT)
	await process_frame

	var label_overlay := colored_label.get_node_or_null("PhishingLetterFontOverlay") as RichTextLabel
	var button_overlay := colored_button.get_node_or_null("PhishingLetterFontOverlay") as RichTextLabel
	_check(label_overlay != null, "Colored labels should receive a per-letter font overlay.")
	_check(button_overlay != null, "Colored buttons should receive a per-letter font overlay.")
	if label_overlay != null:
		_check(label_overlay.text.contains("[font="), "Label overlay did not randomize individual character fonts.")
		_check(label_overlay.get_theme_color("default_color").is_equal_approx(LABEL_COLOR), "Colored label became black during corruption.")
		_check(label_overlay.get_theme_font_size("normal_font_size") == LABEL_FONT_SIZE, "Colored label font size changed during corruption.")
	if button_overlay != null:
		_check(button_overlay.get_theme_color("default_color").is_equal_approx(BUTTON_COLOR), "Colored button became black during corruption.")
		_check(button_overlay.get_theme_font_size("normal_font_size") == BUTTON_FONT_SIZE, "Colored button font size changed during corruption.")
		var review_color := Color(0.72, 1.0, 0.64, 1.0)
		colored_button.add_theme_color_override("font_disabled_color", review_color)
		_check(PhishingEmailScript.set_corrupted_control_font_color(colored_button, review_color), "Corrupted button review color could not be updated.")
		_check(button_overlay.get_theme_color("default_color").is_equal_approx(review_color), "Corrupted button review color was not applied to its randomized letters.")
		_check(colored_button.get_theme_color("font_disabled_color").a == 0.0, "Original button text became visible under its randomized letters.")
	_check(rich_text.text.contains("[color=#3fc7ff]"), "RichText blue color tag was not preserved.")
	_check(rich_text.text.contains("[color=#ffd23f]"), "RichText yellow color tag was not preserved.")
	_check(rich_text.text.contains("[font="), "RichText characters did not receive randomized fonts.")
	_check(rich_text.get_theme_font_size("normal_font_size") == LABEL_FONT_SIZE, "RichText font size changed during corruption.")

	PhishingEmailScript.clear_font_corruption(test_root)
	_check(colored_label.get_node_or_null("PhishingLetterFontOverlay") == null, "Label corruption overlay was not removed after the round.")
	_check(colored_button.get_node_or_null("PhishingLetterFontOverlay") == null, "Button corruption overlay was not removed after the round.")
	_check(colored_label.get_theme_color("font_color").is_equal_approx(LABEL_COLOR), "Colored label did not restore its original color.")
	_check(colored_button.get_theme_color("font_color").is_equal_approx(BUTTON_COLOR), "Colored button did not restore its original color.")
	_check(colored_label.get_theme_font_size("font_size") == LABEL_FONT_SIZE, "Colored label did not retain its original font size.")
	_check(colored_button.get_theme_font_size("font_size") == BUTTON_FONT_SIZE, "Colored button did not retain its original font size.")
	_check(rich_text.bbcode_enabled and rich_text.text == original_rich_text, "RichText did not restore its exact pre-round content.")

	test_root.queue_free()
	await process_frame

	var question_hud := CYBER_QUESTION_HUD.instantiate() as CyberQuestionHUD
	question_hud.demo_question_animation_enabled = false
	root.add_child(question_hud)
	await process_frame
	question_hud.show_wave_question(1)
	question_hud.call("_start_question", "easy")
	await process_frame
	var answer_button := question_hud.get_node("Root/QuestionPanel/Margin/Content/QuestionView/AnswerButtons/AnswerButton1") as Button
	var answer_font_size := answer_button.get_theme_font_size("font_size")
	question_hud.begin_phishing_effect()
	PhishingEmailScript.apply_font_corruption(question_hud, rng, TEST_FONT_ROOT)
	_check(answer_button.get_node_or_null("PhishingLetterFontOverlay") != null, "Question round did not receive the phishing font effect.")
	question_hud.call("_show_wrong_answer_review", 0)
	await question_hud.question_solved
	_check(answer_button.get_node_or_null("PhishingLetterFontOverlay") != null, "Question round ending removed the active phishing effect.")
	question_hud.show_wave_question(2)
	_check(answer_button.get_node_or_null("PhishingLetterFontOverlay") != null, "Opening the next question removed the active phishing effect.")
	question_hud.end_phishing_effect()
	_check(answer_button.get_node_or_null("PhishingLetterFontOverlay") == null, "Phishing overlays remained after all viruses were cleared.")
	_check(answer_button.get_theme_font_size("font_size") == answer_font_size, "Question round cleanup changed the answer font size.")

	var game := Node2D.new()
	game.set_script(GAME_SCRIPT)
	game.set("_question_hud", question_hud)
	game.set("_phishing_effect_active", true)
	question_hud.begin_phishing_effect()
	var tracked_viruses := game.get("_active_viruses") as Array
	var live_follow := PathFollow2D.new()
	tracked_viruses.append(live_follow)
	game.call("_end_phishing_effect_if_viruses_cleared")
	_check(question_hud.is_phishing_effect_active(), "A live virus did not preserve the phishing effect.")
	tracked_viruses.clear()
	live_follow.free()
	game.call("_end_phishing_effect_if_viruses_cleared")
	_check(not question_hud.is_phishing_effect_active(), "Clearing the final virus did not end the phishing effect.")
	var defeat_follow := PathFollow2D.new()
	tracked_viruses.append(defeat_follow)
	game.set("_phishing_effect_active", true)
	question_hud.begin_phishing_effect()
	PhishingEmailScript.apply_font_corruption(question_hud, rng, TEST_FONT_ROOT)
	game.call("_clear_phishing_effect")
	_check(not question_hud.is_phishing_effect_active(), "Defeat cleanup did not stop phishing while viruses remained active.")
	_check(answer_button.get_node_or_null("PhishingLetterFontOverlay") == null, "Defeat cleanup left corrupted fonts on screen.")
	tracked_viruses.clear()
	defeat_follow.free()
	game.free()

	question_hud.queue_free()
	await process_frame

	if not _failed:
		print("Phishing font corruption validation passed.")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
