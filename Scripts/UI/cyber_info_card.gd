@tool
class_name CyberInfoCard
extends PanelContainer

@export var entry: CyberInfoEntry:
	set(value):
		if entry == value:
			return
		_disconnect_entry_changed()
		entry = value
		_connect_entry_changed()
		if is_node_ready():
			_apply_entry()
@export var use_entry_content := true:
	set(value):
		use_entry_content = value
		if is_node_ready():
			_apply_entry()
@export var preserve_authored_display_image := true:
	set(value):
		preserve_authored_display_image = value
		if is_node_ready():
			_apply_entry()
@export var tower_border_color := Color(0.16, 0.72, 1.0, 1.0)
@export var virus_border_color := Color(1.0, 0.2, 0.25, 1.0)
@export_range(1.0, 10.0, 0.5) var border_width := 3.0

@onready var _image_frame: PanelContainer = $Margin/Content/ImageAspect/ImageFrame
@onready var _display_image: TextureRect = $Margin/Content/ImageAspect/ImageFrame/DisplayImage
@onready var _slideshow: HBoxContainer = $Margin/Content/Slideshow
@onready var _previous_button: Button = $Margin/Content/Slideshow/PreviousButton
@onready var _slide_label: Label = $Margin/Content/Slideshow/SlideLabel
@onready var _next_button: Button = $Margin/Content/Slideshow/NextButton
@onready var _name_label: Label = $Margin/Content/NameLabel
@onready var _type_label: Label = $Margin/Content/TypeLabel
@onready var _description_label: Label = $Margin/Content/DescriptionLabel
@onready var _slide_timer: Timer = $SlideTimer

var _slide_index := 0
var _image_tween: Tween
var _authored_display_texture: Texture2D
var _last_applied_display_texture: Texture2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_authored_display_texture = _display_image.texture
	if not _previous_button.pressed.is_connected(_show_previous_slide):
		_previous_button.pressed.connect(_show_previous_slide)
	if not _next_button.pressed.is_connected(_show_next_slide):
		_next_button.pressed.connect(_show_next_slide)
	if not _slide_timer.timeout.is_connected(_show_next_slide):
		_slide_timer.timeout.connect(_show_next_slide)
	_connect_entry_changed()
	if entry != null:
		_apply_entry()


func set_entry(value: CyberInfoEntry) -> void:
	entry = value
	_slide_index = 0


func _apply_entry() -> void:
	if entry == null:
		return
	_capture_manual_display_image()
	if use_entry_content:
		_name_label.text = entry.display_name
		_type_label.text = entry.type_label.to_upper()
		_description_label.text = entry.description
	_apply_category_border()

	var has_slideshow := entry.images.size() > 1
	_slideshow.visible = has_slideshow
	if has_slideshow and not Engine.is_editor_hint():
		_slide_timer.start()
	else:
		_slide_timer.stop()
	if use_entry_content:
		_show_slide(0, false)


func _apply_category_border() -> void:
	var accent := tower_border_color if entry.category == CyberInfoEntry.Category.TOWER else virus_border_color
	var image_style := _image_frame.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	image_style.border_color = accent
	image_style.set_border_width_all(roundi(border_width))
	_image_frame.add_theme_stylebox_override("panel", image_style)

	var card_style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	card_style.border_color = Color(accent, 0.72)
	add_theme_stylebox_override("panel", card_style)
	_type_label.add_theme_color_override("font_color", accent.lightened(0.18))


func _show_previous_slide() -> void:
	if entry == null or entry.images.size() < 2:
		return
	_show_slide(wrapi(_slide_index - 1, 0, entry.images.size()))
	_slide_timer.start()


func _show_next_slide() -> void:
	if entry == null or entry.images.size() < 2:
		return
	_show_slide(wrapi(_slide_index + 1, 0, entry.images.size()))
	_slide_timer.start()


func _show_slide(index: int, animate := true) -> void:
	if entry == null or entry.images.is_empty():
		_set_display_texture(null)
		_slide_label.text = ""
		return

	_slide_index = clampi(index, 0, entry.images.size() - 1)
	var slide_texture := entry.images[_slide_index]
	if (
		_slide_index == 0
		and preserve_authored_display_image
		and _authored_display_texture != null
	):
		slide_texture = _authored_display_texture
	_slide_label.text = "%d / %d  %s" % [
		_slide_index + 1,
		entry.images.size(),
		entry.get_slide_label(_slide_index),
	]
	if not animate:
		_set_display_texture(slide_texture)
		_display_image.modulate.a = 1.0
		return

	if _image_tween != null:
		_image_tween.kill()
	_image_tween = create_tween()
	_image_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_image_tween.tween_property(_display_image, "modulate:a", 0.0, 0.1)
	_image_tween.tween_callback(_set_display_texture.bind(slide_texture))
	_image_tween.tween_property(_display_image, "modulate:a", 1.0, 0.18)


func _capture_manual_display_image() -> void:
	if not preserve_authored_display_image:
		return
	if _display_image.texture == null:
		return
	if _display_image.texture != _last_applied_display_texture:
		_authored_display_texture = _display_image.texture


func _set_display_texture(texture: Texture2D) -> void:
	_display_image.texture = texture
	_last_applied_display_texture = texture


func _connect_entry_changed() -> void:
	if entry != null and not entry.changed.is_connected(_on_entry_changed):
		entry.changed.connect(_on_entry_changed)


func _disconnect_entry_changed() -> void:
	if entry != null and entry.changed.is_connected(_on_entry_changed):
		entry.changed.disconnect(_on_entry_changed)


func _on_entry_changed() -> void:
	if is_node_ready():
		_apply_entry()
