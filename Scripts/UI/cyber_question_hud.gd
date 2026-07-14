class_name CyberQuestionHUD
extends CanvasLayer

signal question_solved(reward: int)
signal cyberbucks_changed(amount: int)
signal phishing_decoy_selected

const PhishingEmailScript := preload("res://Scripts/Enemies/phishing_email.gd")
const CATEGORY_CYBERSECURITY := "cybersecurity"
const CATEGORY_NETWORKING := "networking"
const DIFFICULTY_EASY := "easy"
const DIFFICULTY_MEDIUM := "medium"
const DIFFICULTY_HARD := "hard"
const REWARDS := {
	DIFFICULTY_EASY: 10,
	DIFFICULTY_MEDIUM: 25,
	DIFFICULTY_HARD: 50
}
const DEMO_WRONG_TEXT := "Wrong Answer for this wave ..."
const DEMO_WRONG_FEEDBACK_SECONDS := 3.0
const DEMO_PANEL_EXIT_DISTANCE := 360.0
const STARTING_CYBERBUCKS := 500
const ANSWER_CORRECT_REVIEW_MODULATE := Color(0.58, 1.0, 0.68, 1.0)
const ANSWER_FADED_REVIEW_MODULATE := Color(0.46, 0.46, 0.46, 0.34)
const ANSWER_CORRECT_REVIEW_FONT_COLOR := Color(0.72, 1.0, 0.64, 1.0)
const ANSWER_FADED_REVIEW_FONT_COLOR := Color(0.72, 0.76, 0.82, 0.42)
const QUESTIONS := {
	CATEGORY_CYBERSECURITY: {
		DIFFICULTY_EASY: [
			{
				"prompt": "Which practice helps protect an account if a password is stolen?",
				"answers": ["Enable multi-factor authentication", "Reuse one simple password", "Share passwords in chat", "Turn off software updates"],
				"correct": 0
			}
		],
		DIFFICULTY_MEDIUM: [
			{
				"prompt": "What should you do before opening an unexpected email attachment?",
				"answers": ["Verify the sender and reason first", "Open it quickly", "Forward it to everyone", "Disable antivirus alerts"],
				"correct": 0
			}
		],
		DIFFICULTY_HARD: [
			{
				"prompt": "Why should passwords be hashed before storage?",
				"answers": ["To verify them without storing the original password", "To make them easier to read", "To remove the need for login checks", "To send them faster over Wi-Fi"],
				"correct": 0
			}
		]
	},
	CATEGORY_NETWORKING: {
		DIFFICULTY_EASY: [
			{
				"prompt": "Which device commonly directs traffic between different networks?",
				"answers": ["Router", "Keyboard", "Monitor", "Headphones"],
				"correct": 0
			}
		],
		DIFFICULTY_MEDIUM: [
			{
				"prompt": "Which protocol is used for encrypted web browsing?",
				"answers": ["HTTPS", "FTP", "Telnet", "HTTP only"],
				"correct": 0
			}
		],
		DIFFICULTY_HARD: [
			{
				"prompt": "What information does a firewall rule commonly inspect before allowing traffic?",
				"answers": ["IP addresses, ports, and protocols", "Screen brightness", "Mouse speed", "Keyboard layout"],
				"correct": 0
			}
		]
	}
}

@export var demo_question_animation_enabled := false
@export var demo_question_reward := 200
@export_range(160.0, 1200.0, 1.0) var demo_panel_slide_distance := 760.0

var cyberbucks := STARTING_CYBERBUCKS
var _selected_category := CATEGORY_CYBERSECURITY
var _current_wave := 0
var _current_reward := 0
var _current_question: Dictionary = {}
var _answer_locked := false
var _panel_rest_offsets := Vector4.ZERO
var _panel_rest_scale := Vector2.ONE
var _panel_rest_modulate := Color.WHITE
var _panel_tween: Tween
var _panel_shake_origin_offsets := Vector4.ZERO
var _panel_shake_active := false
var _control_rest_scales: Dictionary = {}
var _control_rest_modulates: Dictionary = {}
var _control_tweens: Dictionary = {}
var _phishing_rng := RandomNumberGenerator.new()
var _phishing_decoy_answer_index := -1

@onready var _question_panel: PanelContainer = $Root/QuestionPanel
@onready var _selection_view: VBoxContainer = $Root/QuestionPanel/Margin/Content/SelectionView
@onready var _question_view: VBoxContainer = $Root/QuestionPanel/Margin/Content/QuestionView
@onready var _cybersecurity_button: Button = $Root/QuestionPanel/Margin/Content/SelectionView/CategoryButtons/CybersecurityButton
@onready var _networking_button: Button = $Root/QuestionPanel/Margin/Content/SelectionView/CategoryButtons/NetworkingButton
@onready var _easy_button: Button = $Root/QuestionPanel/Margin/Content/SelectionView/DifficultyRow/EasyCard/EasyButton
@onready var _medium_button: Button = $Root/QuestionPanel/Margin/Content/SelectionView/DifficultyRow/MediumCard/MediumButton
@onready var _hard_button: Button = $Root/QuestionPanel/Margin/Content/SelectionView/DifficultyRow/HardCard/HardButton
@onready var _easy_reward_label: Label = $Root/QuestionPanel/Margin/Content/SelectionView/DifficultyRow/EasyCard/EasyReward/Amount
@onready var _medium_reward_label: Label = $Root/QuestionPanel/Margin/Content/SelectionView/DifficultyRow/MediumCard/MediumReward/Amount
@onready var _hard_reward_label: Label = $Root/QuestionPanel/Margin/Content/SelectionView/DifficultyRow/HardCard/HardReward/Amount
@onready var _question_label: Label = $Root/QuestionPanel/Margin/Content/QuestionView/QuestionText
@onready var _current_reward_label: Label = $Root/QuestionPanel/Margin/Content/QuestionView/CurrentReward/Amount
@onready var _answer_buttons := [
	$Root/QuestionPanel/Margin/Content/QuestionView/AnswerButtons/AnswerButton1,
	$Root/QuestionPanel/Margin/Content/QuestionView/AnswerButtons/AnswerButton2,
	$Root/QuestionPanel/Margin/Content/QuestionView/AnswerButtons/AnswerButton3,
	$Root/QuestionPanel/Margin/Content/QuestionView/AnswerButtons/AnswerButton4
]
@onready var _feedback_label: Label = $Root/QuestionPanel/Margin/Content/QuestionView/FeedbackLabel
@onready var _back_button: Button = $Root/QuestionPanel/Margin/Content/QuestionView/BackButton


func _ready() -> void:
	_phishing_rng.randomize()
	_question_panel.hide()
	_panel_rest_offsets = _get_panel_offsets()
	_panel_rest_scale = _question_panel.scale
	_panel_rest_modulate = _question_panel.modulate
	_cache_animated_control_state()
	_easy_reward_label.text = "+%d" % _get_question_reward(DIFFICULTY_EASY)
	_medium_reward_label.text = "+%d" % _get_question_reward(DIFFICULTY_MEDIUM)
	_hard_reward_label.text = "+%d" % _get_question_reward(DIFFICULTY_HARD)
	_update_cyberbuck_amount()
	_select_category(CATEGORY_CYBERSECURITY)

	_cybersecurity_button.pressed.connect(Callable(self, "_select_category").bind(CATEGORY_CYBERSECURITY))
	_networking_button.pressed.connect(Callable(self, "_select_category").bind(CATEGORY_NETWORKING))
	_easy_button.pressed.connect(Callable(self, "_start_question").bind(DIFFICULTY_EASY))
	_medium_button.pressed.connect(Callable(self, "_start_question").bind(DIFFICULTY_MEDIUM))
	_hard_button.pressed.connect(Callable(self, "_start_question").bind(DIFFICULTY_HARD))
	_back_button.pressed.connect(Callable(self, "_show_selection_view"))
	for index in _answer_buttons.size():
		_answer_buttons[index].pressed.connect(Callable(self, "_answer_selected").bind(index))


func show_wave_question(wave_number: int) -> void:
	_current_wave = wave_number
	_answer_locked = false
	_show_selection_view()
	_question_panel.show()
	if demo_question_animation_enabled:
		_animate_panel_entry()
		_animate_selection_controls()


func add_cyberbucks(amount: int) -> void:
	cyberbucks += max(0, amount)
	_update_cyberbuck_amount()


func get_cyberbucks() -> int:
	return cyberbucks


func can_spend_cyberbucks(amount: int) -> bool:
	return cyberbucks >= maxi(0, amount)


func spend_cyberbucks(amount: int) -> bool:
	var cost := maxi(0, amount)
	if cyberbucks < cost:
		return false

	cyberbucks -= cost
	_update_cyberbuck_amount()
	return true


func reset_cyberbucks() -> void:
	cyberbucks = STARTING_CYBERBUCKS
	_update_cyberbuck_amount()


func _select_category(category: String) -> void:
	_selected_category = category
	var cyber_selected := category == CATEGORY_CYBERSECURITY
	_cybersecurity_button.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0, 1.0) if cyber_selected else Color.WHITE)
	_networking_button.add_theme_color_override("font_color", Color(1.0, 0.82, 0.22, 1.0) if not cyber_selected else Color.WHITE)


func _show_selection_view() -> void:
	_feedback_label.text = ""
	_answer_locked = false
	_phishing_decoy_answer_index = -1
	_reset_answer_button_review_state()
	_back_button.disabled = false
	_selection_view.show()
	_question_view.hide()
	if demo_question_animation_enabled and _question_panel.visible:
		_animate_selection_controls()


func _start_question(difficulty: String) -> void:
	var question_set := QUESTIONS[_selected_category][difficulty] as Array
	if question_set.is_empty():
		return

	var question_index: int = max(0, _current_wave - 1) % question_set.size()
	_current_question = question_set[question_index] as Dictionary
	_current_reward = _get_question_reward(difficulty)
	var answers := (_current_question["answers"] as Array).duplicate()
	var correct_index := int(_current_question["correct"])
	_phishing_decoy_answer_index = -1
	if PhishingEmailScript.should_attack_wave(_current_wave, _phishing_rng):
		_phishing_decoy_answer_index = _apply_phishing_decoy(answers, correct_index)
	_question_label.text = String(_current_question["prompt"])
	_current_reward_label.text = "+%d CyberBucks" % _current_reward
	_feedback_label.text = ""
	_answer_locked = false

	for index in _answer_buttons.size():
		var button := _answer_buttons[index] as Button
		button.disabled = false
		_reset_answer_button_visual(button)
		if index < answers.size():
			button.text = String(answers[index])
			button.show()
		else:
			button.hide()

	_selection_view.hide()
	_question_view.show()
	if demo_question_animation_enabled:
		_animate_question_view_intro()


func _answer_selected(answer_index: int) -> void:
	if _current_question.is_empty() or _answer_locked:
		return

	var correct_index := int(_current_question["correct"])
	if answer_index != correct_index:
		_answer_locked = true
		if answer_index == _phishing_decoy_answer_index:
			_trigger_phishing_decoy_failure()
		await _show_wrong_answer_review(correct_index)
		return

	_answer_locked = true
	_phishing_decoy_answer_index = -1
	for button in _answer_buttons:
		(button as Button).disabled = true

	add_cyberbucks(_current_reward)
	if demo_question_animation_enabled:
		await _show_demo_correct_feedback()
		await _animate_panel_exit()
	else:
		_feedback_label.text = ""

	_question_panel.hide()
	_restore_panel_transform()
	question_solved.emit(_current_reward)


func _show_wrong_answer_review(correct_index: int) -> void:
	_phishing_decoy_answer_index = -1
	_set_question_interactable(false)
	_apply_wrong_answer_review_state(correct_index)

	if demo_question_animation_enabled:
		_show_demo_wrong_feedback()
	else:
		_feedback_label.text = DEMO_WRONG_TEXT
		_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.38, 0.24, 1.0))
		_play_feedback_fade(_feedback_label, DEMO_WRONG_FEEDBACK_SECONDS, true)

	await get_tree().create_timer(DEMO_WRONG_FEEDBACK_SECONDS).timeout
	if demo_question_animation_enabled:
		await _animate_panel_exit()

	_question_panel.hide()
	_restore_panel_transform()
	_reset_answer_button_review_state()
	_back_button.disabled = false
	question_solved.emit(0)


func _set_question_interactable(interactable: bool) -> void:
	for button in _answer_buttons:
		(button as Button).disabled = not interactable
	_back_button.disabled = not interactable


func _apply_wrong_answer_review_state(correct_index: int) -> void:
	for index in _answer_buttons.size():
		var button := _answer_buttons[index] as Button
		if not button.visible:
			continue

		if index == correct_index:
			button.modulate = ANSWER_CORRECT_REVIEW_MODULATE
			button.add_theme_color_override("font_color", ANSWER_CORRECT_REVIEW_FONT_COLOR)
			button.add_theme_color_override("font_disabled_color", ANSWER_CORRECT_REVIEW_FONT_COLOR)
		else:
			button.modulate = ANSWER_FADED_REVIEW_MODULATE
			button.add_theme_color_override("font_color", ANSWER_FADED_REVIEW_FONT_COLOR)
			button.add_theme_color_override("font_disabled_color", ANSWER_FADED_REVIEW_FONT_COLOR)


func _reset_answer_button_review_state() -> void:
	for button_value in _answer_buttons:
		var button := button_value as Button
		_reset_answer_button_visual(button)


func _reset_answer_button_visual(button: Button) -> void:
	if button == null:
		return

	button.modulate = _get_control_rest_modulate(button)
	button.remove_theme_color_override("font_color")
	button.remove_theme_color_override("font_disabled_color")


func _apply_phishing_decoy(answers: Array, correct_index: int) -> int:
	var wrong_indices: Array[int] = []
	for index in answers.size():
		if index != correct_index:
			wrong_indices.append(index)

	if wrong_indices.is_empty():
		return -1

	var decoy_index := wrong_indices[_phishing_rng.randi_range(0, wrong_indices.size() - 1)]
	var correct_answer := String(answers[correct_index])
	answers[decoy_index] = PhishingEmailScript.make_subtle_decoy(correct_answer, _phishing_rng)
	return decoy_index


func _trigger_phishing_decoy_failure() -> void:
	_phishing_decoy_answer_index = -1
	PhishingEmailScript.apply_font_corruption(get_tree().root, _phishing_rng)
	phishing_decoy_selected.emit()


func _update_cyberbuck_amount() -> void:
	cyberbucks_changed.emit(cyberbucks)


func _get_question_reward(difficulty: String) -> int:
	if demo_question_animation_enabled:
		return demo_question_reward

	return int(REWARDS[difficulty])


func _animate_panel_entry() -> void:
	if _panel_tween != null:
		_panel_tween.kill()

	_set_panel_animation_offset(Vector2(demo_panel_slide_distance, 0.0))
	_question_panel.scale = _panel_rest_scale
	_question_panel.modulate = _with_alpha(_panel_rest_modulate, 0.0)

	_panel_tween = create_tween()
	_panel_tween.set_parallel(true)
	_panel_tween.tween_method(Callable(self, "_set_panel_animation_offset"), Vector2(demo_panel_slide_distance, 0.0), Vector2.ZERO, 0.48).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_panel_tween.tween_property(_question_panel, "modulate:a", _panel_rest_modulate.a, 0.22)
	_panel_tween.set_parallel(false)
	_panel_tween.tween_callback(Callable(self, "_restore_panel_transform"))


func _animate_panel_exit() -> void:
	if _panel_tween != null:
		_panel_tween.kill()

	_question_panel.scale = _panel_rest_scale
	_panel_tween = create_tween()
	_panel_tween.set_parallel(true)
	_panel_tween.tween_method(Callable(self, "_set_panel_animation_offset"), Vector2.ZERO, Vector2(-DEMO_PANEL_EXIT_DISTANCE, 0.0), 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_panel_tween.tween_property(_question_panel, "modulate:a", 0.0, 0.2)
	await _panel_tween.finished


func _animate_selection_controls() -> void:
	var controls: Array[Control] = [
		_cybersecurity_button,
		_networking_button,
		_easy_button.get_parent() as Control,
		_medium_button.get_parent() as Control,
		_hard_button.get_parent() as Control
	]
	for index in controls.size():
		_pop_control_from_right(controls[index], float(index) * 0.07)


func _animate_question_view_intro() -> void:
	var controls: Array[Control] = [
		_question_label,
		_current_reward_label.get_parent() as Control,
		_answer_buttons[0],
		_answer_buttons[1],
		_answer_buttons[2],
		_answer_buttons[3],
		_back_button
	]
	for index in controls.size():
		var control := controls[index]
		if control.visible:
			_pop_control_from_right(control, float(index) * 0.055)


func _pop_control_from_right(control: Control, delay: float) -> void:
	_kill_control_tween(control)

	var target_scale := _get_control_rest_scale(control)
	var target_modulate := _get_control_rest_modulate(control)
	control.scale = target_scale
	control.modulate = _with_alpha(target_modulate, 0.0)

	var tween := create_tween()
	_control_tweens[control] = tween
	tween.tween_interval(delay)
	tween.tween_property(control, "modulate:a", target_modulate.a, 0.16)
	tween.tween_callback(Callable(self, "_restore_control_transform").bind(control))


func _show_demo_wrong_feedback() -> void:
	_feedback_label.text = DEMO_WRONG_TEXT
	_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.38, 0.24, 1.0))
	_play_feedback_fade(_feedback_label, DEMO_WRONG_FEEDBACK_SECONDS, true)

	if _panel_tween != null:
		_panel_tween.kill()

	if _panel_shake_active:
		_finish_panel_shake()

	_panel_shake_origin_offsets = _get_panel_offsets()
	_panel_shake_active = true
	_panel_tween = create_tween()
	_panel_tween.tween_method(Callable(self, "_set_panel_shake_offset"), 0.0, -14.0, 0.045)
	_panel_tween.tween_method(Callable(self, "_set_panel_shake_offset"), -14.0, 12.0, 0.045)
	_panel_tween.tween_method(Callable(self, "_set_panel_shake_offset"), 12.0, -7.0, 0.04)
	_panel_tween.tween_method(Callable(self, "_set_panel_shake_offset"), -7.0, 0.0, 0.06)
	_panel_tween.tween_callback(Callable(self, "_finish_panel_shake"))


func _show_demo_correct_feedback() -> void:
	_feedback_label.text = "+%d Cyber Bucks" % _current_reward
	_feedback_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.24, 1.0))
	_kill_control_tween(_feedback_label)

	var rest_scale := _get_control_rest_scale(_feedback_label)
	var rest_modulate := _get_control_rest_modulate(_feedback_label)
	_feedback_label.scale = rest_scale
	_feedback_label.modulate = _with_alpha(rest_modulate, 0.0)
	var tween := create_tween()
	_control_tweens[_feedback_label] = tween
	tween.tween_property(_feedback_label, "modulate:a", rest_modulate.a, 0.12)
	tween.tween_interval(0.58)
	tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.16)
	tween.tween_callback(Callable(self, "_restore_control_transform").bind(_feedback_label))
	await tween.finished


func _cache_animated_control_state() -> void:
	for control in _get_animated_controls():
		_control_rest_scales[control] = control.scale
		_control_rest_modulates[control] = control.modulate


func _get_animated_controls() -> Array[Control]:
	return [
		_cybersecurity_button,
		_networking_button,
		_easy_button.get_parent() as Control,
		_medium_button.get_parent() as Control,
		_hard_button.get_parent() as Control,
		_question_label,
		_current_reward_label.get_parent() as Control,
		_answer_buttons[0],
		_answer_buttons[1],
		_answer_buttons[2],
		_answer_buttons[3],
		_feedback_label,
		_back_button
	]


func _restore_panel_transform() -> void:
	_panel_shake_active = false
	_apply_panel_offsets(_panel_rest_offsets)
	_question_panel.scale = _panel_rest_scale
	_question_panel.modulate = _panel_rest_modulate


func _get_panel_offsets() -> Vector4:
	return Vector4(_question_panel.offset_left, _question_panel.offset_top, _question_panel.offset_right, _question_panel.offset_bottom)


func _apply_panel_offsets(offsets: Vector4) -> void:
	_question_panel.offset_left = offsets.x
	_question_panel.offset_top = offsets.y
	_question_panel.offset_right = offsets.z
	_question_panel.offset_bottom = offsets.w


func _set_panel_animation_offset(offset: Vector2) -> void:
	_apply_panel_offsets(Vector4(
		_panel_rest_offsets.x + offset.x,
		_panel_rest_offsets.y + offset.y,
		_panel_rest_offsets.z + offset.x,
		_panel_rest_offsets.w + offset.y
	))


func _set_panel_shake_offset(offset_x: float) -> void:
	_apply_panel_offsets(Vector4(
		_panel_shake_origin_offsets.x + offset_x,
		_panel_shake_origin_offsets.y,
		_panel_shake_origin_offsets.z + offset_x,
		_panel_shake_origin_offsets.w
	))


func _finish_panel_shake() -> void:
	_apply_panel_offsets(_panel_shake_origin_offsets)
	_panel_shake_active = false


func _restore_control_transform(control: Control) -> void:
	control.scale = _get_control_rest_scale(control)
	control.modulate = _get_control_rest_modulate(control)
	_control_tweens.erase(control)


func _play_feedback_fade(control: Control, visible_seconds := 0.0, clear_text_after := false) -> void:
	_kill_control_tween(control)

	var rest_scale := _get_control_rest_scale(control)
	var rest_modulate := _get_control_rest_modulate(control)
	control.scale = rest_scale
	control.modulate = _with_alpha(rest_modulate, 0.0)

	var tween := create_tween()
	_control_tweens[control] = tween
	tween.tween_property(control, "modulate:a", rest_modulate.a, 0.12)
	if visible_seconds > 0.0:
		tween.tween_interval(visible_seconds)
		tween.tween_property(control, "modulate:a", 0.0, 0.18)
		tween.tween_callback(Callable(self, "_finish_timed_feedback").bind(control, clear_text_after))
	else:
		tween.tween_callback(Callable(self, "_restore_control_transform").bind(control))


func _finish_timed_feedback(control: Control, clear_text_after: bool) -> void:
	control.scale = _get_control_rest_scale(control)
	control.modulate = _with_alpha(_get_control_rest_modulate(control), 0.0)
	if clear_text_after and control is Label:
		(control as Label).text = ""
	_control_tweens.erase(control)


func _kill_control_tween(control: Control) -> void:
	if not _control_tweens.has(control):
		return

	var tween := _control_tweens[control] as Tween
	if tween != null:
		tween.kill()
	_control_tweens.erase(control)


func _get_control_rest_scale(control: Control) -> Vector2:
	if _control_rest_scales.has(control):
		return _control_rest_scales[control] as Vector2

	_control_rest_scales[control] = control.scale
	return control.scale


func _get_control_rest_modulate(control: Control) -> Color:
	if _control_rest_modulates.has(control):
		return _control_rest_modulates[control] as Color

	_control_rest_modulates[control] = control.modulate
	return control.modulate


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
