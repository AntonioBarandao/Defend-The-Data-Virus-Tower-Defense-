class_name WaveManager
extends RefCounted

const RED_VIRUS := &"red_virus"
const MUTANT_VIRUS := &"mutant_virus"
const ARMORED_VIRUS := &"armored_virus"
const TROJAN_HORSE := &"trojan_horse"
const ADWARE := &"adware"
const SPYWARE := &"spyware"
const ZOMBIE_NODE_MINION := &"zombie_node_minion"
const ZOMBIE_NODE := &"zombie_node"
const BOTNET_NODE := &"botnet_node"
const WORM_BOSS := &"worm_boss"
const PHISHING_EMAIL := &"phishing_email"

const BEGINNING := &"beginning"
const MIDDLE := &"middle"
const END := &"end"
const LEADING_VIRUS_1 := &"leading_virus_1"
const LEADING_VIRUS_2 := &"leading_virus_2"
const LEADING_VIRUS_3 := &"leading_virus_3"

const VIRUS_TYPES := [
	RED_VIRUS,
	MUTANT_VIRUS,
	ARMORED_VIRUS,
	TROJAN_HORSE,
	ADWARE,
	SPYWARE,
	ZOMBIE_NODE_MINION,
	PHISHING_EMAIL,
]

const PROGRESSIVE_BOSS_TYPES := [
	ZOMBIE_NODE,
	BOTNET_NODE,
	WORM_BOSS,
]

const PATHWAY_VIRUS_TYPES := [
	RED_VIRUS,
	MUTANT_VIRUS,
	ARMORED_VIRUS,
	TROJAN_HORSE,
	ADWARE,
	SPYWARE,
	ZOMBIE_NODE_MINION,
]

const SPAWN_MARKERS := [
	BEGINNING,
	MIDDLE,
	END,
]

const LEADING_VIRUS_KEYS := [
	LEADING_VIRUS_1,
	LEADING_VIRUS_2,
	LEADING_VIRUS_3,
]

const VIRUS_SCENE_PATHS := {
	RED_VIRUS: "res://Scenes/Enemies/RedVirus.tscn",
	MUTANT_VIRUS: "res://Scenes/Enemies/MutantVirus.tscn",
	ARMORED_VIRUS: "res://Scenes/Enemies/ArmoredVirus.tscn",
	TROJAN_HORSE: "res://Scenes/Enemies/TrojanHorse.tscn",
	ADWARE: "res://Scenes/Enemies/Adware.tscn",
	SPYWARE: "res://Scenes/Enemies/Spyware.tscn",
	ZOMBIE_NODE_MINION: "res://Scenes/Enemies/ZombieNodeMinion.tscn",
	PHISHING_EMAIL: "res://Scenes/Enemies/PhishingEmail.tscn",
}

const PROGRESSIVE_BOSS_SCENE_PATHS := {
	ZOMBIE_NODE: "res://Scenes/Enemies/ZombieNode.tscn",
	BOTNET_NODE: "res://Scenes/Enemies/BotnetNode.tscn",
	WORM_BOSS: "res://Scenes/Enemies/WormBoss.tscn",
}

# Each wave has three ordered leader slots followed by beginning, middle, and
# end markers. Marker counts determine the concentration after the leaders.
const WAVE_DATABASE := {
	1: {
		"spawn_duration_seconds": 15.0,
		"leading_virus_1": "red_virus",
		"leading_virus_2": "red_virus",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 6, "middle": 6, "end": 5},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 20, "mutant_virus": 0, "armored_virus": 0,
			"trojan_horse": 0, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	2: {
		"spawn_duration_seconds": 15.0,
		"leading_virus_1": "red_virus",
		"leading_virus_2": "red_virus",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 10, "middle": 10, "end": 10},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 33, "mutant_virus": 0, "armored_virus": 0,
			"trojan_horse": 0, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	3: {
		"spawn_duration_seconds": 15.0,
		"leading_virus_1": "red_virus",
		"leading_virus_2": "red_virus",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 11, "middle": 11, "end": 11},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 36, "mutant_virus": 0, "armored_virus": 0,
			"trojan_horse": 0, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	4: {
		"spawn_duration_seconds": 15.0,
		"leading_virus_1": "red_virus",
		"leading_virus_2": "red_virus",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 12, "middle": 12, "end": 12},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 39, "mutant_virus": 0, "armored_virus": 0,
			"trojan_horse": 0, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	5: {
		"spawn_duration_seconds": 30.0,
		"leading_virus_1": "trojan_horse",
		"leading_virus_2": "red_virus",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 13, "middle": 13, "end": 13},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 41, "mutant_virus": 0, "armored_virus": 0,
			"trojan_horse": 1, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	6: {
		"spawn_duration_seconds": 30.0,
		"leading_virus_1": "trojan_horse",
		"leading_virus_2": "red_virus",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 14, "middle": 14, "end": 14},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 44, "mutant_virus": 0, "armored_virus": 0,
			"trojan_horse": 1, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	7: {
		"spawn_duration_seconds": 30.0,
		"leading_virus_1": "armored_virus",
		"leading_virus_2": "trojan_horse",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 16, "middle": 15, "end": 15},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 47, "mutant_virus": 0, "armored_virus": 1,
			"trojan_horse": 1, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	8: {
		"spawn_duration_seconds": 30.0,
		"leading_virus_1": "armored_virus",
		"leading_virus_2": "trojan_horse",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 16, "middle": 16, "end": 16},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 49, "mutant_virus": 0, "armored_virus": 1,
			"trojan_horse": 1, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	9: {
		"spawn_duration_seconds": 30.0,
		"leading_virus_1": "trojan_horse",
		"leading_virus_2": "armored_virus",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 17, "middle": 17, "end": 17},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 52, "mutant_virus": 0, "armored_virus": 1,
			"trojan_horse": 1, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	10: {
		"spawn_duration_seconds": 60.0,
		"leading_virus_1": "armored_virus",
		"leading_virus_2": "trojan_horse",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 19, "middle": 18, "end": 18},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 55, "mutant_virus": 0, "armored_virus": 2,
			"trojan_horse": 1, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	11: {
		"spawn_duration_seconds": 60.0,
		"leading_virus_1": "trojan_horse",
		"leading_virus_2": "armored_virus",
		"leading_virus_3": "red_virus",
		"markers": {"beginning": 19, "middle": 19, "end": 19},
		"progressive_boss": {"name": "zombie_node", "level": 1},
		"viruses": {
			"red_virus": 57, "mutant_virus": 0, "armored_virus": 2,
			"trojan_horse": 1, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	12: {
		"spawn_duration_seconds": 60.0,
		"leading_virus_1": "adware",
		"leading_virus_2": "armored_virus",
		"leading_virus_3": "trojan_horse",
		"markers": {"beginning": 21, "middle": 20, "end": 20},
		"progressive_boss": {"name": "zombie_node", "level": 1},
		"viruses": {
			"red_virus": 60, "mutant_virus": 0, "armored_virus": 2,
			"trojan_horse": 1, "adware": 1, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	13: {
		"spawn_duration_seconds": 60.0,
		"leading_virus_1": "mutant_virus",
		"leading_virus_2": "armored_virus",
		"leading_virus_3": "trojan_horse",
		"markers": {"beginning": 22, "middle": 22, "end": 21},
		"progressive_boss": {"name": "zombie_node", "level": 4},
		"viruses": {
			"red_virus": 63, "mutant_virus": 1, "armored_virus": 3,
			"trojan_horse": 1, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	14: {
		"spawn_duration_seconds": 60.0,
		"leading_virus_1": "adware",
		"leading_virus_2": "mutant_virus",
		"leading_virus_3": "armored_virus",
		"markers": {"beginning": 23, "middle": 23, "end": 22},
		"progressive_boss": {"name": "zombie_node", "level": 4},
		"viruses": {
			"red_virus": 65, "mutant_virus": 1, "armored_virus": 3,
			"trojan_horse": 1, "adware": 1, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	15: {
		"spawn_duration_seconds": 120.0,
		"leading_virus_1": "trojan_horse",
		"leading_virus_2": "mutant_virus",
		"leading_virus_3": "armored_virus",
		"markers": {"beginning": 24, "middle": 24, "end": 23},
		"progressive_boss": {"name": "zombie_node", "level": 5},
		"viruses": {
			"red_virus": 68, "mutant_virus": 2, "armored_virus": 3,
			"trojan_horse": 1, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	16: {
		"spawn_duration_seconds": 120.0,
		"leading_virus_1": "spyware",
		"leading_virus_2": "adware",
		"leading_virus_3": "trojan_horse",
		"markers": {"beginning": 78, "middle": 77, "end": 77},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 212, "mutant_virus": 7, "armored_virus": 11,
			"trojan_horse": 3, "adware": 1, "spyware": 1,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	17: {
		"spawn_duration_seconds": 120.0,
		"leading_virus_1": "armored_virus",
		"leading_virus_2": "mutant_virus",
		"leading_virus_3": "trojan_horse",
		"markers": {"beginning": 81, "middle": 80, "end": 80},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 220, "mutant_virus": 9, "armored_virus": 12,
			"trojan_horse": 3, "adware": 0, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	18: {
		"spawn_duration_seconds": 120.0,
		"leading_virus_1": "adware",
		"leading_virus_2": "spyware",
		"leading_virus_3": "trojan_horse",
		"markers": {"beginning": 86, "middle": 85, "end": 85},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 228, "mutant_virus": 11, "armored_virus": 14,
			"trojan_horse": 4, "adware": 1, "spyware": 1,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	19: {
		"spawn_duration_seconds": 120.0,
		"leading_virus_1": "spyware",
		"leading_virus_2": "mutant_virus",
		"leading_virus_3": "armored_virus",
		"markers": {"beginning": 89, "middle": 89, "end": 89},
		"progressive_boss": {"name": "", "level": 0},
		"viruses": {
			"red_virus": 236, "mutant_virus": 13, "armored_virus": 16,
			"trojan_horse": 4, "adware": 0, "spyware": 1,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	20: {
		"spawn_duration_seconds": 180.0,
		"leading_virus_1": "trojan_horse",
		"leading_virus_2": "armored_virus",
		"leading_virus_3": "mutant_virus",
		"markers": {"beginning": 94, "middle": 93, "end": 93},
		"progressive_boss": {"name": "worm_boss", "level": 1},
		"viruses": {
			"red_virus": 244, "mutant_virus": 16, "armored_virus": 18,
			"trojan_horse": 4, "adware": 1, "spyware": 0,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	21: {
		"spawn_duration_seconds": 180.0,
		"leading_virus_1": "adware",
		"leading_virus_2": "spyware",
		"leading_virus_3": "armored_virus",
		"markers": {"beginning": 98, "middle": 98, "end": 97},
		"progressive_boss": {"name": "botnet_node", "level": 1},
		"viruses": {
			"red_virus": 252, "mutant_virus": 18, "armored_virus": 20,
			"trojan_horse": 4, "adware": 1, "spyware": 1,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	22: {
		"spawn_duration_seconds": 180.0,
		"leading_virus_1": "spyware",
		"leading_virus_2": "trojan_horse",
		"leading_virus_3": "mutant_virus",
		"markers": {"beginning": 102, "middle": 102, "end": 101},
		"progressive_boss": {"name": "botnet_node", "level": 1},
		"viruses": {
			"red_virus": 260, "mutant_virus": 20, "armored_virus": 22,
			"trojan_horse": 5, "adware": 0, "spyware": 1,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	23: {
		"spawn_duration_seconds": 180.0,
		"leading_virus_1": "adware",
		"leading_virus_2": "spyware",
		"leading_virus_3": "trojan_horse",
		"markers": {"beginning": 107, "middle": 106, "end": 106},
		"progressive_boss": {"name": "botnet_node", "level": 2},
		"viruses": {
			"red_virus": 268, "mutant_virus": 23, "armored_virus": 24,
			"trojan_horse": 5, "adware": 1, "spyware": 1,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	24: {
		"spawn_duration_seconds": 180.0,
		"leading_virus_1": "spyware",
		"leading_virus_2": "adware",
		"leading_virus_3": "mutant_virus",
		"markers": {"beginning": 111, "middle": 111, "end": 111},
		"progressive_boss": {"name": "botnet_node", "level": 2},
		"viruses": {
			"red_virus": 276, "mutant_virus": 26, "armored_virus": 26,
			"trojan_horse": 5, "adware": 1, "spyware": 2,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
	25: {
		"spawn_duration_seconds": 180.0,
		"leading_virus_1": "trojan_horse",
		"leading_virus_2": "adware",
		"leading_virus_3": "spyware",
		"markers": {"beginning": 117, "middle": 117, "end": 117},
		"progressive_boss": {"name": "botnet_node", "level": 3},
		"viruses": {
			"red_virus": 284, "mutant_virus": 30, "armored_virus": 30,
			"trojan_horse": 6, "adware": 2, "spyware": 2,
			"zombie_node_minion": 0, "phishing_email": 0,
		},
	},
}


func has_wave(wave_number: int) -> bool:
	return WAVE_DATABASE.has(wave_number)


func get_wave_definition(wave_number: int) -> Dictionary:
	return _get_wave_database_entry(wave_number).duplicate(true)


func get_spawn_duration_seconds(wave_number: int) -> float:
	return maxf(
		0.0,
		float(_get_wave_database_entry(wave_number).get("spawn_duration_seconds", 0.0))
	)


func get_virus_amount(wave_number: int, virus_type: StringName) -> int:
	if not VIRUS_TYPES.has(virus_type):
		return 0
	var viruses := _get_wave_database_entry(wave_number).get("viruses", {}) as Dictionary
	return maxi(0, int(viruses.get(String(virus_type), 0)))


func get_virus_scene_path(virus_type: StringName) -> String:
	return String(VIRUS_SCENE_PATHS.get(virus_type, ""))


func get_progressive_boss_name(wave_number: int) -> StringName:
	var boss := _get_wave_database_entry(wave_number).get(
		"progressive_boss",
		{}
	) as Dictionary
	var boss_name := StringName(boss.get("name", ""))
	return boss_name if PROGRESSIVE_BOSS_TYPES.has(boss_name) else &""


func get_progressive_boss_level(wave_number: int) -> int:
	if get_progressive_boss_name(wave_number).is_empty():
		return 0
	var boss := _get_wave_database_entry(wave_number).get(
		"progressive_boss",
		{}
	) as Dictionary
	return maxi(0, int(boss.get("level", 0)))


func get_progressive_boss_scene_path(boss_name: StringName) -> String:
	return String(PROGRESSIVE_BOSS_SCENE_PATHS.get(boss_name, ""))


func has_progressive_boss(wave_number: int) -> bool:
	return not get_progressive_boss_name(wave_number).is_empty() \
		and get_progressive_boss_level(wave_number) > 0


func get_leading_virus_name(wave_number: int, leader_slot: int) -> StringName:
	if leader_slot < 1 or leader_slot > LEADING_VIRUS_KEYS.size():
		return &""
	var leader_key: StringName = LEADING_VIRUS_KEYS[leader_slot - 1]
	return StringName(
		_get_wave_database_entry(wave_number).get(String(leader_key), "")
	)


func get_leading_viruses(wave_number: int) -> Array[StringName]:
	var leaders: Array[StringName] = []
	var remaining_counts := {}
	for virus_type in PATHWAY_VIRUS_TYPES:
		remaining_counts[virus_type] = get_virus_amount(wave_number, virus_type)

	for leader_slot in range(1, LEADING_VIRUS_KEYS.size() + 1):
		var virus_type := get_leading_virus_name(wave_number, leader_slot)
		if not PATHWAY_VIRUS_TYPES.has(virus_type):
			continue
		if int(remaining_counts.get(virus_type, 0)) <= 0:
			continue
		leaders.append(virus_type)
		remaining_counts[virus_type] = int(remaining_counts[virus_type]) - 1

	return leaders


func get_marker_virus_count(wave_number: int, marker: StringName) -> int:
	if not SPAWN_MARKERS.has(marker):
		return 0
	var counts := _get_balanced_marker_counts(wave_number)
	return maxi(0, int(counts.get(marker, 0)))


func get_total_pathway_virus_count(wave_number: int) -> int:
	var total := 0
	for virus_type in PATHWAY_VIRUS_TYPES:
		total += get_virus_amount(wave_number, virus_type)
	return total


func build_spawn_schedule(wave_number: int) -> Array[Dictionary]:
	var schedule: Array[Dictionary] = []
	var leaders := get_leading_viruses(wave_number)
	var virus_queue := _build_weighted_virus_queue(wave_number, leaders)
	if leaders.is_empty() and virus_queue.is_empty():
		return schedule

	var raw_slots: Array[Dictionary] = []
	var marker_counts := _get_balanced_marker_counts(wave_number)
	var duration := get_spawn_duration_seconds(wave_number)
	var segment_duration := duration / float(SPAWN_MARKERS.size() + 1)

	for leader_index in range(leaders.size()):
		var centered_progress := (
			(float(leader_index) + 0.5)
			/ float(leaders.size())
		)
		raw_slots.append({
			"marker": LEADING_VIRUS_KEYS[leader_index],
			"virus_type": leaders[leader_index],
			"raw_time_seconds": centered_progress * segment_duration,
		})

	for marker_index in range(SPAWN_MARKERS.size()):
		var marker: StringName = SPAWN_MARKERS[marker_index]
		var marker_count := int(marker_counts.get(marker, 0))
		if marker_count <= 0:
			continue

		var marker_start := segment_duration * float(marker_index + 1)
		for spawn_index in range(marker_count):
			var centered_progress := (float(spawn_index) + 0.5) / float(marker_count)
			raw_slots.append({
				"marker": marker,
				"raw_time_seconds": marker_start + (centered_progress * segment_duration),
			})

	var first_raw_time := float(raw_slots.front().get("raw_time_seconds", 0.0))
	var last_raw_time := float(raw_slots.back().get("raw_time_seconds", duration))
	var raw_time_span := last_raw_time - first_raw_time

	var queue_index := 0
	for schedule_index in range(raw_slots.size()):
		var raw_slot := raw_slots[schedule_index]
		var spawn_time := 0.0
		if raw_time_span > 0.0:
			spawn_time = (
				(float(raw_slot.get("raw_time_seconds", 0.0)) - first_raw_time)
				/ raw_time_span
			) * duration
		var virus_type := StringName(raw_slot.get("virus_type", &""))
		if virus_type.is_empty() and queue_index < virus_queue.size():
			virus_type = virus_queue[queue_index]
			queue_index += 1
		schedule.append({
			"marker": raw_slot.get("marker", BEGINNING),
			"virus_type": virus_type,
			"spawn_time_seconds": spawn_time,
		})

	return schedule


func build_spawn_queue(wave_number: int) -> Array[StringName]:
	var queue: Array[StringName] = []
	for instruction in build_spawn_schedule(wave_number):
		queue.append(StringName(instruction.get("virus_type", RED_VIRUS)))
	return queue


func _build_weighted_virus_queue(
	wave_number: int,
	leaders: Array[StringName]
) -> Array[StringName]:
	var queue: Array[StringName] = []
	var remaining_counts := {}
	for virus_type in PATHWAY_VIRUS_TYPES:
		remaining_counts[virus_type] = get_virus_amount(wave_number, virus_type)
	for leader in leaders:
		remaining_counts[leader] = maxi(0, int(remaining_counts[leader]) - 1)

	var total_count := 0
	for virus_type in PATHWAY_VIRUS_TYPES:
		total_count += int(remaining_counts[virus_type])
	if total_count <= 0:
		return queue

	var current_weights := {}
	var emitted_counts := {}
	for virus_type in PATHWAY_VIRUS_TYPES:
		current_weights[virus_type] = 0
		emitted_counts[virus_type] = 0

	for _spawn_index in range(total_count):
		var selected_type: StringName = &""
		var selected_weight := -INF
		for virus_type in PATHWAY_VIRUS_TYPES:
			var configured_count := int(remaining_counts[virus_type])
			if int(emitted_counts[virus_type]) >= configured_count:
				continue

			current_weights[virus_type] = int(current_weights[virus_type]) + configured_count
			var candidate_weight := float(current_weights[virus_type])
			if selected_type.is_empty() or candidate_weight > selected_weight:
				selected_type = virus_type
				selected_weight = candidate_weight

		if selected_type.is_empty():
			break

		queue.append(selected_type)
		emitted_counts[selected_type] = int(emitted_counts[selected_type]) + 1
		current_weights[selected_type] = int(current_weights[selected_type]) - total_count

	return queue


func _get_balanced_marker_counts(wave_number: int) -> Dictionary:
	var marker_counts := {}
	var definition := _get_wave_database_entry(wave_number)
	var configured_markers := definition.get("markers", {}) as Dictionary
	for marker in SPAWN_MARKERS:
		marker_counts[marker] = maxi(
			0,
			int(configured_markers.get(String(marker), 0))
		)

	var target_count := (
		get_total_pathway_virus_count(wave_number)
		- get_leading_viruses(wave_number).size()
	)
	var configured_total := 0
	for marker in SPAWN_MARKERS:
		configured_total += int(marker_counts[marker])

	while configured_total < target_count:
		var smallest_marker: StringName = SPAWN_MARKERS.front()
		for marker in SPAWN_MARKERS:
			if int(marker_counts[marker]) < int(marker_counts[smallest_marker]):
				smallest_marker = marker
		marker_counts[smallest_marker] = int(marker_counts[smallest_marker]) + 1
		configured_total += 1

	while configured_total > target_count:
		var largest_marker: StringName = SPAWN_MARKERS.front()
		for marker in SPAWN_MARKERS:
			if int(marker_counts[marker]) > int(marker_counts[largest_marker]):
				largest_marker = marker
		if int(marker_counts[largest_marker]) <= 0:
			break
		marker_counts[largest_marker] = int(marker_counts[largest_marker]) - 1
		configured_total -= 1

	return marker_counts


func _get_wave_database_entry(wave_number: int) -> Dictionary:
	return WAVE_DATABASE.get(wave_number, {}) as Dictionary
