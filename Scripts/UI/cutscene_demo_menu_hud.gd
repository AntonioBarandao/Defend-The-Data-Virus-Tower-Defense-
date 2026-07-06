class_name CutsceneDemoMenuHUD
extends CanvasLayer

@export var game_path: NodePath = ^".."
@export var music_player_path: NodePath = ^"../AdminSandboxSoundtrack"
@export var text_cutscene_hud_path: NodePath = ^"../TextCutsceneHUD"
@export_file("*.tscn") var main_menu_scene_path := "res://Scenes/Menus/MainMenu.tscn"
@export_group("Editable UI Paths")
@export var hamburger_button_path: NodePath = ^"Root/HamburgerButton"
@export var dim_overlay_path: NodePath = ^"Root/DimOverlay"
@export var menu_panel_path: NodePath = ^"Root/MenuPanel"
@export var resume_button_path: NodePath = ^"Root/MenuPanel/Margin/Content/ResumeButton"
@export var settings_button_path: NodePath = ^"Root/MenuPanel/Margin/Content/SettingsButton"
@export var exit_button_path: NodePath = ^"Root/MenuPanel/Margin/Content/ExitButton"
@export var settings_panel_path: NodePath = ^"Root/MenuPanel/Margin/Content/SettingsPanel"
@export var master_slider_path: NodePath = ^"Root/MenuPanel/Margin/Content/SettingsPanel/Margin/Sliders/MasterRow/MasterSlider"
@export var music_slider_path: NodePath = ^"Root/MenuPanel/Margin/Content/SettingsPanel/Margin/Sliders/MusicRow/MusicSlider"
@export var sound_slider_path: NodePath = ^"Root/MenuPanel/Margin/Content/SettingsPanel/Margin/Sliders/SoundRow/SoundSlider"
@export var wave_input_path: NodePath = ^"Root/WaveSetPanel/Margin/Content/WaveInput"
@export var wave_set_button_path: NodePath = ^"Root/WaveSetPanel/Margin/Content/SetWaveButton"
@export_group("")
@export_group("Menu Animation")
@export_range(80.0, 900.0, 1.0) var menu_slide_distance := 520.0
@export_range(0.08, 1.0, 0.01) var menu_open_duration := 0.34
@export_range(0.08, 1.0, 0.01) var menu_close_duration := 0.24
@export_range(0.0, 1.0, 0.01) var dim_overlay_opacity := 1.0
@export_group("")

var _hamburger_button: Button
var _dim_overlay: ColorRect
var _menu_panel: PanelContainer
var _resume_button: Button
var _settings_button: Button
var _exit_button: Button
var _settings_panel: PanelContainer
var _master_slider: HSlider
var _music_slider: HSlider
var _sound_slider: HSlider
var _wave_input: LineEdit
var _wave_set_button: Button

var _game: Node
var _music_player: AudioStreamPlayer
var _text_cutscene_hud: Node
var _menu_open := false
var _was_tree_paused_before_menu := false
var _menu_rest_position := Vector2.ZERO
var _menu_rest_modulate := Color.WHITE
var _menu_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_game = get_node_or_null(game_path)
	_music_player = get_node_or_null(music_player_path) as AudioStreamPlayer
	_text_cutscene_hud = get_node_or_null(text_cutscene_hud_path)
	_resolve_ui_nodes()
	if _menu_panel != null:
		_menu_rest_position = _menu_panel.position
		_menu_rest_modulate = _menu_panel.modulate
		_menu_panel.hide()
	if _dim_overlay != null:
		_dim_overlay.hide()
		_set_canvas_item_alpha(_dim_overlay, 0.0)
	if _settings_panel != null:
		_settings_panel.hide()
	if _hamburger_button != null:
		_hamburger_button.pressed.connect(_toggle_menu)
	if _resume_button != null:
		_resume_button.pressed.connect(_close_menu)
	if _settings_button != null:
		_settings_button.pressed.connect(_toggle_settings)
	if _exit_button != null:
		_exit_button.pressed.connect(_return_to_main_menu)
	if _wave_set_button != null:
		_wave_set_button.pressed.connect(_apply_wave_set)
	if _wave_input != null:
		_wave_input.text_submitted.connect(func(_text: String) -> void: _apply_wave_set())
	if _master_slider != null:
		_master_slider.value_changed.connect(func(value: float) -> void: _set_bus_volume("Master", value))
	if _music_slider != null:
		_music_slider.value_changed.connect(_set_music_volume)
	if _sound_slider != null:
		_sound_slider.value_changed.connect(func(value: float) -> void: _set_bus_volume("SFX", value))
	_sync_slider_values()


func _resolve_ui_nodes() -> void:
	_hamburger_button = get_node_or_null(hamburger_button_path) as Button
	_dim_overlay = get_node_or_null(dim_overlay_path) as ColorRect
	_menu_panel = get_node_or_null(menu_panel_path) as PanelContainer
	_resume_button = get_node_or_null(resume_button_path) as Button
	_settings_button = get_node_or_null(settings_button_path) as Button
	_exit_button = get_node_or_null(exit_button_path) as Button
	_settings_panel = get_node_or_null(settings_panel_path) as PanelContainer
	_master_slider = get_node_or_null(master_slider_path) as HSlider
	_music_slider = get_node_or_null(music_slider_path) as HSlider
	_sound_slider = get_node_or_null(sound_slider_path) as HSlider
	_wave_input = get_node_or_null(wave_input_path) as LineEdit
	_wave_set_button = get_node_or_null(wave_set_button_path) as Button


func _toggle_menu() -> void:
	if _menu_panel == null:
		return

	if _menu_open:
		_close_menu()
	else:
		_open_menu()


func _open_menu() -> void:
	if _menu_panel == null or _menu_open:
		return

	_menu_open = true
	_was_tree_paused_before_menu = get_tree().paused
	get_tree().paused = true
	if _settings_panel != null:
		_settings_panel.hide()

	if _dim_overlay != null:
		_dim_overlay.show()
		_set_canvas_item_alpha(_dim_overlay, 0.0)

	_menu_panel.show()
	_menu_panel.position = _menu_rest_position + Vector2(0.0, menu_slide_distance)
	_set_canvas_item_alpha(_menu_panel, 0.0)

	var tween := _create_menu_tween()
	tween.set_parallel(true)
	if _dim_overlay != null:
		tween.tween_property(_dim_overlay, "modulate:a", dim_overlay_opacity, menu_open_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(_menu_panel, "position", _menu_rest_position, menu_open_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(_menu_panel, "modulate:a", _menu_rest_modulate.a, menu_open_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _close_menu() -> void:
	if _menu_panel == null:
		return

	if not _menu_open:
		_menu_panel.hide()
		if _dim_overlay != null:
			_dim_overlay.hide()
		return

	_menu_open = false
	var tween := _create_menu_tween()
	tween.set_parallel(true)
	if _dim_overlay != null:
		tween.tween_property(_dim_overlay, "modulate:a", 0.0, menu_close_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(_menu_panel, "position", _menu_rest_position + Vector2(0.0, menu_slide_distance), menu_close_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(_menu_panel, "modulate:a", 0.0, menu_close_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(Callable(self, "_finish_close_menu"))


func _toggle_settings() -> void:
	if _settings_panel == null:
		return

	_settings_panel.visible = not _settings_panel.visible


func _return_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene_path)


func _apply_wave_set() -> void:
	if _game == null or not _game.has_method("set_current_wave_for_demo"):
		return
	if _wave_input == null:
		return

	var wave_number := clampi(int(_wave_input.text), 0, 20)
	_wave_input.text = str(wave_number)
	_game.call("set_current_wave_for_demo", wave_number)


func _sync_slider_values() -> void:
	if _master_slider != null:
		_master_slider.value = _get_bus_linear("Master")
	if _sound_slider != null:
		_sound_slider.value = _get_bus_linear("SFX")
	if _music_slider != null:
		_music_slider.value = _get_music_linear()


func _set_bus_volume(bus_name: String, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear_value, 0.001)))
	AudioServer.set_bus_mute(bus_index, linear_value <= 0.001)


func _get_bus_linear(bus_name: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return 1.0

	if AudioServer.is_bus_mute(bus_index):
		return 0.0

	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)


func _set_music_volume(linear_value: float) -> void:
	if _music_player != null:
		_music_player.volume_db = linear_to_db(maxf(linear_value, 0.001))

	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(maxf(linear_value, 0.001)))
		AudioServer.set_bus_mute(music_bus, linear_value <= 0.001)


func _get_music_linear() -> float:
	if _music_player != null:
		return clampf(db_to_linear(_music_player.volume_db), 0.0, 1.0)

	return _get_bus_linear("Music")


func _create_menu_tween() -> Tween:
	if _menu_tween != null:
		_menu_tween.kill()

	_menu_tween = create_tween()
	_menu_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return _menu_tween


func _finish_close_menu() -> void:
	if _menu_open:
		return

	if _menu_panel != null:
		_menu_panel.hide()
		_menu_panel.position = _menu_rest_position
		_menu_panel.modulate = _menu_rest_modulate
	if _dim_overlay != null:
		_dim_overlay.hide()
		_set_canvas_item_alpha(_dim_overlay, 0.0)
	get_tree().paused = _was_tree_paused_before_menu


func _set_canvas_item_alpha(canvas_item: CanvasItem, alpha: float) -> void:
	var next_modulate := canvas_item.modulate
	next_modulate.a = alpha
	canvas_item.modulate = next_modulate
