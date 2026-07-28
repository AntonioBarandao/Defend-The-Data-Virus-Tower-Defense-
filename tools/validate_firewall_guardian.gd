extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	host.name = "FirewallGuardianValidation"
	root.add_child(host)
	current_scene = host

	var virus_elements := Node2D.new()
	virus_elements.name = "VirusElements"
	host.add_child(virus_elements)
	var virus_path := Path2D.new()
	virus_path.name = "Path2D"
	virus_path.curve = Curve2D.new()
	virus_path.curve.add_point(Vector2.ZERO)
	virus_path.curve.add_point(Vector2(600.0, 0.0))
	virus_elements.add_child(virus_path)

	var sprites := Node2D.new()
	sprites.name = "Sprites"
	host.add_child(sprites)

	var guardian_scene := load(
		"res://Scenes/Towers/CyberGuardian.tscn"
	) as PackedScene
	var hud_scene := load(
		"res://Scenes/UI/SignalBoostHUD.tscn"
	) as PackedScene
	var red_virus_scene := load(
		"res://Scenes/Enemies/RedVirus.tscn"
	) as PackedScene
	_check(guardian_scene != null, "Cyber Guardian scene loads")
	_check(hud_scene != null, "Guardian ability HUD scene loads")
	_check(red_virus_scene != null, "Red Virus scene loads")
	if guardian_scene == null or hud_scene == null or red_virus_scene == null:
		_finish()
		return

	var guardian := guardian_scene.instantiate() as CyberGuardianTower
	guardian.position = Vector2(300.0, 50.0)
	sprites.add_child(guardian)
	await process_frame
	guardian.set("_placed", true)
	_check(
		is_equal_approx(guardian.firewall_active_duration, 60.0),
		"Firewall active duration defaults to 60 seconds"
	)
	_check(
		guardian.set_guardian_mode(&"firewall"),
		"Firewall mode can be selected"
	)

	var idle_visual := guardian.get_node(
		"Visuals/FirewallIdle"
	) as AnimatedSprite2D
	var declare_visual := guardian.get_node(
		"Visuals/FirewallSummon"
	) as AnimatedSprite2D
	var active_visual := guardian.get_node(
		"Visuals/FirewallShoot"
	) as AnimatedSprite2D
	_check(
		idle_visual.sprite_frames.get_frame_count(&"idle") == 145,
		"Firewall idle has 145 source frames"
	)
	_check(
		declare_visual.sprite_frames.get_frame_count(&"SummonAnim") == 73,
		"Firewall declare has 73 source frames"
	)
	_check(
		active_visual.sprite_frames.get_frame_count(&"ShootAnim") == 145,
		"Firewall active has 145 source frames"
	)
	_check(idle_visual.visible, "Firewall mode starts on its idle visual")
	_check(
		guardian.get("_firewall_area") == null,
		"Selecting Firewall mode does not deploy the field automatically"
	)

	var field_template := guardian.get_node(
		"Effects/FirewallFieldSpriteTemplate"
	) as Sprite2D
	var burn_template := guardian.get_node(
		"Effects/FirewallBurnVFXTemplate"
	) as Node2D
	_check(
		field_template.texture != null,
		"Cyber Guardian scene exposes an editable firewall field sprite"
	)
	_check(
		burn_template.get_node_or_null("AnimatedSprite2D") != null,
		"Cyber Guardian scene exposes an editable burn VFX template"
	)

	var hud := hud_scene.instantiate() as SignalBoostHUD
	host.add_child(hud)
	hud.set_guardian(guardian)
	await process_frame
	var signal_slot := hud.get_ability_slot()
	var firewall_slot := hud.get_firewall_ability_slot()
	_check(
		firewall_slot.visible and not signal_slot.visible,
		"Firewall mode displays only the Firewall activation card"
	)
	_check(
		not firewall_slot is Container,
		"Firewall activation card remains manually transformable"
	)

	hud.firewall_activation_requested.connect(guardian.activate_firewall)
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	hud.call("_on_firewall_ability_slot_gui_input", click_event)
	_check(
		guardian.get_firewall_state_id() == &"declare",
		"Pressing the Firewall icon enters the declare state"
	)
	_check(
		declare_visual.visible,
		"Declare state displays the Firewall declare animation"
	)
	_check(
		guardian.get("_firewall_area") == null,
		"Firewall field stays absent during its declare animation"
	)

	guardian.call("_start_firewall_active")
	await process_frame
	_check(
		guardian.get_firewall_state_id() == &"active",
		"Declare state transitions to the active state"
	)
	_check(
		guardian.get_firewall_time_remaining() > 59.0
			and guardian.get_firewall_time_remaining() <= 60.0,
		"Active state starts a 60-second timer"
	)
	_check(
		active_visual.visible and active_visual.is_playing(),
		"Active state loops the Firewall active animation"
	)

	var firewall_area := guardian.get("_firewall_area") as Area2D
	var firewall_visual := guardian.get("_firewall_visual") as Sprite2D
	_check(
		firewall_area != null and firewall_area.visible,
		"Active Firewall deploys its field on the virus path"
	)
	_check(
		firewall_visual != null and firewall_visual.texture != null,
		"Firewall field uses the authored sprite instead of a generated line"
	)
	_check(
		_find_descendant_of_type(firewall_area, "Line2D") == null,
		"Firewall field no longer contains a generated Line2D"
	)

	var follow := PathFollow2D.new()
	follow.progress = 300.0
	virus_path.add_child(follow)
	var red_virus := red_virus_scene.instantiate() as RedVirus
	follow.add_child(red_virus)
	await process_frame

	var damage_events: Array[int] = []
	guardian.firewall_damage_requested.connect(
		func(_follow: PathFollow2D, damage: int) -> void:
			damage_events.append(damage)
	)
	var active_viruses: Array[PathFollow2D] = [follow]
	guardian.update_firewall(0.0, active_viruses)
	_check(
		damage_events == [1],
		"Crossing the active Firewall applies one point of impact damage"
	)
	var burn_state := (
		guardian.get("_firewall_burn_states") as Dictionary
	).get(follow.get_instance_id(), {}) as Dictionary
	var burn_vfx := burn_state.get("vfx") as Node2D
	_check(
		is_instance_valid(burn_vfx) and burn_vfx.get_parent() == red_virus,
		"Firewall burn VFX attaches to the afflicted virus"
	)

	guardian.update_firewall(1.0, active_viruses)
	_check(
		damage_events == [1, 1],
		"Firewall burn applies one point of damage after one second"
	)

	guardian.call("_update_firewall_cycle", 60.0)
	await process_frame
	_check(
		guardian.get_firewall_state_id() == &"ready",
		"Firewall returns to ready after its 60-second duration"
	)
	_check(
		not firewall_area.visible and idle_visual.visible,
		"Expiration hides the field and returns to Firewall idle"
	)
	var damage_count_after_expiration := damage_events.size()
	guardian.update_firewall(1.0, active_viruses)
	_check(
		damage_events.size() == damage_count_after_expiration + 1,
		"Existing burn continues independently after the Firewall field expires"
	)
	guardian.update_firewall(5.0, active_viruses)
	_check(
		not (
			guardian.get("_firewall_burn_states") as Dictionary
		).has(follow.get_instance_id()),
		"Firewall burn state ends after its configured duration"
	)

	host.queue_free()
	await process_frame
	_finish()


func _find_descendant_of_type(node: Node, type_name: StringName) -> Node:
	if node == null:
		return null
	for child in node.get_children():
		if child.is_class(type_name):
			return child
		var nested := _find_descendant_of_type(child, type_name)
		if nested != null:
			return nested
	return null


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("Firewall Guardian validation passed.")
		quit(0)
	else:
		quit(1)
