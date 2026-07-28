class_name IPSElectricityLink
extends Area2D

const ELECTRICITY_ANIMATION := &"Animated_Electricity"

@export var animated_sprite_path: NodePath = ^"AnimatedSprite2D"
@export var collision_shape_path: NodePath = ^"Hitbox"
@export_range(40.0, 600.0, 1.0) var visual_reference_length := 340.0
@export_range(4.0, 160.0, 1.0) var hitbox_width := 44.0

var first_spike: IPSIntrusionSpike
var second_spike: IPSIntrusionSpike

var _animated_sprite: AnimatedSprite2D
var _collision_shape: CollisionShape2D
var _base_visual_scale := Vector2.ONE
var _link_length := 0.0


func _ready() -> void:
	_animated_sprite = get_node_or_null(animated_sprite_path) as AnimatedSprite2D
	_collision_shape = get_node_or_null(collision_shape_path) as CollisionShape2D
	if _animated_sprite != null:
		_base_visual_scale = _animated_sprite.scale
	if _collision_shape != null and _collision_shape.shape != null:
		_collision_shape.shape = _collision_shape.shape.duplicate()
	_set_link_visible(false)


func configure(
	start_spike: IPSIntrusionSpike,
	end_spike: IPSIntrusionSpike
) -> void:
	first_spike = start_spike
	second_spike = end_spike
	sync_link()


func sync_link() -> bool:
	if not _endpoints_are_ready():
		_set_link_visible(false)
		return false

	var start_position := first_spike.global_position
	var end_position := second_spike.global_position
	var displacement := end_position - start_position
	_link_length = displacement.length()
	if _link_length <= 0.01:
		_set_link_visible(false)
		return false

	global_position = (start_position + end_position) * 0.5
	global_rotation = displacement.angle()
	if _animated_sprite != null:
		var stretch := _link_length / maxf(1.0, visual_reference_length)
		_animated_sprite.scale = _base_visual_scale * stretch
		if _animated_sprite.animation != ELECTRICITY_ANIMATION \
				or not _animated_sprite.is_playing():
			_animated_sprite.play(ELECTRICITY_ANIMATION)
	if _collision_shape != null:
		var rectangle := _collision_shape.shape as RectangleShape2D
		if rectangle != null:
			rectangle.size = Vector2(_link_length, hitbox_width)
	_set_link_visible(true)
	return true


func contains_follow(follow: PathFollow2D) -> bool:
	if not visible or not is_instance_valid(follow) or _link_length <= 0.0:
		return false

	var local_target := to_local(_get_follow_target_position(follow))
	return absf(local_target.x) <= _link_length * 0.5 \
		and absf(local_target.y) <= hitbox_width * 0.5


func get_link_length() -> float:
	return _link_length


func _endpoints_are_ready() -> bool:
	return is_instance_valid(first_spike) \
		and is_instance_valid(second_spike) \
		and first_spike.is_landed() \
		and second_spike.is_landed()


func _set_link_visible(value: bool) -> void:
	visible = value
	if _collision_shape != null:
		_collision_shape.disabled = not value


func _get_follow_target_position(follow: PathFollow2D) -> Vector2:
	for child in follow.get_children():
		var virus := child as RedVirus
		if virus != null:
			return virus.global_position
	return follow.global_position
