class_name FirewallBurnVFX
extends Node2D

@export var animated_sprite_path: NodePath = ^"AnimatedSprite2D"
@export_range(0.01, 1.0, 0.01) var fade_out_duration := 0.16

var _stopping := false


func play_effect() -> void:
	_stopping = false
	modulate = Color.WHITE
	show()
	var animated_sprite := get_node_or_null(
		animated_sprite_path
	) as AnimatedSprite2D
	if animated_sprite == null:
		return
	animated_sprite.frame = 0
	animated_sprite.frame_progress = 0.0
	animated_sprite.play()


func stop_and_free() -> void:
	if _stopping:
		return
	_stopping = true
	var tween := create_tween()
	tween.tween_property(
		self,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.0),
		fade_out_duration
	)
	tween.tween_callback(queue_free)
