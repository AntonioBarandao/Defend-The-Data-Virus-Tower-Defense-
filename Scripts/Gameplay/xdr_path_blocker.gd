@tool
class_name XDRPathBlocker
extends Node2D

const XDR_BLOCKER_COLLISION_LAYER := 1 << 20
const MINIMUM_SEGMENT_LENGTH := 0.5

@export var source_path: NodePath = ^"../VirusElements/Path2D":
	set(value):
		source_path = value
		_request_rebuild()
@export_range(40.0, 320.0, 2.0) var corridor_width := 60.0:
	set(value):
		corridor_width = maxf(40.0, value)
		_request_rebuild()
@export var trace_color := Color(1.0, 0.08, 0.06, 0.3):
	set(value):
		trace_color = value
		_request_rebuild()
@export var show_trace_in_game := false:
	set(value):
		show_trace_in_game = value
		_sync_trace_visibility()

var _trace: Line2D
var _static_body: StaticBody2D
var _last_source_signature := ""
var _rebuild_queued := false


func _ready() -> void:
	add_to_group("XDR_PATH_BLOCKER")
	_trace = get_node_or_null(^"Trace") as Line2D
	_static_body = get_node_or_null(^"StaticBody2D") as StaticBody2D
	if _static_body != null:
		_static_body.collision_layer = XDR_BLOCKER_COLLISION_LAYER
		_static_body.collision_mask = 0
		_static_body.add_to_group("XDR_PATH_BLOCKER")
	_sync_trace_visibility()
	_rebuild_from_source()
	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	var signature := _get_source_signature()
	if signature != _last_source_signature:
		_rebuild_from_source()


func rebuild_from_source() -> void:
	_rebuild_from_source()


func get_corridor_width() -> float:
	return corridor_width


func get_collision_layer_value() -> int:
	return XDR_BLOCKER_COLLISION_LAYER


func _request_rebuild() -> void:
	if not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild_from_source")


func _rebuild_from_source() -> void:
	_rebuild_queued = false
	if not is_inside_tree():
		return
	if _trace == null:
		_trace = get_node_or_null(^"Trace") as Line2D
	if _static_body == null:
		_static_body = get_node_or_null(^"StaticBody2D") as StaticBody2D
	if _trace == null or _static_body == null:
		return

	var source := get_node_or_null(source_path) as Path2D
	if source == null or source.curve == null:
		_trace.clear_points()
		_clear_collision_shapes()
		_last_source_signature = ""
		return

	var local_points := PackedVector2Array()
	for source_point in source.curve.get_baked_points():
		local_points.append(to_local(source.to_global(source_point)))
	if local_points.size() < 2:
		for point_index in range(source.curve.point_count):
			local_points.append(to_local(source.to_global(source.curve.get_point_position(point_index))))

	_trace.width = corridor_width
	_trace.default_color = trace_color
	_trace.points = local_points
	_sync_trace_visibility()
	_rebuild_collision_shapes(local_points)
	_last_source_signature = _get_source_signature()


func _rebuild_collision_shapes(points: PackedVector2Array) -> void:
	_clear_collision_shapes()
	if points.size() < 2:
		return

	var half_width := corridor_width * 0.5
	for index in range(points.size() - 1):
		var start := points[index]
		var finish := points[index + 1]
		var segment := finish - start
		var length := segment.length()
		if length <= MINIMUM_SEGMENT_LENGTH:
			continue

		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(length, corridor_width)
		var collision := CollisionShape2D.new()
		collision.name = "PathSegment%03d" % index
		collision.position = (start + finish) * 0.5
		collision.rotation = segment.angle()
		collision.shape = rectangle
		collision.debug_color = trace_color
		_static_body.add_child(collision)

	for index in range(points.size()):
		var circle := CircleShape2D.new()
		circle.radius = half_width
		var joint_collision := CollisionShape2D.new()
		joint_collision.name = "PathJoint%03d" % index
		joint_collision.position = points[index]
		joint_collision.shape = circle
		joint_collision.debug_color = trace_color
		_static_body.add_child(joint_collision)


func _clear_collision_shapes() -> void:
	if _static_body == null:
		return
	for child in _static_body.get_children():
		_static_body.remove_child(child)
		child.queue_free()


func _sync_trace_visibility() -> void:
	if _trace != null:
		_trace.visible = Engine.is_editor_hint() or show_trace_in_game


func _get_source_signature() -> String:
	var source := get_node_or_null(source_path) as Path2D
	if source == null or source.curve == null:
		return ""
	var values := PackedStringArray([
		str(global_transform),
		str(source.global_transform),
		str(source.curve.bake_interval),
		str(source.curve.point_count),
		str(corridor_width),
		str(trace_color),
	])
	for point_index in range(source.curve.point_count):
		values.append(str(source.curve.get_point_position(point_index)))
		values.append(str(source.curve.get_point_in(point_index)))
		values.append(str(source.curve.get_point_out(point_index)))
	return "|".join(values)
