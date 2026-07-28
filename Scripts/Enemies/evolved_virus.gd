class_name EvolvedVirus
extends RedVirus

@export var damage_flash_enabled := false
@export var damage_flash_color := Color(1.0, 0.12, 0.12, 1.0)
@export_range(0.03, 0.6, 0.01) var damage_flash_seconds := 0.14

var _damage_flash_tween: Tween


func reset_for_spawn() -> void:
	_clear_damage_flash()
	super.reset_for_spawn()


func take_damage(amount: int) -> bool:
	var was_destroying := is_destroying()
	var health_before := current_health
	var destroyed := super.take_damage(amount)
	if damage_flash_enabled and not was_destroying and health_before > current_health and current_health > 0:
		_play_damage_flash()

	return destroyed


func _play_damage_flash() -> void:
	if _damage_flash_tween != null:
		_damage_flash_tween.kill()

	set_visual_self_modulate(damage_flash_color)
	_damage_flash_tween = create_tween()
	_damage_flash_tween.set_parallel(true)
	for visual in _get_visual_tracks():
		_damage_flash_tween.tween_property(
			visual,
			"self_modulate",
			Color.WHITE,
			damage_flash_seconds
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_damage_flash_tween.set_parallel(false)
	_damage_flash_tween.tween_callback(func() -> void:
		_damage_flash_tween = null
	)


func _clear_damage_flash() -> void:
	if _damage_flash_tween != null:
		_damage_flash_tween.kill()
		_damage_flash_tween = null
	set_visual_self_modulate(Color.WHITE)
