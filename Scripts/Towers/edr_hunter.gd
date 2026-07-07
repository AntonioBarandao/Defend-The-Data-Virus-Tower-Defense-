class_name EDRHunterTower
extends CyberGuardianTower

const EDR_MAX_LEVEL := 5
const EDR_DAMAGE := 10
const EDR_ATTACK_RANGE := 100000.0
const EDR_COOLDOWN := 3.0
const EDR_LASER_WIDTH := 12.0
const EDR_UPGRADE_COSTS := [0, 0, 0, 0, 0]


func _ready() -> void:
	show_attack_range_preview = false
	super._ready()


func set_menu_range_preview_active(_active: bool) -> void:
	super.set_menu_range_preview_active(false)


func get_shot_power() -> int:
	return EDR_DAMAGE


func get_attack_range() -> float:
	return EDR_ATTACK_RANGE * _get_signal_boost_range_multiplier()


func get_shot_cooldown() -> float:
	return EDR_COOLDOWN * _get_signal_boost_cooldown_multiplier()


func get_laser_width() -> float:
	return EDR_LASER_WIDTH


func get_max_level() -> int:
	return EDR_MAX_LEVEL


func can_upgrade() -> bool:
	return level < EDR_MAX_LEVEL


func get_upgrade_cost() -> int:
	if not can_upgrade():
		return 0

	return int(EDR_UPGRADE_COSTS[level])


func upgrade() -> bool:
	if not can_upgrade():
		return false

	level += 1
	return true


func can_scan_cloaked_viruses() -> bool:
	return true
