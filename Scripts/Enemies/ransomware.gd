class_name Ransomware
extends PathFollow2D

const CentralAudioResolver := preload("res://Scripts/Audio/audio_player_resolver.gd")

signal timer_changed(time_remaining: float, formatted_time: String)
signal health_changed(current_health: int, maximum_health: int)
signal timed_out(ransomware: Ransomware, target: Node2D)
signal lock_released(ransomware: Ransomware, target: Node2D, reason: StringName)
signal visual_finished(ransomware: Ransomware)
signal result_announcement_finished

enum State {
	DORMANT,
	APPEARING,
	ACTIVE,
	DESTROYING,
	RELEASING,
	FINISHED
}

const RELEASE_DESTROYED := &"destroyed"
const RELEASE_PAID := &"paid"
const RELEASE_TIMEOUT := &"timeout"
const MAX_STANDARD_DISPLAY_SECONDS := 99 * 60 + 59

@export_group("Ransomware")
@export_range(1, 10000, 1) var maximum_health := 150
@export var target_offset := Vector2(0, -22)
@export_range(0.01, 1.0, 0.01) var health_tween_seconds := 0.18
@export_group("Visual Nodes")
@export var appear_animation_path: NodePath = ^"AppearAnimation"
@export var head_appear_animation_path: NodePath = ^"HeadAppearAnimation"
@export var idle_animation_path: NodePath = ^"IdleAnimation"
@export var front_straight_animation_path: NodePath = ^"FrontStraightAnimation"
@export var front_sides_animation_path: NodePath = ^"FrontSidesAnimation"
@export var destroy_animation_path: NodePath = ^"DestroyAnimation"
@export var disappear_animation_path: NodePath = ^"DisappearAnimation"
@export var timer_label_path: NodePath = ^"TimerLabel"
@export var health_hud_path: NodePath = ^"RansomwareHealthHUD"
@export var health_bar_path: NodePath = ^"RansomwareHealthHUD/HealthBar"
@export var result_root_path: NodePath = ^"ResultAnnouncementHUD/Root"
@export var result_panel_path: NodePath = ^"ResultAnnouncementHUD/Root/Center/ResultPanel"
@export var result_label_path: NodePath = ^"ResultAnnouncementHUD/Root/Center/ResultPanel/Margin/ResultLabel"
@export_range(0.05, 1.0, 0.01) var result_appear_seconds := 0.2
@export_range(0.0, 5.0, 0.05) var result_hold_seconds := 0.9
@export_range(0.05, 1.0, 0.01) var result_fade_seconds := 0.28
@export_group("")
@export_group("Audio")
@export var appear_sfx_path: NodePath = ^"Sounds/RansomwareAppearSfx"
@export var paid_sfx_path: NodePath = ^"Sounds/RansomwarePaidSfx"
@export var deleted_sfx_path: NodePath = ^"Sounds/RansomwareDeletedSfx"
@export_group("")

@onready var _appear_animation := get_node_or_null(appear_animation_path) as AnimatedSprite2D
@onready var _head_appear_animation := get_node_or_null(
	head_appear_animation_path
) as AnimatedSprite2D
@onready var _idle_animation := get_node_or_null(idle_animation_path) as AnimatedSprite2D
@onready var _front_straight_animation := get_node_or_null(
	front_straight_animation_path
) as AnimatedSprite2D
@onready var _front_sides_animation := get_node_or_null(
	front_sides_animation_path
) as AnimatedSprite2D
@onready var _destroy_animation := get_node_or_null(
	destroy_animation_path
) as AnimatedSprite2D
@onready var _disappear_animation := get_node_or_null(
	disappear_animation_path
) as AnimatedSprite2D
@onready var _timer_label := get_node_or_null(timer_label_path) as Label
@onready var _health_hud := get_node_or_null(health_hud_path) as CanvasItem
@onready var _health_bar := get_node_or_null(health_bar_path) as ProgressBar
@onready var _result_root := get_node_or_null(result_root_path) as Control
@onready var _result_panel := get_node_or_null(result_panel_path) as Control
@onready var _result_label := get_node_or_null(result_label_path) as Label

var _state := State.DORMANT
var _target_tower: Node2D
var _time_remaining := 0.0
var _ransom_cost := 0
var _current_health := 150
var _target_was_processing := false
var _target_was_physics_processing := false
var _health_tween: Tween
var _result_tween: Tween
var _release_reason := RELEASE_PAID
var _appear_sfx: AudioStreamPlayer
var _paid_sfx: AudioStreamPlayer
var _deleted_sfx: AudioStreamPlayer


func _ready() -> void:
	_appear_sfx = CentralAudioResolver.resolve(self, appear_sfx_path)
	_paid_sfx = CentralAudioResolver.resolve(self, paid_sfx_path)
	_deleted_sfx = CentralAudioResolver.resolve(self, deleted_sfx_path)
	rotates = false
	loop = false
	_current_health = maximum_health
	_configure_health_bar()
	_hide_all_animation_nodes()
	if _timer_label != null:
		_timer_label.hide()
	if _health_hud != null:
		_health_hud.hide()
	if _result_root != null:
		_result_root.hide()


func configure(target: Node2D, duration_seconds: float, ransom_cost: int) -> void:
	_target_tower = target
	_time_remaining = maxf(0.0, duration_seconds)
	_ransom_cost = maxi(0, ransom_cost)
	_current_health = maximum_health
	_state = State.APPEARING
	visible = true
	_follow_target()
	_lock_target()
	_configure_health_bar()
	_update_timer_presentation()
	if _timer_label != null:
		_timer_label.show()
	if _health_hud != null:
		_health_hud.show()


func play_appear() -> void:
	if _state != State.APPEARING:
		return

	_play_audio_player(_appear_sfx)
	_hide_all_animation_nodes()
	if _appear_animation == null and _head_appear_animation == null:
		finish_appear_immediately()
		return

	if _appear_animation != null:
		_appear_animation.show()
		_appear_animation.play(&"appear")
	if _head_appear_animation != null:
		_head_appear_animation.show()
		_head_appear_animation.play(&"head_appear")
	while _state == State.APPEARING \
			and (_is_animation_playing(_appear_animation) \
				or _is_animation_playing(_head_appear_animation)):
		await get_tree().process_frame

	if _state == State.APPEARING:
		finish_appear_immediately()


func finish_appear_immediately() -> void:
	if _state != State.APPEARING:
		return

	if _appear_animation != null:
		_appear_animation.stop()
		_appear_animation.hide()
	if _head_appear_animation != null:
		_head_appear_animation.stop()
		_head_appear_animation.hide()
	_show_idle_visuals()
	_state = State.ACTIVE


func update_interruption(delta: float) -> void:
	if _state == State.FINISHED or _state == State.DORMANT:
		return

	_follow_target()
	if _state != State.ACTIVE:
		return
	if not is_instance_valid(_target_tower):
		release_without_payment(RELEASE_TIMEOUT)
		return

	_time_remaining = maxf(0.0, _time_remaining - maxf(0.0, delta))
	_update_timer_presentation()
	if _time_remaining > 0.0:
		return

	_state = State.RELEASING
	_play_audio_player(_deleted_sfx)
	if _timer_label != null:
		_timer_label.hide()
	_release_reason = RELEASE_TIMEOUT
	timed_out.emit(self, _target_tower)
	call_deferred("_play_release_sequence")


func take_damage(amount: int) -> bool:
	if _state != State.ACTIVE or amount <= 0:
		return false

	_current_health = maxi(0, _current_health - amount)
	_tween_health_bar_to(_current_health)
	health_changed.emit(_current_health, maximum_health)
	if _current_health > 0:
		return false

	_state = State.DESTROYING
	_play_audio_player(_deleted_sfx)
	_release_reason = RELEASE_DESTROYED
	if _timer_label != null:
		_timer_label.hide()
	_unlock_target(RELEASE_DESTROYED)
	call_deferred("_play_destroy_sequence")
	return true


func release_from_payment() -> bool:
	if _state not in [State.APPEARING, State.ACTIVE]:
		return false

	_state = State.RELEASING
	_play_audio_player(_paid_sfx)
	_release_reason = RELEASE_PAID
	if _timer_label != null:
		_timer_label.hide()
	_unlock_target(RELEASE_PAID)
	call_deferred("_play_release_sequence")
	return true


func release_without_payment(reason: StringName = RELEASE_TIMEOUT) -> void:
	if _state == State.FINISHED or _state == State.DORMANT:
		return

	_state = State.RELEASING
	_release_reason = reason
	if _timer_label != null:
		_timer_label.hide()
	_unlock_target(reason)
	call_deferred("_play_release_sequence")


func can_be_targeted() -> bool:
	return _state == State.ACTIVE and _current_health > 0


func get_target_tower() -> Node2D:
	return _target_tower


func get_time_remaining() -> float:
	return _time_remaining


func get_ransom_cost() -> int:
	return _ransom_cost


func get_current_health() -> int:
	return _current_health


func get_maximum_health() -> int:
	return maximum_health


func get_formatted_time() -> String:
	return _format_time(_time_remaining)


func _play_destroy_sequence() -> void:
	_hide_all_animation_nodes()
	if _health_hud != null:
		_health_hud.hide()
	if _destroy_animation != null:
		_destroy_animation.show()
		_destroy_animation.play(&"destroy")
		while _state == State.DESTROYING \
				and is_instance_valid(_destroy_animation) \
				and _destroy_animation.is_playing():
			await get_tree().process_frame

	if _state != State.DESTROYING:
		return
	_state = State.RELEASING
	await _play_disappear_animation()
	_finish_visual()


func _play_release_sequence() -> void:
	if _state != State.RELEASING:
		return

	_unlock_target(_release_reason)
	_hide_all_animation_nodes()
	if _health_hud != null:
		_health_hud.hide()
	_play_result_announcement(_release_reason)
	await _play_disappear_animation()
	if _result_root != null and _result_root.visible:
		await result_announcement_finished
	_finish_visual()


func _play_disappear_animation() -> void:
	if _disappear_animation == null:
		return

	_disappear_animation.show()
	_disappear_animation.play_backwards(&"appear")
	while _state == State.RELEASING \
			and is_instance_valid(_disappear_animation) \
			and _disappear_animation.is_playing():
		await get_tree().process_frame
	_disappear_animation.stop()
	_disappear_animation.hide()


func _finish_visual() -> void:
	if _state == State.FINISHED:
		return

	_state = State.FINISHED
	_hide_all_animation_nodes()
	if _timer_label != null:
		_timer_label.hide()
	if _health_hud != null:
		_health_hud.hide()
	if _result_root != null:
		_result_root.hide()
	visual_finished.emit(self)
	queue_free()


func _play_result_announcement(reason: StringName) -> void:
	if reason not in [RELEASE_PAID, RELEASE_TIMEOUT] \
			or _result_root == null \
			or _result_panel == null \
			or _result_label == null:
		return

	if _result_tween != null and _result_tween.is_valid():
		_result_tween.kill()
	_result_label.text = (
		"RANSOMWARE PAID"
			if reason == RELEASE_PAID
			else "DELETED"
	)
	_result_label.add_theme_color_override(
		"font_color",
		Color(0.19, 1.0, 0.45, 1.0)
			if reason == RELEASE_PAID
			else Color(1.0, 0.16, 0.16, 1.0)
	)
	_result_root.show()
	_result_panel.scale = Vector2(0.72, 0.72)
	_result_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	await get_tree().process_frame
	if not is_instance_valid(_result_panel):
		return
	_result_panel.pivot_offset = _result_panel.size * 0.5

	_result_tween = create_tween()
	_result_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_result_tween.tween_property(
		_result_panel,
		"scale",
		Vector2.ONE,
		result_appear_seconds
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_result_tween.parallel().tween_property(
		_result_panel,
		"modulate:a",
		1.0,
		result_appear_seconds
	)
	_result_tween.tween_interval(result_hold_seconds)
	_result_tween.tween_property(
		_result_panel,
		"modulate:a",
		0.0,
		result_fade_seconds
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _result_tween.finished
	if _result_root != null:
		_result_root.hide()
	result_announcement_finished.emit()


func _show_idle_visuals() -> void:
	_hide_all_animation_nodes()
	if _idle_animation != null:
		_idle_animation.show()
		_idle_animation.play(&"idle")
	if _front_straight_animation != null:
		_front_straight_animation.show()
		_front_straight_animation.play(&"front_straight")


func _hide_all_animation_nodes() -> void:
	for animation in [
		_appear_animation,
		_head_appear_animation,
		_idle_animation,
		_front_straight_animation,
		_front_sides_animation,
		_destroy_animation,
		_disappear_animation
	]:
		if animation == null:
			continue
		animation.stop()
		animation.hide()


func _is_animation_playing(animation: AnimatedSprite2D) -> bool:
	return is_instance_valid(animation) and animation.is_playing()


func _follow_target() -> void:
	if is_instance_valid(_target_tower):
		global_position = _target_tower.global_position + target_offset


func _lock_target() -> void:
	if not is_instance_valid(_target_tower):
		return

	_target_was_processing = _target_tower.is_processing()
	_target_was_physics_processing = _target_tower.is_physics_processing()
	_target_tower.set_meta("ransom_locked", true)
	_target_tower.set_meta("ransomware_owner", self)
	_target_tower.set_process(false)
	_target_tower.set_physics_process(false)


func _unlock_target(reason: StringName) -> void:
	var target := _target_tower
	if not is_instance_valid(target):
		return
	if not target.has_meta("ransomware_owner") \
			or target.get_meta("ransomware_owner") != self:
		return

	target.remove_meta("ransom_locked")
	target.remove_meta("ransomware_owner")
	target.set_process(_target_was_processing)
	target.set_physics_process(_target_was_physics_processing)
	lock_released.emit(self, target, reason)


func _configure_health_bar() -> void:
	if _health_bar == null:
		return

	_health_bar.min_value = 0.0
	_health_bar.max_value = float(maximum_health)
	_health_bar.value = float(_current_health)
	_health_bar.show_percentage = false


func _tween_health_bar_to(value: int) -> void:
	if _health_bar == null:
		return
	if _health_tween != null and _health_tween.is_valid():
		_health_tween.kill()

	_health_tween = create_tween()
	_health_tween.tween_property(
		_health_bar,
		"value",
		float(value),
		health_tween_seconds
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_timer_presentation() -> void:
	var formatted_time := _format_time(_time_remaining)
	if _timer_label != null:
		_timer_label.text = formatted_time
	timer_changed.emit(_time_remaining, formatted_time)


func _format_time(time_seconds: float) -> String:
	var total_seconds := maxi(0, ceili(time_seconds))
	if total_seconds > MAX_STANDARD_DISPLAY_SECONDS:
		return "99:99"
	var minutes := floori(float(total_seconds) / 60.0)
	var seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _play_audio_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	player.stop()
	player.play()
