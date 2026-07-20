extends SceneTree

const TOWER_SCENES := [
	"res://Scenes/Towers/CyberGuardian.tscn",
	"res://Scenes/Towers/LaserTurret.tscn",
	"res://Scenes/Towers/SIEM_Hawk.tscn",
	"res://Scenes/Towers/IPS_Intrusion.tscn",
	"res://Scenes/Towers/Honeypot_Production.tscn"
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	host.name = "RadiusCleanupTest"
	root.add_child(host)
	current_scene = host

	for index in TOWER_SCENES.size():
		var packed_scene := load(TOWER_SCENES[index]) as PackedScene
		var tower := packed_scene.instantiate() as Node2D
		tower.name = "RadiusOwner%d" % index
		host.add_child(tower)
		await process_frame

		tower.call("set_menu_range_preview_active", true)
		await process_frame
		var fill := host.get_node_or_null("%sRangePreviewFill" % tower.name) as Polygon2D
		var outline := host.get_node_or_null("%sRangePreviewOutline" % tower.name) as Line2D
		if fill == null or outline == null:
			push_error("Tower did not create its external range preview: %s" % TOWER_SCENES[index])
			quit(1)
			return

		tower.call("clear_range_preview")
		if fill.visible or outline.visible:
			push_error("Tower range preview remained visible during cleanup: %s" % TOWER_SCENES[index])
			quit(1)
			return
		await process_frame
		await process_frame
		if is_instance_valid(fill) or is_instance_valid(outline):
			push_error("Tower range preview was not freed: %s" % TOWER_SCENES[index])
			quit(1)
			return

		tower.queue_free()
		await process_frame

	print("Tower radius cleanup validation passed.")
	quit(0)
