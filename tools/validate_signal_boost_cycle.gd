extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node2D.new()
	host.name = "SignalBoostCycleValidation"
	root.add_child(host)
	current_scene = host

	var guardian_scene := load("res://Scenes/Towers/CyberGuardian.tscn") as PackedScene
	var hud_scene := load("res://Scenes/UI/SignalBoostHUD.tscn") as PackedScene
	_check(guardian_scene != null, "Cyber Guardian scene loads")
	_check(hud_scene != null, "Signal Boost HUD scene loads")
	if guardian_scene == null or hud_scene == null:
		_finish()
		return

	var guardian := guardian_scene.instantiate() as CyberGuardianTower
	host.add_child(guardian)
	await process_frame
	guardian.set("_placed", true)
	_check(is_equal_approx(guardian.signal_boost_active_duration, 50.0), "Signal Boost active duration defaults to 50 seconds")
	_check(is_equal_approx(guardian.signal_boost_cooldown_duration, 120.0), "Signal Boost cooldown defaults to 120 seconds")
	_check(guardian.set_guardian_mode(&"signal_boost"), "Signal Boost mode can be selected")

	var idle_visual := guardian.get_node("Visuals/SignalBoostIdle") as AnimatedSprite2D
	var declare_visual := guardian.get_node("Visuals/SignalBoostDeclare") as AnimatedSprite2D
	var active_visual := guardian.get_node("Visuals/SignalBoostActive") as AnimatedSprite2D
	_check(idle_visual.sprite_frames.get_frame_count(&"idle") == 145, "Signal Boost idle has 145 source frames")
	_check(declare_visual.sprite_frames.get_frame_count(&"SummonAnim") == 73, "Signal Boost declare has 73 source frames")
	_check(active_visual.sprite_frames.get_frame_count(&"ShootAnim") == 73, "Signal Boost active has 73 source frames")
	_check(idle_visual.visible, "Signal Boost mode starts on its idle visual")

	_check(guardian.activate_signal_boost(), "Signal Boost activates from the ready state")
	_check(guardian.get_signal_boost_state_id() == &"declare", "Activation enters the declare state")
	_check(declare_visual.visible, "Declare state displays the declare animation track")

	guardian.call("_start_signal_boost_active")
	_check(guardian.get_signal_boost_state_id() == &"active", "Declare transitions to the active state")
	_check(guardian.is_signal_boost_effect_active(), "Global Signal Boost effect is active during the active state")
	_check(active_visual.visible, "Active state displays the active animation track")

	var hud := hud_scene.instantiate() as SignalBoostHUD
	host.add_child(hud)
	hud.set_guardian(guardian)
	await process_frame
	for editable_path in [
		"Root/AbilitySlot",
		"Root/AbilitySlot/Margin",
		"Root/AbilitySlot/Margin/Content",
		"Root/AbilitySlot/Margin/Content/IconFrame"
	]:
		var editable_control := hud.get_node(editable_path) as Control
		_check(editable_control != null and not editable_control is Container, "%s is manually transformable" % editable_path)
	var ability_slot := hud.get_ability_slot() as Panel
	_check(ability_slot.visible, "Signal Boost HUD is visible for the placed Signal Boost Guardian")
	var signal_boost_icon := hud.get_node("Root/AbilitySlot/Margin/Content/IconFrame/SignalBoostIcon") as TextureRect
	var status_label := hud.get_node("Root/AbilitySlot/Margin/Content/StatusLabel") as Label
	_check(signal_boost_icon.self_modulate != Color.WHITE, "Signal Boost icon is dimmed while active")
	_check(status_label.text == "SIGNAL BOOST  50s", "Signal Boost HUD starts the green active timer at 50 seconds")

	var base_border_color := (ability_slot.get_theme_stylebox("panel") as StyleBoxFlat).border_color
	hud.call("_on_ability_slot_mouse_entered")
	var hover_border_color := (ability_slot.get_theme_stylebox("panel") as StyleBoxFlat).border_color
	_check(hover_border_color != base_border_color, "Signal Boost card border glows on hover")
	hud.call("_on_ability_slot_mouse_exited")
	_check(
		(ability_slot.get_theme_stylebox("panel") as StyleBoxFlat).border_color == base_border_color,
		"Signal Boost card border returns to its authored color after hover"
	)

	guardian.call("_start_signal_boost_cooldown")
	await process_frame
	_check(guardian.get_signal_boost_state_id() == &"cooldown", "Active state transitions to cooldown")
	_check(not guardian.is_signal_boost_effect_active(), "Global Signal Boost effect stops during cooldown")
	_check(idle_visual.visible, "Cooldown returns the Guardian to its idle animation")
	_check(signal_boost_icon.self_modulate != Color.WHITE, "Signal Boost icon remains dimmed during cooldown")
	_check(status_label.text == "COOLDOWN  120s", "Signal Boost HUD starts the red cooldown timer at 120 seconds")

	guardian.call("_set_signal_boost_cycle_state", &"ready", 0.0)
	guardian.play_idle()
	await process_frame
	_check(signal_boost_icon.self_modulate == Color.WHITE, "Signal Boost icon re-enables when cooldown finishes")
	_check(status_label.text == "SIGNAL BOOST", "Ready state no longer requires a separate Activate label")

	hud.activation_requested.connect(guardian.activate_signal_boost)
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	hud.call("_on_ability_slot_gui_input", click_event)
	_check(guardian.get_signal_boost_state_id() == &"declare", "Pressing the Signal Boost card activates the ability")

	host.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("Signal Boost cycle validation passed.")
		quit(0)
	else:
		quit(1)
