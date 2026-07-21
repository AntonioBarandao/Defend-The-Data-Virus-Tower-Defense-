class_name PhishingEmail
extends Node2D

const GROUP_NAME := "PHISHING_EMAIL"
const START_WAVE := 6
const TRIGGER_CHANCE := 0.5
const DEFAULT_FONT_ROOT := "res://assets/Fonts"
const FONT_EXTENSIONS := ["otf", "ttf"]
const FONT_OVERLAY_NAME := "PhishingLetterFontOverlay"
const FONT_OVERLAY_META := "phishing_letter_font_overlay"
const FONT_ORIGINAL_STATE_META := "phishing_font_original_state"
const HIDDEN_TEXT_COLOR_NAMES := [
	"font_color",
	"font_pressed_color",
	"font_hover_color",
	"font_hover_pressed_color",
	"font_focus_color",
	"font_disabled_color",
	"font_readonly_color",
	"font_uneditable_color",
	"font_placeholder_color",
	"caret_color",
	"selection_color"
]


func _ready() -> void:
	add_to_group(GROUP_NAME)


static func should_attack_wave(wave_number: int, rng: RandomNumberGenerator) -> bool:
	if wave_number < START_WAVE:
		return false

	return rng.randf() < TRIGGER_CHANCE


static func make_subtle_decoy(correct_answer: String, rng: RandomNumberGenerator) -> String:
	if correct_answer.length() <= 1:
		return correct_answer

	var removable_indices: Array[int] = []
	for index in correct_answer.length():
		var character := correct_answer.substr(index, 1)
		if character.strip_edges() == "":
			continue
		removable_indices.append(index)

	if removable_indices.is_empty():
		return correct_answer

	var remove_index := removable_indices[rng.randi_range(0, removable_indices.size() - 1)]
	return correct_answer.substr(0, remove_index) + correct_answer.substr(remove_index + 1)


static func apply_font_corruption(root: Node, rng: RandomNumberGenerator, fonts_root: String = DEFAULT_FONT_ROOT) -> void:
	if root == null:
		return

	var font_paths := load_font_paths(fonts_root)
	if font_paths.is_empty():
		return

	_apply_font_corruption_recursive(root, font_paths, rng)


static func clear_font_corruption(root: Node) -> void:
	if root == null:
		return

	_clear_font_corruption_recursive(root)


static func set_corrupted_control_font_color(control: Control, color: Color) -> bool:
	if control == null or not control.has_meta(FONT_ORIGINAL_STATE_META):
		return false

	var original_state := control.get_meta(FONT_ORIGINAL_STATE_META) as Dictionary
	if String(original_state.get("kind", "")) != "control_overlay":
		return false

	var overlay := control.get_node_or_null(FONT_OVERLAY_NAME) as RichTextLabel
	if overlay == null:
		return false

	overlay.add_theme_color_override("default_color", color)
	_hide_control_text(control)
	return true


static func load_font_paths(fonts_root: String = DEFAULT_FONT_ROOT) -> Array[String]:
	var font_paths: Array[String] = []
	_collect_font_paths(fonts_root, font_paths)
	return font_paths


static func load_font_files(fonts_root: String = DEFAULT_FONT_ROOT) -> Array[Font]:
	var font_paths := load_font_paths(fonts_root)

	var fonts: Array[Font] = []
	for path in font_paths:
		var resource := load(path)
		if resource is Font:
			fonts.append(resource as Font)

	return fonts


static func _collect_font_paths(directory_path: String, font_paths: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = directory.get_next()
			continue

		var path := directory_path.path_join(file_name)
		if directory.current_is_dir():
			_collect_font_paths(path, font_paths)
		else:
			var extension := file_name.get_extension().to_lower()
			if FONT_EXTENSIONS.has(extension):
				font_paths.append(path)

		file_name = directory.get_next()

	directory.list_dir_end()


static func _apply_font_corruption_recursive(node: Node, font_paths: Array[String], rng: RandomNumberGenerator) -> void:
	if node.has_meta(FONT_OVERLAY_META):
		return

	var control := node as Control
	if control != null:
		_apply_letter_font_corruption(control, font_paths, rng)

	for child in node.get_children():
		_apply_font_corruption_recursive(child, font_paths, rng)


static func _apply_letter_font_corruption(control: Control, font_paths: Array[String], rng: RandomNumberGenerator) -> void:
	if font_paths.is_empty() or control.has_meta(FONT_ORIGINAL_STATE_META):
		return

	var text := _get_control_text(control)
	if text.is_empty():
		return

	if control is RichTextLabel:
		var rich_text := control as RichTextLabel
		var original_bbcode_enabled := rich_text.bbcode_enabled
		control.set_meta(FONT_ORIGINAL_STATE_META, {
			"kind": "rich_text",
			"text": rich_text.text,
			"bbcode_enabled": original_bbcode_enabled
		})
		rich_text.bbcode_enabled = true
		rich_text.text = _build_letter_font_bbcode(rich_text.text, font_paths, rng, original_bbcode_enabled)
		return

	if not (control is Label or control is Button or control is LineEdit or control is TextEdit):
		return

	_clear_existing_letter_overlay(control)
	_capture_control_color_state(control)

	var overlay := RichTextLabel.new()
	overlay.name = FONT_OVERLAY_NAME
	overlay.set_meta(FONT_OVERLAY_META, true)
	overlay.bbcode_enabled = true
	overlay.text = _build_letter_font_bbcode(text, font_paths, rng)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.fit_content = false
	overlay.scroll_active = false
	overlay.clip_contents = true
	overlay.z_index = 100
	overlay.autowrap_mode = control.autowrap_mode if control is Label or control is TextEdit else TextServer.AUTOWRAP_OFF
	_copy_text_theme(control, overlay)
	_hide_control_text(control)
	control.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func _build_letter_font_bbcode(
	text: String,
	font_paths: Array[String],
	rng: RandomNumberGenerator,
	preserve_bbcode_tags := false
) -> String:
	var bbcode := ""
	var previous_font_index := -1
	var index := 0
	while index < text.length():
		var character := text.substr(index, 1)
		if preserve_bbcode_tags and character == "[":
			var tag_end := text.find("]", index)
			if tag_end >= index:
				bbcode += text.substr(index, tag_end - index + 1)
				index = tag_end + 1
				continue
		if character == "\n":
			bbcode += "\n"
			index += 1
			continue

		var font_index := rng.randi_range(0, font_paths.size() - 1)
		if font_paths.size() > 1 and font_index == previous_font_index:
			font_index = (font_index + rng.randi_range(1, font_paths.size() - 1)) % font_paths.size()

		previous_font_index = font_index
		var font_path := font_paths[font_index]
		bbcode += "[font=\"%s\"]%s[/font]" % [font_path, _escape_bbcode(character)]
		index += 1

	return bbcode


static func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")


static func _get_control_text(control: Control) -> String:
	if control is RichTextLabel:
		if control.has_method("get_parsed_text"):
			return String(control.call("get_parsed_text"))
		return (control as RichTextLabel).text
	if control is Label:
		return (control as Label).text
	if control is Button:
		return (control as Button).text
	if control is LineEdit:
		return (control as LineEdit).text
	if control is TextEdit:
		return (control as TextEdit).text

	return ""


static func _clear_existing_letter_overlay(control: Control) -> void:
	for child in control.get_children():
		if child.has_meta(FONT_OVERLAY_META) or child.name == FONT_OVERLAY_NAME:
			child.free()


static func _capture_control_color_state(control: Control) -> void:
	var color_overrides := {}
	for color_name in HIDDEN_TEXT_COLOR_NAMES:
		color_overrides[color_name] = {
			"had_override": control.has_theme_color_override(color_name),
			"color": control.get_theme_color(color_name)
		}
	control.set_meta(FONT_ORIGINAL_STATE_META, {
		"kind": "control_overlay",
		"color_overrides": color_overrides
	})


static func _hide_control_text(control: Control) -> void:
	var transparent := Color(1.0, 1.0, 1.0, 0.0)
	for color_name in HIDDEN_TEXT_COLOR_NAMES:
		control.add_theme_color_override(color_name, transparent)


static func _clear_font_corruption_recursive(node: Node) -> void:
	if node.has_meta(FONT_OVERLAY_META):
		return

	for child in node.get_children():
		_clear_font_corruption_recursive(child)

	var control := node as Control
	if control == null or not control.has_meta(FONT_ORIGINAL_STATE_META):
		return

	var original_state := control.get_meta(FONT_ORIGINAL_STATE_META) as Dictionary
	var state_kind := String(original_state.get("kind", ""))
	if state_kind == "rich_text" and control is RichTextLabel:
		var rich_text := control as RichTextLabel
		rich_text.bbcode_enabled = bool(original_state.get("bbcode_enabled", false))
		rich_text.text = String(original_state.get("text", ""))
	elif state_kind == "control_overlay":
		_clear_existing_letter_overlay(control)
		_restore_control_color_state(control, original_state.get("color_overrides", {}) as Dictionary)

	control.remove_meta(FONT_ORIGINAL_STATE_META)


static func _restore_control_color_state(control: Control, color_overrides: Dictionary) -> void:
	for color_name in HIDDEN_TEXT_COLOR_NAMES:
		var color_state := color_overrides.get(color_name, {}) as Dictionary
		if bool(color_state.get("had_override", false)):
			control.add_theme_color_override(color_name, color_state.get("color", Color.WHITE) as Color)
		else:
			control.remove_theme_color_override(color_name)


static func _copy_text_theme(source: Control, target: RichTextLabel) -> void:
	var font_size := _get_theme_font_size(source)
	target.add_theme_font_size_override("normal_font_size", font_size)
	target.add_theme_font_size_override("bold_font_size", font_size)
	target.add_theme_font_size_override("italics_font_size", font_size)
	target.add_theme_font_size_override("bold_italics_font_size", font_size)
	target.add_theme_font_size_override("mono_font_size", font_size)

	var font_color := _get_theme_font_color(source)
	target.add_theme_color_override("default_color", font_color)
	target.add_theme_color_override("font_outline_color", _get_theme_outline_color(source))
	target.add_theme_constant_override("outline_size", _get_theme_outline_size(source))

	if _has_property(target, "horizontal_alignment"):
		target.set("horizontal_alignment", _get_horizontal_alignment(source))
	if _has_property(target, "vertical_alignment"):
		target.set("vertical_alignment", _get_vertical_alignment(source))


static func _get_theme_font_size(control: Control) -> int:
	if control.has_theme_font_size("font_size"):
		return control.get_theme_font_size("font_size")
	if control.has_theme_font_size("normal_font_size"):
		return control.get_theme_font_size("normal_font_size")
	return 16


static func _get_theme_font_color(control: Control) -> Color:
	if control.has_theme_color("font_color"):
		return control.get_theme_color("font_color")
	if control.has_theme_color("default_color"):
		return control.get_theme_color("default_color")
	return Color.WHITE


static func _get_theme_outline_color(control: Control) -> Color:
	if control.has_theme_color("font_outline_color"):
		return control.get_theme_color("font_outline_color")
	return Color.TRANSPARENT


static func _get_theme_outline_size(control: Control) -> int:
	if control.has_theme_constant("outline_size"):
		return control.get_theme_constant("outline_size")
	return 0


static func _get_horizontal_alignment(control: Control) -> int:
	if control is Label:
		return (control as Label).horizontal_alignment
	if control is Button:
		return HORIZONTAL_ALIGNMENT_CENTER
	if control is LineEdit:
		return (control as LineEdit).alignment
	return HORIZONTAL_ALIGNMENT_LEFT


static func _get_vertical_alignment(control: Control) -> int:
	if control is Label:
		return (control as Label).vertical_alignment
	if control is Button:
		return VERTICAL_ALIGNMENT_CENTER
	return VERTICAL_ALIGNMENT_TOP


static func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if String(property["name"]) == property_name:
			return true

	return false
