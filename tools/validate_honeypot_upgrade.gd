extends SceneTree

const HONEYPOT_SCENE := preload("res://Scenes/Towers/Honeypot_Production.tscn")
const HUD_SCENE := preload("res://Scenes/UI/TowerUpgradeHud.tscn")
const FRAMES_PATH := "res://assets/Towers/Honeypot_Production/HoneypotProductionSpriteFrames.tres"
const EXPECTED_TICK_SECONDS := [0.1, 0.05, 0.025, 0.01, 0.005]


func _init() -> void:
	call_deferred("_validate")


func _validate() -> void:
	var sprite_frames := load(FRAMES_PATH) as SpriteFrames
	assert(sprite_frames != null, "Honeypot SpriteFrames did not load.")
	for level in range(1, 6):
		var animation_name := StringName("idle_lv%d" % level)
		assert(sprite_frames.has_animation(animation_name), "%s is missing." % animation_name)
		assert(sprite_frames.get_frame_count(animation_name) == 145, "%s must contain 145 frames." % animation_name)
		assert(is_equal_approx(sprite_frames.get_animation_speed(animation_name), 24.0), "%s must play at 24 FPS." % animation_name)

	var tower := HONEYPOT_SCENE.instantiate() as HoneypotProductionTower
	root.add_child(tower)
	await process_frame
	assert(is_equal_approx(tower.get_production_tick_seconds(), 0.1), "LV1 production tick must preserve the original 10 Cyber Bucks per second rate.")
	assert(is_equal_approx(tower.get_production_rate(), 10.0), "LV1 production rate must be 10 Cyber Bucks per second.")
	tower.call("_try_start_production_cycle", 1)
	var no_viruses: Array[PathFollow2D] = []
	tower.call("_update_production_cycle", no_viruses, 0.1)
	assert(tower.get_production_pot() == 1, "A production tick must add exactly one Cyber Buck.")
	tower.reset_tower()
	for level in range(1, 6):
		assert(is_equal_approx(tower.get_production_tick_seconds(), EXPECTED_TICK_SECONDS[level - 1]), "LV%d production tick is incorrect." % level)
		var visual := tower.get_node("LevelVisuals/LV%dVisual" % level) as AnimatedSprite2D
		assert(visual != null, "LV%d visual is missing." % level)
		assert(visual.visible == (tower.get_level() == level), "Incorrect visual active at LV%d." % tower.get_level())
		if level < 5:
			assert(tower.upgrade(), "Upgrade to LV%d failed." % (level + 1))
	assert(is_equal_approx(tower.get_production_rate(), 200.0), "LV5 production rate must be 200 Cyber Bucks per second.")

	var hud := HUD_SCENE.instantiate() as TowerUpgradeHUD
	root.add_child(hud)
	await process_frame
	for level in range(1, 6):
		hud.set_honeypot_stats(level, 5, 0, 100, 10.0, 250.0, "Waiting", 0, 10, level >= 3, level < 5, 0)
		var display := hud.get_node("Root/MenuPanel/Margin/Content/VBoxContainer2/HoneypotLevelDisplay/DisplayMargin/LevelImage") as TextureRect
		assert(display.texture != null, "HUD display texture is missing at LV%d." % level)
		assert(display.texture.resource_path.ends_with("LV%d.png" % level), "HUD display did not advance to LV%d." % level)

	print("Honeypot upgrade validation passed: 5 x 145 frames, tower visuals, and HUD portraits.")
	quit()
