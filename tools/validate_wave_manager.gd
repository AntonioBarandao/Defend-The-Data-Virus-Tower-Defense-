extends SceneTree

const WaveManagerScript := preload("res://Scripts/Gameplay/wave_manager.gd")


func _initialize() -> void:
	var manager := WaveManagerScript.new()
	for wave_number in range(1, 26):
		if not _require(manager.has_wave(wave_number), "Wave %d is missing." % wave_number):
			return

		var definition := manager.get_wave_definition(wave_number)
		var viruses := definition.get("viruses", {}) as Dictionary
		var markers := definition.get("markers", {}) as Dictionary
		var progressive_boss := definition.get(
			"progressive_boss",
			{}
		) as Dictionary
		if not _require(
			not viruses.has("zombie_node")
				and not viruses.has("botnet_node"),
			"Wave %d still treats a progressive boss as a normal virus."
				% wave_number
		):
			return
		for virus_type in WaveManagerScript.VIRUS_TYPES:
			if not _require(
				viruses.has(String(virus_type)),
				"Wave %d is missing '%s'." % [wave_number, String(virus_type)]
			):
				return
			if not _require(
				manager.get_virus_amount(wave_number, virus_type) >= 0,
				"Wave %d has a negative '%s' amount." % [
					wave_number,
					String(virus_type),
				]
			):
				return
			var scene_path := manager.get_virus_scene_path(virus_type)
			if not _require(
				not scene_path.is_empty() and ResourceLoader.exists(scene_path),
				"Virus scene '%s' is not registered correctly." % String(virus_type)
			):
				return

		var expected_boss := _expected_progressive_boss(wave_number)
		var boss_name := manager.get_progressive_boss_name(wave_number)
		var boss_level := manager.get_progressive_boss_level(wave_number)
		if not _require(
			progressive_boss.has("name")
				and progressive_boss.has("level")
				and boss_name == expected_boss.name
				and boss_level == expected_boss.level,
			"Wave %d has the wrong progressive boss name or level."
				% wave_number
		):
			return
		if not boss_name.is_empty():
			var boss_scene_path := manager.get_progressive_boss_scene_path(
				boss_name
			)
			if not _require(
				ResourceLoader.exists(boss_scene_path),
				"Wave %d progressive boss scene is not registered."
					% wave_number
			):
				return

		var leaders := manager.get_leading_viruses(wave_number)
		if not _require(
			leaders.size() == WaveManagerScript.LEADING_VIRUS_KEYS.size(),
			"Wave %d must configure all three valid leading-virus names."
				% wave_number
		):
			return
		for leader_index in range(WaveManagerScript.LEADING_VIRUS_KEYS.size()):
			var leader_key: StringName = WaveManagerScript.LEADING_VIRUS_KEYS[
				leader_index
			]
			var configured_name := String(definition.get(String(leader_key), ""))
			if not _require(
				definition.has(String(leader_key))
					and not configured_name.is_empty()
					and StringName(configured_name) == leaders[leader_index],
				"Wave %d has an invalid '%s' value." % [
					wave_number,
					String(leader_key),
				]
			):
				return

		var marker_total := 0
		var configured_marker_total := 0
		for marker in WaveManagerScript.SPAWN_MARKERS:
			if not _require(
				markers.has(String(marker)),
				"Wave %d is missing its '%s' marker." % [
					wave_number,
					String(marker),
				]
			):
				return
			configured_marker_total += maxi(
				0,
				int(markers.get(String(marker), 0))
			)
			marker_total += manager.get_marker_virus_count(wave_number, marker)
		if not _require(
			configured_marker_total + leaders.size()
					== manager.get_total_pathway_virus_count(wave_number)
				and marker_total == configured_marker_total,
			"Wave %d leaders and marker concentrations do not cover every pathway virus."
				% wave_number
		):
			return

		var expected_duration := _expected_duration(wave_number)
		if not _require(
			is_equal_approx(
				manager.get_spawn_duration_seconds(wave_number),
				expected_duration
			),
			"Wave %d should have a %.0f-second spawn duration." % [
				wave_number,
				expected_duration,
			]
		):
			return

		var expected_red_count := 5 + ((wave_number - 1) * 2)
		if not _require(
			manager.get_virus_amount(wave_number, WaveManagerScript.RED_VIRUS)
				== expected_red_count,
			"Wave %d did not retain its red-virus progression." % wave_number
		):
			return

		var schedule := manager.build_spawn_schedule(wave_number)
		var queue := manager.build_spawn_queue(wave_number)
		if not _require(
			schedule.size() == manager.get_total_pathway_virus_count(wave_number)
				and queue.size() == schedule.size(),
			"Wave %d spawn schedule does not match its configured amounts."
				% wave_number
		):
			return
		for virus_type in WaveManagerScript.PATHWAY_VIRUS_TYPES:
			if not _require(
				queue.count(virus_type)
					== manager.get_virus_amount(wave_number, virus_type),
				"Wave %d queue has the wrong '%s' amount." % [
					wave_number,
					String(virus_type),
				]
			):
				return

		if not _validate_schedule_timing(
			manager,
			wave_number,
			schedule,
			expected_duration
		):
			return

	if not _require(
		manager.get_leading_virus_name(5, 1) == WaveManagerScript.TROJAN_HORSE
			and manager.get_leading_virus_name(7, 1)
				== WaveManagerScript.ARMORED_VIRUS
			and manager.get_leading_virus_name(13, 1)
				== WaveManagerScript.MUTANT_VIRUS,
		"The Trojan, armored, and mutant introductions are not leading their waves."
	):
		return

	var game_script := load("res://Scripts/Gameplay/game.gd") as Script
	if not _require(
		game_script != null and game_script.can_instantiate(),
		"game.gd no longer parses."
	):
		return

	print(
		"Wave manager validation passed: 25 complete waves, three named leaders, "
		+ "three phase markers, progressive boss levels, and even schedules are valid."
	)
	quit(0)


func _validate_schedule_timing(
	manager: RefCounted,
	wave_number: int,
	schedule: Array[Dictionary],
	duration: float
) -> bool:
	if schedule.is_empty():
		return _require(false, "Wave %d has no spawn schedule." % wave_number)

	var previous_time := -1.0
	var marker_times := {}
	for leader_key in WaveManagerScript.LEADING_VIRUS_KEYS:
		marker_times[leader_key] = []
	for marker in WaveManagerScript.SPAWN_MARKERS:
		marker_times[marker] = []

	for instruction in schedule:
		var spawn_time := float(instruction.get("spawn_time_seconds", -1.0))
		var marker := StringName(instruction.get("marker", &""))
		if not _require(
			spawn_time >= previous_time
				and spawn_time >= 0.0
				and spawn_time <= duration,
			"Wave %d spawn timestamps are not ordered within the duration."
				% wave_number
		):
			return false
		if not _require(
			WaveManagerScript.LEADING_VIRUS_KEYS.has(marker)
				or WaveManagerScript.SPAWN_MARKERS.has(marker),
			"Wave %d contains an invalid spawn marker." % wave_number
		):
			return false

		(marker_times[marker] as Array).append(spawn_time)
		previous_time = spawn_time

	var leaders: Array[StringName] = manager.call(
		"get_leading_viruses",
		wave_number
	)
	for leader_index in range(leaders.size()):
		var leader_key: StringName = WaveManagerScript.LEADING_VIRUS_KEYS[
			leader_index
		]
		var times := marker_times[leader_key] as Array
		if not _require(
			times.size() == 1
				and StringName(schedule[leader_index].get("marker", &""))
					== leader_key
				and StringName(schedule[leader_index].get("virus_type", &""))
					== leaders[leader_index],
			"Wave %d '%s' is not in its configured leading position." % [
				wave_number,
				String(leader_key),
			]
		):
			return false

	if schedule.size() > 1 and not _require(
		is_zero_approx(float(schedule.front().get("spawn_time_seconds", -1.0)))
			and is_equal_approx(
				float(schedule.back().get("spawn_time_seconds", -1.0)),
				duration
			),
		"Wave %d should spread from 0 through %.0f seconds." % [
			wave_number,
			duration,
		]
	):
		return false

	for marker in WaveManagerScript.SPAWN_MARKERS:
		var times := marker_times[marker] as Array
		if not _require(
			times.size() == manager.get_marker_virus_count(wave_number, marker),
			"Wave %d '%s' marker has the wrong concentration." % [
				wave_number,
				String(marker),
			]
		):
			return false
		if times.size() < 3:
			continue

		var expected_spacing := float(times[1]) - float(times[0])
		for time_index in range(2, times.size()):
			var spacing := float(times[time_index]) - float(times[time_index - 1])
			if not _require(
				is_equal_approx(spacing, expected_spacing),
				"Wave %d '%s' marker is not evenly distributed." % [
					wave_number,
					String(marker),
				]
			):
				return false

	return true


func _expected_duration(wave_number: int) -> float:
	if wave_number <= 4:
		return 15.0
	if wave_number <= 9:
		return 30.0
	if wave_number <= 14:
		return 60.0
	if wave_number <= 19:
		return 120.0
	return 180.0


func _expected_progressive_boss(wave_number: int) -> Dictionary:
	if wave_number <= 10:
		return {"name": &"", "level": 0}
	if wave_number <= 12:
		return {"name": WaveManagerScript.ZOMBIE_NODE, "level": 1}
	if wave_number <= 14:
		return {"name": WaveManagerScript.ZOMBIE_NODE, "level": 4}
	if wave_number == 15:
		return {"name": WaveManagerScript.ZOMBIE_NODE, "level": 5}
	if wave_number <= 19:
		return {"name": &"", "level": 0}
	if wave_number == 20:
		return {"name": WaveManagerScript.WORM_BOSS, "level": 1}
	if wave_number <= 22:
		return {"name": WaveManagerScript.BOTNET_NODE, "level": 1}
	if wave_number <= 24:
		return {"name": WaveManagerScript.BOTNET_NODE, "level": 2}
	return {"name": WaveManagerScript.BOTNET_NODE, "level": 3}


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
