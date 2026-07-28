@tool
class_name ZombieNodeProgressBar
extends Node2D

@export var progress_bar_path: NodePath = ^"ProgressBar"
@export var threshold_marker_path: NodePath = ^"ThresholdMarker"
@export var threshold_label_path: NodePath = ^"ThresholdLabel"
@export var status_label_path: NodePath = ^"StatusLabel"
@export_range(0.0, 1.0, 0.01) var editor_preview_ratio := 1.0:
	set(value):
		editor_preview_ratio = clampf(value, 0.0, 1.0)
		if Engine.is_editor_hint():
			_apply_ratio(editor_preview_ratio)
@export_range(0.05, 1.0, 0.01) var tween_seconds := 0.32
@export_range(0.0, 1.0, 0.01) var critical_ratio := 1.0 / 3.0

var _progress_bar: ProgressBar
var _threshold_marker: ColorRect
var _threshold_label: Label
var _status_label: Label
var _health_tween: Tween
var _pulse_tween: Tween
var _current_ratio := 1.0


func _ready() -> void:
	_resolve_nodes()
	_position_threshold_marker()
	if Engine.is_editor_hint():
		_apply_ratio(editor_preview_ratio)
	else:
		_apply_ratio(_current_ratio)


func set_health(current_health: int, max_health: int, animate := true) -> void:
	var ratio := 0.0
	if max_health > 0:
		ratio = float(current_health) / float(max_health)
	set_ratio(ratio, animate)


func set_ratio(ratio: float, animate := true) -> void:
	_current_ratio = clampf(ratio, 0.0, 1.0)
	_resolve_nodes()
	if _progress_bar == null:
		return

	if Engine.is_editor_hint() or not animate or not is_inside_tree():
		_apply_ratio(_current_ratio)
		return

	if _health_tween != null:
		_health_tween.kill()
	_health_tween = create_tween()
	_health_tween.tween_property(
		_progress_bar,
		"value",
		_current_ratio * 100.0,
		tween_seconds
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func set_critical_state(value: bool) -> void:
	_resolve_nodes()
	if _status_label != null:
		_status_label.text = "CORE BREACH // RAPID SPAWN" if value else "CPU LINK EXPOSED"
		_status_label.modulate = (
			Color(1.0, 0.28, 0.2, 1.0)
				if value
				else Color(0.35, 0.9, 1.0, 1.0)
		)
	if not value or Engine.is_editor_hint() or not is_inside_tree():
		_stop_critical_pulse()
		return

	_stop_critical_pulse()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(
		self,
		"modulate",
		Color(1.0, 0.7, 0.7, 1.0),
		0.34
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(
		self,
		"modulate",
		Color.WHITE,
		0.34
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func set_bar_visible(value: bool) -> void:
	visible = value
	if value:
		modulate = Color.WHITE


func play_defeat_fade() -> void:
	_stop_critical_pulse()
	if not is_inside_tree():
		hide()
		return

	var fade_tween := create_tween()
	fade_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.45
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_tween.tween_callback(hide)


func _resolve_nodes() -> void:
	if _progress_bar == null:
		_progress_bar = get_node_or_null(progress_bar_path) as ProgressBar
	if _threshold_marker == null:
		_threshold_marker = get_node_or_null(threshold_marker_path) as ColorRect
	if _threshold_label == null:
		_threshold_label = get_node_or_null(threshold_label_path) as Label
	if _status_label == null:
		_status_label = get_node_or_null(status_label_path) as Label

	if _progress_bar != null:
		_progress_bar.min_value = 0.0
		_progress_bar.max_value = 100.0
		_progress_bar.show_percentage = false


func _position_threshold_marker() -> void:
	_resolve_nodes()
	if _progress_bar == null or _threshold_marker == null:
		return

	var marker_x := lerpf(
		_progress_bar.offset_left,
		_progress_bar.offset_right,
		clampf(critical_ratio, 0.0, 1.0)
	)
	_threshold_marker.position.x = marker_x - _threshold_marker.size.x * 0.5
	if _threshold_label != null:
		_threshold_label.position.x = marker_x - _threshold_label.size.x * 0.5


func _apply_ratio(ratio: float) -> void:
	_resolve_nodes()
	if _progress_bar != null:
		_progress_bar.value = clampf(ratio, 0.0, 1.0) * 100.0


func _stop_critical_pulse() -> void:
	if _pulse_tween != null:
		_pulse_tween.kill()
		_pulse_tween = null
	modulate = Color.WHITE
