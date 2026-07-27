class_name ArmoredVirus
extends EvolvedVirus

const ARMOR_DESTROY_ANIMATION := &"armor_destroy"
const DEFAULT_RED_VIRUS_SCALE := Vector2(0.2, 0.2)

@export var armor_destroy_animation: StringName = ARMOR_DESTROY_ANIMATION
@export var red_virus_scene: PackedScene = preload("res://Scenes/Enemies/RedVirus.tscn")
@export var red_virus_spawn_scale := DEFAULT_RED_VIRUS_SCALE
@export var transformed_virus_name := "SpawnedRedVirus"

var _breaking_armor := false


func reset_for_spawn() -> void:
	_breaking_armor = false
	super.reset_for_spawn()


func take_damage(amount: int) -> bool:
	var damage := maxi(0, amount)
	if _breaking_armor or is_destroying() or damage <= 0:
		return false

	if current_health > damage:
		return super.take_damage(damage)

	current_health = 0
	health_changed.emit(current_health, maxi(1, max_health))
	_breaking_armor = true
	_destroying = true
	_play_destroy_sfx()
	_play_armor_destroy_and_transform()
	return false


func can_be_targeted_by(attacker: Node) -> bool:
	return not _breaking_armor and super.can_be_targeted_by(attacker)


func _play_armor_destroy_and_transform() -> void:
	_clear_damage_flash()
	set_visual_self_modulate(Color.WHITE)

	var armor_destroy_sprite := play_destroy_track(armor_destroy_animation)
	if armor_destroy_sprite != null:
		await armor_destroy_sprite.animation_finished

	if not is_inside_tree():
		return

	_transform_to_red_virus()


func _transform_to_red_virus() -> void:
	var follow := get_parent() as PathFollow2D
	if follow == null or red_virus_scene == null:
		queue_free()
		return

	var red_virus := red_virus_scene.instantiate() as RedVirus
	if red_virus == null:
		queue_free()
		return

	red_virus.name = transformed_virus_name
	red_virus.position = Vector2.ZERO
	follow.add_child(red_virus)
	follow.move_child(red_virus, 0)
	red_virus.global_scale = red_virus_spawn_scale
	red_virus.reset_for_spawn()

	hide()
	queue_free()
