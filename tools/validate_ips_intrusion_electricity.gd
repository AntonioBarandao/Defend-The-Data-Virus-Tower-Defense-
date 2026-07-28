extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	host.name = "IPSElectricityValidation"
	root.add_child(host)
	current_scene = host

	var virus_elements := Node2D.new()
	virus_elements.name = "VirusElements"
	host.add_child(virus_elements)
	var virus_path := Path2D.new()
	virus_path.name = "Path2D"
	virus_path.curve = Curve2D.new()
	virus_path.curve.add_point(Vector2(0.0, 100.0))
	virus_path.curve.add_point(Vector2(600.0, 100.0))
	virus_elements.add_child(virus_path)

	var tower_scene := load(
		"res://Scenes/Towers/IPS_Intrusion.tscn"
	) as PackedScene
	var spike_scene := load(
		"res://Scenes/Towers/IPS_Intrusion_Spike.tscn"
	) as PackedScene
	_check(tower_scene != null, "IPS Intrusion scene loads")
	_check(spike_scene != null, "IPS spike scene loads")
	if tower_scene == null or spike_scene == null:
		_finish()
		return

	var tower := tower_scene.instantiate() as IPSIntrusionTower
	host.add_child(tower)
	tower.global_position = Vector2(220.0, 220.0)
	tower.set("_home_position", tower.global_position)
	tower.set("_placed", true)
	await process_frame

	var factory_visual_paths := [
		"FactoryVisual",
		"LV2FactoryVisual",
		"LV3FactoryVisual",
		"LV4FactoryVisual",
		"LV5FactoryVisual",
	]
	var factory_frame_resource_ids := {}
	for tower_level in range(1, 6):
		tower.level = tower_level
		tower.call("_sync_factory_level_animation")
		var factory_visual := tower.get_node(
			factory_visual_paths[tower_level - 1]
		) as AnimatedSprite2D
		var expected_animation := StringName(
			"IPS_Intrusion_Factory_LV%d" % tower_level
		)
		var visible_factory_count := 0
		for visual_path in factory_visual_paths:
			var level_visual := tower.get_node(
				visual_path
			) as AnimatedSprite2D
			if level_visual.visible:
				visible_factory_count += 1
		_check(
			tower.get_active_factory_visual() == factory_visual
				and factory_visual.visible
				and visible_factory_count == 1
				and factory_visual.animation == expected_animation
				and factory_visual.is_playing(),
			"IPS LV%d uses its independent factory AnimatedSprite2D"
				% tower_level
		)
		_check(
			factory_visual.sprite_frames.get_frame_count(
				expected_animation
			) == 73,
			"IPS LV%d factory animation contains 73 optimized frames" % tower_level
		)
		factory_frame_resource_ids[
			factory_visual.sprite_frames.get_instance_id()
		] = true
		_check(
			tower.get_spike_durability() == tower_level,
			"IPS LV%d creates spikes with %d durability"
			% [tower_level, tower_level]
		)
	_check(
		factory_frame_resource_ids.size() == 5,
		"All five IPS factory levels expose independent editable SpriteFrames."
	)
	tower.level = 4
	tower.play_summon()
	var summoned_level_four := tower.get_node(
		"LV4FactoryVisual"
	) as AnimatedSprite2D
	var hidden_level_one := tower.get_node(
		"FactoryVisual"
	) as AnimatedSprite2D
	_check(
		tower.get_active_factory_visual()
			== summoned_level_four
			and summoned_level_four.visible
			and not hidden_level_one.visible,
		"Summoning preserves the selected factory level sibling."
	)

	tower.level = 1
	tower.max_spikes = 3
	tower.call("_sync_factory_level_animation")
	var no_viruses: Array[PathFollow2D] = []
	for spike_index in range(3):
		tower.update_spike_factory(tower.get_shot_cooldown(), no_viruses)
		await process_frame
		var spawned_spikes := _get_spikes()
		_check(
			spawned_spikes.size() == spike_index + 1,
			"Factory spawned spike %d without overlap" % (spike_index + 1)
		)
		for spawned_spike in spawned_spikes:
			if not spawned_spike.is_landed():
				spawned_spike.call("_finish_deploy")
		tower.update_spike_factory(0.0, no_viruses)

	var spikes := _get_spikes()
	var links := _get_links()
	_check(spikes.size() == 3, "Three adjacent spikes remain deployed")
	_check(
		links.size() == 2,
		"Three adjacent spikes create two electricity connections"
	)
	for spike in spikes:
		spike.hurt_radius = 1.0
	for link in links:
		var visual := link.get_node_or_null(
			^"AnimatedSprite2D"
		) as AnimatedSprite2D
		var hitbox := link.get_node_or_null(^"Hitbox") as CollisionShape2D
		_check(
			visual != null
				and visual.sprite_frames.get_frame_count(
					&"Animated_Electricity"
				) == 37
				and visual.is_playing(),
			"Electricity connection plays its optimized 37-frame loop"
		)
		_check(
			hitbox != null
				and hitbox.shape is RectangleShape2D
				and (hitbox.shape as RectangleShape2D).size.x > 0.0,
			"Electricity connection exposes an authored hitbox"
		)

	var test_link := links[0]
	var follow := PathFollow2D.new()
	virus_path.add_child(follow)
	follow.progress = virus_path.curve.get_closest_offset(
		virus_path.to_local(test_link.global_position)
	)
	var damage_events: Array[int] = []
	tower.spike_damage_requested.connect(
		func(_follow: PathFollow2D, damage: int) -> void:
			damage_events.append(damage)
	)
	var active_viruses: Array[PathFollow2D] = [follow]
	tower.update_spike_factory(0.49, active_viruses)
	_check(
		damage_events.is_empty(),
		"Electricity does not damage before its 0.5-second interval"
	)
	tower.update_spike_factory(0.01, active_viruses)
	_check(
		damage_events == [1],
		"Electricity deals one damage at the 0.5-second interval"
	)
	follow.progress = 550.0
	tower.update_spike_factory(1.0, active_viruses)
	_check(
		damage_events == [1],
		"Electricity stops damaging immediately after a virus exits"
	)
	follow.progress = virus_path.curve.get_closest_offset(
		virus_path.to_local(test_link.global_position)
	)
	tower.update_spike_factory(0.5, active_viruses)
	_check(
		damage_events == [1, 1],
		"Re-entering electricity starts a fresh damage interval"
	)

	var durability_spike := spike_scene.instantiate() as IPSIntrusionSpike
	durability_spike.configure_for_level(2)
	host.add_child(durability_spike)
	durability_spike.start_deploy(
		Vector2(100.0, 100.0),
		Vector2(100.0, 100.0),
		0.0,
		0.01
	)
	durability_spike.call("_finish_deploy")
	var first_contact := PathFollow2D.new()
	var second_contact := PathFollow2D.new()
	virus_path.add_child(first_contact)
	virus_path.add_child(second_contact)
	first_contact.progress = 100.0
	second_contact.progress = 100.0
	_check(
		durability_spike.mark_follow_hit(first_contact)
			and durability_spike.get_remaining_hits() == 1
			and durability_spike.is_landed(),
		"LV2 spike survives its first virus contact"
	)
	_check(
		durability_spike.mark_follow_hit(second_contact)
			and durability_spike.get_remaining_hits() == 0
			and not durability_spike.is_landed(),
		"LV2 spike despawns after its second virus contact"
	)

	var level_five_spike := spike_scene.instantiate() as IPSIntrusionSpike
	level_five_spike.configure_for_level(5)
	host.add_child(level_five_spike)
	await process_frame
	var level_five_visual := level_five_spike.get_node(
		"AnimatedSprite2D"
	) as AnimatedSprite2D
	_check(
		level_five_spike.max_hits == 5
			and level_five_visual.animation == &"Animated_Spikes_LV5"
			and level_five_visual.sprite_frames.get_frame_count(
				&"Animated_Spikes_LV5"
			) == 37,
		"LV5 spike uses five durability and its dedicated animation"
	)

	host.queue_free()
	await process_frame
	_finish()


func _get_spikes() -> Array[IPSIntrusionSpike]:
	var spikes: Array[IPSIntrusionSpike] = []
	for node in get_nodes_in_group("IPS_SPIKE"):
		var spike := node as IPSIntrusionSpike
		if spike != null and is_instance_valid(spike):
			spikes.append(spike)
	spikes.sort_custom(
		func(first: IPSIntrusionSpike, second: IPSIntrusionSpike) -> bool:
			return first.path_offset < second.path_offset
	)
	return spikes


func _get_links() -> Array[IPSElectricityLink]:
	var links: Array[IPSElectricityLink] = []
	for node in get_nodes_in_group("IPS_ELECTRICITY_LINK"):
		var link := node as IPSElectricityLink
		if link != null and is_instance_valid(link):
			links.append(link)
	return links


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("IPS Intrusion electricity validation passed.")
		quit(0)
	else:
		quit(1)
