class_name SignalBoostBalance
extends RefCounted

const BONUS_PER_KNOWLEDGE_LEVEL := 0.15


static func get_profile(
	knowledge_level: int,
	unlock_knowledge_level: int = 1
) -> Dictionary:
	var effective_level := maxi(unlock_knowledge_level, knowledge_level)
	var stat_bonus := (
		float(effective_level)
		* BONUS_PER_KNOWLEDGE_LEVEL
	)
	var speed_multiplier := 1.0 + stat_bonus
	return {
		"damage_bonus": stat_bonus,
		"attack_speed_bonus": stat_bonus,
		"range_bonus": stat_bonus,
		"hawk_speed_bonus": stat_bonus,
		"damage_multiplier": 1.0 + stat_bonus,
		"range_multiplier": 1.0 + stat_bonus,
		"cooldown_multiplier": 1.0 / speed_multiplier,
		"hawk_speed_multiplier": speed_multiplier
	}
