class_name ZombieMinionDestroyEffect
extends Node2D

const LINE_COUNT := 14
const EFFECT_DURATION := 0.52
const MINION_GREEN := Color("#9AFF18")
const TOP_DOWN_Y_SCALE := 0.58


func _ready() -> void:
	z_as_relative = false
	for index in range(LINE_COUNT):
		_spawn_line(index)

	var cleanup_tween := create_tween()
	cleanup_tween.tween_interval(EFFECT_DURATION + 0.08)
	cleanup_tween.tween_callback(queue_free)


func _spawn_line(index: int) -> void:
	var angle := TAU * float(index) / float(LINE_COUNT) + randf_range(-0.12, 0.12)
	var direction := Vector2(cos(angle), sin(angle) * TOP_DOWN_Y_SCALE).normalized()
	var start_distance := randf_range(10.0, 24.0)
	var line_length := randf_range(20.0, 46.0)
	var line := Line2D.new()
	line.name = "GreenDestroyLine"
	line.width = randf_range(2.5, 5.0)
	line.default_color = MINION_GREEN
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.points = PackedVector2Array([
		direction * start_distance,
		direction * (start_distance + line_length),
	])
	add_child(line)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "position", direction * randf_range(34.0, 72.0), EFFECT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(line, "width", 0.5, EFFECT_DURATION)
	tween.tween_property(line, "modulate", Color(1, 1, 1, 0), EFFECT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
