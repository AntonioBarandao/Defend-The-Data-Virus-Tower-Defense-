extends SceneTree

const EXPECTED_CORRIDOR_WIDTH := 60.0


func _initialize() -> void:
	var gameplay_scene := load("res://Scenes/Gameplay/Normal_Game.tscn") as PackedScene
	if not _require(gameplay_scene != null, "Normal Game could not be loaded."):
		return
	var gameplay := gameplay_scene.instantiate()
	root.add_child(gameplay)
	await process_frame
	await physics_frame

	var blocker := gameplay.get_node_or_null("XDRPathBlocker") as XDRPathBlocker
	if not _require(blocker != null, "XDRPathBlocker is missing from the gameplay scene."):
		return
	var trace := blocker.get_node_or_null("Trace") as Line2D
	var body := blocker.get_node_or_null("StaticBody2D") as StaticBody2D
	if not _require(trace != null and trace.points.size() >= 30, "The red blocker trace did not copy the virus pathway."):
		return
	if Engine.is_editor_hint() and not _require(trace.visible, "The red blocker trace is hidden in the Normal Game editor viewport."):
		return
	if not _require(is_equal_approx(blocker.get_corridor_width(), EXPECTED_CORRIDOR_WIDTH), "The blocker does not use the authored 60px corridor width."):
		return
	if not _require(is_equal_approx(trace.width, EXPECTED_CORRIDOR_WIDTH), "The blocker trace does not match the authored corridor width."):
		return
	if not _require(body != null and body.get_child_count() >= trace.points.size(), "The blocker collision shapes were not generated."):
		return
	if not _require(body.collision_layer == XDRPathBlocker.XDR_BLOCKER_COLLISION_LAYER, "The blocker is on the wrong physics layer."):
		return
	var segment_shape_count := 0
	var joint_shape_count := 0
	for child in body.get_children():
		var collision := child as CollisionShape2D
		if collision == null:
			continue
		if collision.shape is RectangleShape2D:
			segment_shape_count += 1
			var rectangle := collision.shape as RectangleShape2D
			if not _require(is_equal_approx(rectangle.size.y, EXPECTED_CORRIDOR_WIDTH), "A StaticBody2D path segment does not match the 60px corridor width."):
				return
		elif collision.shape is CircleShape2D:
			joint_shape_count += 1
			var circle := collision.shape as CircleShape2D
			if not _require(is_equal_approx(circle.radius * 2.0, EXPECTED_CORRIDOR_WIDTH), "A StaticBody2D path joint does not match the 60px corridor width."):
				return
	if not _require(segment_shape_count > 0 and joint_shape_count > 0, "The blocker did not generate both path segments and joints."):
		return

	var tower_scene := load("res://Scenes/Towers/XDR_Mech.tscn") as PackedScene
	var mech := tower_scene.instantiate() as XDRMechTower
	gameplay.add_child(mech)
	await process_frame
	await physics_frame
	mech.set_process(false)
	var mech_collision := mech.get_node_or_null("MovementCollision/CollisionShape2D") as CollisionShape2D
	if not _require(mech_collision != null and mech_collision.shape is RectangleShape2D, "The XDR movement collision is not an editable rectangle in its scene."):
		return
	var deployment_slots := [
		Vector2(396.0, 220.0), Vector2(1437.0, 398.0), Vector2(1214.0, 511.0),
		Vector2(590.0, 472.0), Vector2(794.0, 89.0), Vector2(1085.0, 218.0),
		Vector2(1668.0, 232.0), Vector2(1619.0, 578.0), Vector2(1466.0, 716.0),
		Vector2(762.0, 703.0), Vector2(190.0, 574.0), Vector2(491.0, 860.0),
		Vector2(1231.0, 820.0),
	]
	for slot_position in deployment_slots:
		var route_distance := _distance_to_trace(trace, slot_position)
		if not _require(not mech._would_collide_with_virus_path(slot_position), "A deployment slot overlaps the XDR pathway blocker at %s (route distance %.2f)." % [slot_position, route_distance]):
			return
	mech.global_position = Vector2(250.0, 140.0)
	mech.set("_placed", true)
	mech.destination_turn_seconds = 0.0
	mech.set_dispatched(true)
	if not _require(mech.set_dispatch_destination(Vector2(250.0, 500.0)), "The XDR test destination was rejected."):
		return

	for step in range(60):
		mech._process(0.1)
	if not _require(not mech.has_dispatch_destination(), "The blocked destination was not canceled after three seconds."):
		return
	if not _require(not mech._would_collide_with_virus_path(mech.global_position), "The XDR Mech stopped while overlapping the virus pathway corridor."):
		return
	var marker := mech.get_node_or_null("DestinationMarker") as Node2D
	if not _require(marker != null and not marker.visible, "The canceled destination marker is still visible."):
		return

	gameplay.free()
	print("XDR path blocker validation passed: traced corridor, generated collisions, blocked movement, and timed destination cancellation.")
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false


func _distance_to_trace(trace: Line2D, world_position: Vector2) -> float:
	var local_position := trace.to_local(world_position)
	var closest_distance := INF
	for index in range(trace.points.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(local_position, trace.points[index], trace.points[index + 1])
		closest_distance = minf(closest_distance, local_position.distance_to(closest))
	return closest_distance
