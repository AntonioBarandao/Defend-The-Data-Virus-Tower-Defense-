class_name VictoryHUD
extends CanvasLayer

signal play_again_requested
signal main_menu_requested

const VICTORY_ANIMATION := &"victory"

@export_range(0.1, 2.0, 0.01) var dim_fade_duration := 0.45
@export_range(0.1, 2.0, 0.01) var display_entry_duration := 0.55
@export_range(0.05, 1.0, 0.01) var button_entry_duration := 0.38
@export_range(0.0, 1.0, 0.01) var button_entry_delay := 0.18
@export_range(0.5, 1.0, 0.01) var display_start_scale := 0.78
@export_range(0.5, 1.0, 0.01) var button_start_scale := 0.72

@onready var _root: Control = $Root
@onready var _dim_overlay: ColorRect = $Root/DimOverlay
@onready var _animated_display: AnimatedSprite2D = $Root/DisplayAnchor/AnimatedDisplay
@onready var _play_again_button: Button = $Root/PlayAgainButton
@onready var _main_menu_button: Button = $Root/MainMenuButton

var _sequence_running := false
var _animated_display_rest_scale := Vector2.ONE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_animated_display_rest_scale = _animated_display.scale
	_play_again_button.pressed.connect(_on_play_again_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_prepare_hidden()


func show_victory() -> void:
	if _sequence_running:
		return

	_sequence_running = true
	_root.show()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_overlay.modulate.a = 0.0
	_animated_display.show()
	_animated_display.animation = VICTORY_ANIMATION
	_animated_display.frame = 0
	_animated_display.modulate.a = 0.0
	_animated_display.scale = _animated_display_rest_scale * display_start_scale
	_reset_button(_play_again_button)
	_reset_button(_main_menu_button)

	var intro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intro.set_parallel(true)
	intro.tween_property(_dim_overlay, "modulate:a", 1.0, dim_fade_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	intro.tween_property(_animated_display, "modulate:a", 1.0, minf(display_entry_duration, 0.3))
	intro.tween_property(_animated_display, "scale", _animated_display_rest_scale, display_entry_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_animated_display.play(VICTORY_ANIMATION)
	await _animated_display.animation_finished
	_animated_display.pause()
	_animated_display.frame = _animated_display.sprite_frames.get_frame_count(VICTORY_ANIMATION) - 1

	await _reveal_button(_play_again_button)
	await get_tree().create_timer(button_entry_delay, true, false, true).timeout
	await _reveal_button(_main_menu_button)
	_play_again_button.grab_focus()


func _prepare_hidden() -> void:
	_root.hide()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animated_display.stop()
	_animated_display.hide()
	_reset_button(_play_again_button)
	_reset_button(_main_menu_button)


func _reset_button(button: Button) -> void:
	button.hide()
	button.disabled = true
	button.modulate.a = 0.0
	button.scale = Vector2.ONE * button_start_scale


func _reveal_button(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	button.show()
	button.disabled = false
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(button, "modulate:a", 1.0, button_entry_duration)
	tween.tween_property(button, "scale", Vector2.ONE, button_entry_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished


func _on_play_again_pressed() -> void:
	_disable_actions()
	play_again_requested.emit()


func _on_main_menu_pressed() -> void:
	_disable_actions()
	main_menu_requested.emit()


func _disable_actions() -> void:
	_play_again_button.disabled = true
	_main_menu_button.disabled = true
