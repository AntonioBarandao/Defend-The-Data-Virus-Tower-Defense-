extends SceneTree

const CASES := [
	{
		"path": "res://Scenes/Enemies/RedVirus.tscn",
		"idle": "IdleAnimation",
		"destroy": "DestroyAnimation",
		"destroy_animation": &"destroy",
	},
	{
		"path": "res://Scenes/Enemies/MutantVirus.tscn",
		"idle": "IdleAnimation",
		"destroy": "DestroyAnimation",
		"destroy_animation": &"destroy",
	},
	{
		"path": "res://Scenes/Enemies/ArmoredVirus.tscn",
		"idle": "IdleAnimation",
		"destroy": "ArmorDestroyAnimation",
		"destroy_animation": &"armor_destroy",
	},
]


func _initialize() -> void:
	for test_case in CASES:
		var scene := load(test_case.path) as PackedScene
		if not _require(scene != null, "%s could not be loaded." % test_case.path):
			return

		var virus := scene.instantiate() as RedVirus
		if not _require(virus != null, "%s has an incompatible root." % test_case.path):
			return
		root.add_child(virus)
		await process_frame

		var idle_sprite := virus.get_node_or_null(test_case.idle) as AnimatedSprite2D
		var destroy_sprite := virus.get_node_or_null(test_case.destroy) as AnimatedSprite2D
		if not _require(
			idle_sprite != null
				and destroy_sprite != null
				and idle_sprite.get_parent() == virus
				and destroy_sprite.get_parent() == virus,
			"%s does not expose sibling idle and destroy visual nodes." % test_case.path
		):
			return

		var original_idle_scale := idle_sprite.scale
		destroy_sprite.scale = Vector2(1.17, 1.17)
		if not _require(
			idle_sprite.scale == original_idle_scale,
			"%s cannot scale its destroy visual independently." % test_case.path
		):
			return

		var played_sprite := virus.play_destroy_track(test_case.destroy_animation)
		if not _require(
			played_sprite == destroy_sprite
				and destroy_sprite.visible
				and not idle_sprite.visible
				and destroy_sprite.animation == test_case.destroy_animation,
			"%s does not switch to its dedicated destroy visual." % test_case.path
		):
			return

		virus.play_idle()
		if not _require(
			idle_sprite.visible and not destroy_sprite.visible and idle_sprite.animation == &"idle",
			"%s does not restore its dedicated idle visual." % test_case.path
		):
			return

		virus.free()

	if not await _validate_armored_transformation():
		return

	print("Virus visual track validation passed: Red, Mutant, and Armored tracks use independently scalable sibling nodes.")
	quit(0)


func _validate_armored_transformation() -> bool:
	var scene := load("res://Scenes/Enemies/ArmoredVirus.tscn") as PackedScene
	var follow := PathFollow2D.new()
	root.add_child(follow)
	var armored := scene.instantiate() as ArmoredVirus
	follow.add_child(armored)
	await process_frame

	var armor_destroy_sprite := armored.get_node_or_null(
		"ArmorDestroyAnimation"
	) as AnimatedSprite2D
	armor_destroy_sprite.speed_scale = 100.0
	armored.take_damage(armored.max_health)
	if not _require(
		armor_destroy_sprite.visible and armor_destroy_sprite.is_playing(),
		"ArmoredVirus did not play its dedicated armor-destroy sibling."
	):
		return false

	for _frame_index in range(30):
		await process_frame
		if follow.get_node_or_null("SpawnedRedVirus") != null:
			break

	var transformed_red := follow.get_node_or_null("SpawnedRedVirus") as RedVirus
	if not _require(
		transformed_red != null
			and transformed_red.get_node_or_null("IdleAnimation") is AnimatedSprite2D,
		"ArmoredVirus did not transform into the refactored RedVirus scene."
	):
		return false

	follow.free()
	return true


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
