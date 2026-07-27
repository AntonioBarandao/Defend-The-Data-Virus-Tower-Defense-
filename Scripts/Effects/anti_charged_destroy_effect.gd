class_name AntiChargedDestroyEffect
extends Node2D

const STAR_COUNT := 11
const EFFECT_DURATION := 0.62
const TOP_DOWN_Y_SCALE := 0.62
const STAR_COLOR := Color("#FF2438")
const STAR_HIGHLIGHT := Color("#FF8A94")


func _ready() -> void:
	z_as_relative = false
	for index in range(STAR_COUNT):
		_spawn_star(index)

	var cleanup_tween := create_tween()
	cleanup_tween.tween_interval(EFFECT_DURATION + 0.08)
	cleanup_tween.tween_callback(queue_free)


func _spawn_star(index: int) -> void:
	var angle := TAU * float(index) / float(STAR_COUNT) + randf_range(-0.16, 0.16)
	var direction := Vector2(cos(angle), sin(angle) * TOP_DOWN_Y_SCALE).normalized()
	var star := Polygon2D.new()
	star.name = "RedDestroyStar"
	star.polygon = _make_star_polygon(randf_range(7.0, 12.0), randf_range(3.0, 5.0))
	star.color = STAR_COLOR.lerp(STAR_HIGHLIGHT, randf_range(0.0, 0.48))
	star.position = direction * randf_range(8.0, 22.0)
	star.rotation = randf_range(-PI, PI)
	star.scale = Vector2.ONE * randf_range(0.65, 1.15)
	add_child(star)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		star,
		"position",
		direction * randf_range(48.0, 92.0),
		EFFECT_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		star,
		"rotation",
		star.rotation + randf_range(-2.6, 2.6),
		EFFECT_DURATION
	)
	tween.tween_property(
		star,
		"scale",
		Vector2.ZERO,
		EFFECT_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(
		star,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.0),
		EFFECT_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _make_star_polygon(outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(10):
		var radius := outer_radius if point_index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + TAU * float(point_index) / 10.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
