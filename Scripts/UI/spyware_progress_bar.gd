@tool
class_name SpywareProgressBar
extends Node2D

@export var progress_bar_path: NodePath = ^"ProgressBar"
@export_range(0.0, 1.0, 0.01) var editor_preview_ratio := 1.0:
	set(value):
		editor_preview_ratio = clampf(value, 0.0, 1.0)
		if Engine.is_editor_hint():
			_apply_ratio(editor_preview_ratio)
@export_range(0.05, 1.0, 0.01) var tween_seconds := 0.24

var _progress_bar: ProgressBar
var _health_tween: Tween
var _current_ratio := 1.0


func _ready() -> void:
	_resolve_progress_bar()
	_apply_ratio(editor_preview_ratio if Engine.is_editor_hint() else _current_ratio)


func reset_full(animate := false) -> void:
	set_health(1, 1, animate)


func set_health(current_health: int, max_health: int, animate := true) -> void:
	var ratio := 0.0
	if max_health > 0:
		ratio = float(current_health) / float(max_health)
	set_ratio(ratio, animate)


func set_ratio(ratio: float, animate := true) -> void:
	_current_ratio = clampf(ratio, 0.0, 1.0)
	_resolve_progress_bar()
	if _progress_bar == null:
		return

	if _health_tween != null:
		_health_tween.kill()
		_health_tween = null

	var target_value := _current_ratio * 100.0
	if Engine.is_editor_hint() or not animate or not is_inside_tree():
		_progress_bar.value = target_value
		return

	_health_tween = create_tween()
	_health_tween.tween_property(
		_progress_bar,
		"value",
		target_value,
		tween_seconds
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_health_tween.tween_callback(func() -> void:
		_health_tween = null
	)


func set_bar_visible(value: bool) -> void:
	visible = value
	if value:
		modulate = Color.WHITE


func _resolve_progress_bar() -> void:
	if is_instance_valid(_progress_bar):
		return
	_progress_bar = get_node_or_null(progress_bar_path) as ProgressBar
	if _progress_bar == null:
		return
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.show_percentage = false


func _apply_ratio(ratio: float) -> void:
	_resolve_progress_bar()
	if _progress_bar != null:
		_progress_bar.value = clampf(ratio, 0.0, 1.0) * 100.0
