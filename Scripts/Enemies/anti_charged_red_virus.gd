class_name AntiChargedRedVirus
extends EvolvedVirus

const DestroyEffect := preload(
	"res://Scripts/Effects/anti_charged_destroy_effect.gd"
)


func play_destroy_and_queue_owner(owner: Node) -> void:
	_spawn_red_star_destroy_effect(owner)
	hide()

	var cleanup_tween := create_tween()
	cleanup_tween.tween_interval(0.7)
	if owner != null:
		cleanup_tween.tween_callback(Callable(owner, "queue_free"))
	else:
		cleanup_tween.tween_callback(queue_free)


func is_anti_charged() -> bool:
	return true


func _spawn_red_star_destroy_effect(owner: Node) -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null and owner != null:
		scene_root = owner
		while scene_root.get_parent() != null \
				and scene_root.get_parent() != get_tree().root:
			scene_root = scene_root.get_parent()
	if scene_root == null:
		return

	var effect := DestroyEffect.new() as AntiChargedDestroyEffect
	effect.name = "AntiChargedDestroyEffect"
	scene_root.add_child(effect)
	effect.global_position = global_position
	effect.z_index = z_index + 2
