extends SceneTree


func _initialize() -> void:
	var tower_scene := load("res://Scenes/Towers/XDR_Mech.tscn") as PackedScene
	if not _require(tower_scene != null, "XDR Mech scene could not be loaded."):
		return
	var tower := tower_scene.instantiate() as XDRMechTower
	if not _require(tower != null, "XDR Mech scene root has the wrong script type."):
		return
	root.add_child(tower)
	await process_frame

	var level_one_head := tower.get_node("Visuals/XDRHead") as Sprite2D
	var level_two_head := tower.get_node("Visuals/LV2Head") as Sprite2D
	var level_three_head := tower.get_node("Visuals/LV3Head") as Sprite2D
	var level_four_head := tower.get_node("Visuals/LV4Head") as Sprite2D
	var level_one_leg := tower.get_node("Visuals/XDRLeg") as AnimatedSprite2D
	var level_one_hit := tower.get_node(
		"Visuals/LV1HitAnimation"
	) as AnimatedSprite2D
	var level_two_hit := tower.get_node(
		"Visuals/LV2HitAnimation"
	) as AnimatedSprite2D
	var level_three_hit := tower.get_node(
		"Visuals/LV3HitAnimation"
	) as AnimatedSprite2D
	var level_four_hit := tower.get_node(
		"Visuals/LV4HitAnimation"
	) as AnimatedSprite2D
	var level_five_hit := tower.get_node(
		"Visuals/LV5HitAnimation"
	) as AnimatedSprite2D
	var level_two_cannon_origin := tower.get_node(
		"Level2CannonOrigin"
	) as Marker2D
	var level_three_left_cannon_origin := tower.get_node(
		"Level3LeftCannonOrigin"
	) as Marker2D
	var level_three_right_cannon_origin := tower.get_node(
		"Level3RightCannonOrigin"
	) as Marker2D
	var level_four_minigun_origin := tower.get_node(
		"Level4MinigunOrigin"
	) as Marker2D
	var level_four_cannon_origin := tower.get_node(
		"Level4CannonOrigin"
	) as Marker2D
	var level_four_minigun_projectile := tower.get_node(
		"Level4MinigunProjectile"
	) as Node2D
	var minigun_collision_shape := tower.get_node(
		"Level4MinigunProjectile/CollisionShape2D"
	) as CollisionShape2D
	var level_four_minigun_muzzle_vfx := tower.get_node(
		"Level4MinigunMuzzleVFX"
	) as Node2D
	var level_five_left_minigun_origin := tower.get_node(
		"Level5LeftMinigunOrigin"
	) as Marker2D
	var level_five_right_minigun_origin := tower.get_node(
		"Level5RightMinigunOrigin"
	) as Marker2D
	var level_five_left_minigun_muzzle_vfx := tower.get_node(
		"Level5LeftMinigunMuzzleVFX"
	) as Node2D
	var level_five_right_minigun_muzzle_vfx := tower.get_node(
		"Level5RightMinigunMuzzleVFX"
	) as Node2D
	var level_two_cannon_projectile := tower.get_node(
		"Level2CannonProjectile"
	) as Node2D
	var level_five_head := tower.get_node("Visuals/LV5Head") as Sprite2D
	var level_five_leg := tower.get_node("Visuals/LV5Leg") as AnimatedSprite2D
	var right_arm_hitbox := tower.get_node(
		"RightArmHitbox"
	) as CollisionShape2D
	var left_arm_hitbox := tower.get_node(
		"LeftArmHitbox"
	) as CollisionShape2D
	if not _require(
		level_one_leg != null
			and level_one_hit != null
			and level_one_hit.visible
			and level_one_hit.is_playing(),
		"Level 1 must use its perpetual hit track as the idle visual."
	):
		return
	if not _require(level_two_head != null and level_three_head != null and level_four_head != null, "Level 2-4 head nodes are missing from the XDR scene."):
		return
	if not _require(level_five_head != null and level_five_leg != null, "Level 5 XDR layers are missing."):
		return
	if not _require(
		right_arm_hitbox != null
			and right_arm_hitbox.shape is RectangleShape2D
			and left_arm_hitbox != null
			and left_arm_hitbox.shape is RectangleShape2D,
		"The editable XDR claw hitboxes are missing."
	):
		return
	for head in [level_one_head, level_two_head, level_three_head, level_four_head, level_five_head]:
		if not _require(head.texture != null, "%s does not have a directly assigned head texture." % head.name):
			return
	var level_five_head_texture := load("res://assets/Towers/XDR_Mech/XDR_Mech_LV5_Head_Idle.png") as Texture2D
	var level_five_leg_texture := load("res://assets/Towers/XDR_Mech/XDR_Mech_LV5_Leg_Idle.png") as Texture2D
	var level_five_head_image := level_five_head_texture.get_image()
	var level_five_leg_image := level_five_leg_texture.get_image()
	if not _require(level_five_head_image.get_pixel(0, 0).a <= 0.01, "The LV5 head green background is not transparent."):
		return
	if not _require(level_five_leg_image.get_pixel(0, 0).a <= 0.01, "The LV5 leg green background is not transparent."):
		return
	if not _require(level_five_head_image.get_pixel(120, 180).a >= 0.99, "The LV5 head gray chassis was made transparent."):
		return
	if not _require(level_five_leg_image.get_pixel(250, 180).a >= 0.99, "The LV5 leg gray chassis was made transparent."):
		return
	if not _require(level_five_head_image.get_pixel(108, 268).a >= 0.99, "The LV5 head blue lighting was made transparent."):
		return
	if not _require(level_five_leg_image.get_pixel(242, 100).a >= 0.99, "The LV5 leg blue lighting was made transparent."):
		return
	if not _require(
		level_one_leg.sprite_frames.get_frame_count(&"walk") > 0,
		"Level 1 walk does not contain frames."
	):
		return
	if not _require(
		level_five_leg.sprite_frames.get_frame_count(&"walk") > 0,
		"Level 5 walk does not contain frames."
	):
		return
	if not _require(
		level_one_leg.sprite_frames.get_animation_speed(&"walk") > 0.0,
		"Level 1 walk does not have a playback speed."
	):
		return
	if not _require(
		level_one_hit != null
			and is_equal_approx(level_one_hit.speed_scale, 2.0)
			and is_equal_approx(tower.level_1_hit_speed_scale, 2.0),
		"The LV1 claw animation and hit timing are not running at 2x speed."
	):
		return
	if not _require(
		level_two_hit != null
			and is_equal_approx(level_two_hit.speed_scale, 2.0)
			and level_two_cannon_origin != null
			and level_two_cannon_projectile != null,
		"The editable LV2 hybrid attack nodes are missing."
	):
		return
	if not _require(
		level_three_hit != null
			and is_equal_approx(level_three_hit.speed_scale, 2.0)
			and level_three_left_cannon_origin != null
			and level_three_right_cannon_origin != null,
		"The editable LV3 dual-cannon nodes are missing."
	):
		return
	if not _require(
		level_four_hit != null
			and is_equal_approx(level_four_hit.speed_scale, 7.0)
			and level_four_minigun_origin != null
			and level_four_cannon_origin != null
			and level_four_minigun_projectile != null
			and level_four_minigun_projectile is Area2D
			and minigun_collision_shape != null
			and minigun_collision_shape.shape is RectangleShape2D
			and (
				minigun_collision_shape.shape as RectangleShape2D
			).size.is_equal_approx(Vector2(96.0, 56.0))
			and level_four_minigun_muzzle_vfx != null
			and level_four_minigun_muzzle_vfx.get_child_count() == 4
			and tower.get_minigun_collision_size().x > 48.0
			and tower.get_minigun_collision_size().y > 28.0,
		"The editable LV4 minigun nodes are missing."
	):
		return
	for arc in level_four_minigun_muzzle_vfx.get_children():
		var line := arc as Line2D
		if not _require(
			line != null
				and line.default_color.b > line.default_color.r
				and line.points.size() >= 3
				and line.points[0].distance_to(
					line.points[line.points.size() - 1]
				) > 55.0,
			"The LV4 minigun muzzle arcs are not blue Line2D visuals."
		):
			return
	if not _require(
		level_five_hit != null
			and is_equal_approx(level_five_hit.speed_scale, 21.0)
			and level_five_left_minigun_origin != null
			and level_five_right_minigun_origin != null
			and level_five_left_minigun_muzzle_vfx != null
			and level_five_right_minigun_muzzle_vfx != null
			and level_five_left_minigun_muzzle_vfx.get_child_count() == 4
			and level_five_right_minigun_muzzle_vfx.get_child_count() == 4,
		"The editable LV5 dual-minigun nodes are missing."
	):
		return
	var expected_minigun_collision_size := \
		tower.get_minigun_collision_size()
	for muzzle_vfx in [
		level_five_left_minigun_muzzle_vfx,
		level_five_right_minigun_muzzle_vfx,
	]:
		for arc in muzzle_vfx.get_children():
			var line := arc as Line2D
			if not _require(
				line != null
					and line.default_color.b > line.default_color.r
					and line.points.size() >= 3
					and line.points[0].distance_to(
						line.points[line.points.size() - 1]
					) > 55.0,
				"The LV5 minigun muzzle arcs are not blue Line2D visuals."
			):
				return
	var cannon_arm_shape := right_arm_hitbox.shape as RectangleShape2D
	var expected_cannon_collision_size := Vector2(
		cannon_arm_shape.size.x
			* right_arm_hitbox.global_transform.x.length(),
		cannon_arm_shape.size.y
			* right_arm_hitbox.global_transform.y.length()
	)
	if not _require(
		level_two_cannon_origin.global_position.is_equal_approx(
			right_arm_hitbox.global_position
		)
			and tower.get_level_2_cannon_collision_size().is_equal_approx(
				expected_cannon_collision_size
			),
		"The LV2 cannon is not aligned with the opposite arm hitbox."
	):
		return
	if not _require(
		level_five_leg.sprite_frames.get_animation_speed(&"walk") > 0.0,
		"Level 5 walk does not have a playback speed."
	):
		return
	for attack_level in range(1, 6):
		var hit_animation := tower.get_hit_animation(attack_level)
		var animation_name := StringName("hit_lv%d" % attack_level)
		var minimum_frame_count := 1
		if attack_level == 1:
			minimum_frame_count = maxi(
				tower.left_arm_impact_frame,
				tower.right_arm_impact_frame
			) + 1
		elif attack_level == 2:
			minimum_frame_count = tower.level_2_claw_impact_frame + 1
		if not _require(
			hit_animation != null
				and hit_animation.sprite_frames != null
				and hit_animation.sprite_frames.has_animation(animation_name)
				and hit_animation.sprite_frames.get_frame_count(animation_name)
					>= minimum_frame_count
				and is_equal_approx(
					hit_animation.sprite_frames.get_animation_speed(
						animation_name
					),
					24.0
				)
				and hit_animation.sprite_frames.get_animation_loop(
					animation_name
				) == (attack_level <= 2),
			"XDR LV%d does not contain its required editable hit frames."
				% attack_level
		):
			return
	print("XDR asset and layer checks passed.")

	for idle_level in range(1, 3):
		tower.set_level(idle_level)
		var idle_hit_animation := tower.get_hit_animation(idle_level)
		if not _require(
			tower.is_claw_attack_active()
				and idle_hit_animation.visible
				and idle_hit_animation.is_playing()
				and level_one_leg.visible,
			"XDR LV%d did not use its perpetual passive animation."
				% idle_level
		):
			return
	tower.set_level(1)
	tower.global_position = Vector2(500.0, 300.0)

	var claw_target := PathFollow2D.new()
	root.add_child(claw_target)
	var claw_targets: Array[PathFollow2D] = [claw_target]
	var claw_hits: Array[Dictionary] = []
	var cannon_hits: Array[Dictionary] = []
	tower.claw_damage_requested.connect(
		func(target: PathFollow2D, damage: int) -> void:
			claw_hits.append({"target": target, "damage": damage})
	)
	tower.cannon_damage_requested.connect(
		func(target: PathFollow2D, damage: int) -> void:
			cannon_hits.append({"target": target, "damage": damage})
	)
	tower.set("_placed", true)
	claw_target.global_position = Vector2(5000.0, 5000.0)
	tower.update_claw_attack(0.0, claw_targets)
	if not _require(
		tower.is_claw_attack_active()
			and level_one_hit.visible
			and level_one_hit.is_playing()
			and not level_one_head.visible
			and not level_two_head.visible
			and not level_three_head.visible
			and not level_four_head.visible
			and not level_five_head.visible
			and level_one_leg.visible,
		"LV1 did not start its perpetual claw animation without a target."
	):
		return
	claw_target.global_position = Vector2(5000.0, 5000.0)
	level_one_hit.frame = tower.left_arm_impact_frame
	tower.update_claw_attack(0.0, claw_targets)
	if not _require(
		claw_hits.is_empty(),
		"The claw damaged a virus that left before the impact frame."
	):
		return

	level_one_hit.frame = 0
	tower.update_claw_attack(0.0, claw_targets)
	claw_target.global_position = left_arm_hitbox.global_position
	level_one_hit.frame = tower.left_arm_impact_frame
	tower.update_claw_attack(0.0, claw_targets)
	if not _require(
		claw_hits.size() == 1
			and claw_hits[0].get("target") == claw_target
			and int(claw_hits[0].get("damage", 0))
				== tower.level_1_claw_damage
			and tower.is_claw_attack_active()
			and level_one_hit.is_playing(),
		"The perpetual LV1 claw cycle did not damage at its next impact."
	):
		return
	tower.set_level(2)
	var cannon_facing_direction := tower.get_facing_direction()
	var cannon_perpendicular := Vector2(
		-cannon_facing_direction.y,
		cannon_facing_direction.x
	)
	claw_target.global_position = level_two_cannon_origin.global_position \
		+ cannon_perpendicular * 80.0
	tower.update_claw_attack(
		tower.level_2_cannon_cooldown_seconds,
		claw_targets
	)
	var first_passive_projectile := \
		tower.get_latest_level_2_cannon_projectile()
	if not _require(
		tower.is_claw_attack_active()
			and level_two_hit.visible
			and level_two_hit.is_playing()
			and level_one_leg.visible
			and not level_one_head.visible
			and not level_two_head.visible
			and not level_two_cannon_projectile.visible
			and is_instance_valid(first_passive_projectile)
			and first_passive_projectile.visible
			and is_equal_approx(
				first_passive_projectile.global_rotation,
				cannon_facing_direction.angle()
			),
		"LV2 did not combine its perpetual arm animation and passive cannon."
	):
		return
	var validated_cannon_travel_distance := \
		tower._get_level_2_cannon_travel_distance(
			level_two_cannon_origin.global_position,
			cannon_facing_direction
		)
	if not _require(
		validated_cannon_travel_distance
			> tower.level_2_cannon_max_distance,
		"LV2 passive cannon did not target the far viewport edge."
	):
		return
	claw_target.global_position = level_two_cannon_origin.global_position \
		+ cannon_facing_direction * 80.0
	first_passive_projectile.global_position = \
		claw_target.global_position
	tower.update_claw_attack(0.0, claw_targets)
	if not _require(
		cannon_hits.size() == 1
			and cannon_hits[0].get("target") == claw_target
			and int(cannon_hits[0].get("damage", 0))
				== tower.level_2_cannon_damage,
		"The LV2 cannon did not deal two damage to the virus it crossed."
	):
		return
	claw_target.global_position = Vector2(5000.0, 5000.0)
	tower.update_claw_attack(
		tower.level_2_cannon_cooldown_seconds,
		claw_targets
	)
	var second_passive_projectile := \
		tower.get_latest_level_2_cannon_projectile()
	if not _require(
		is_instance_valid(second_passive_projectile)
			and second_passive_projectile != first_passive_projectile
			and tower.is_claw_attack_active()
			and level_two_hit.is_playing(),
		"LV2 passive cannon did not fire again after one second."
	):
		return
	tower._cancel_level_2_cannon_projectile()
	claw_target.global_position = Vector2(5000.0, 5000.0)
	level_two_hit.frame = tower.level_2_claw_impact_frame
	tower.update_claw_attack(0.0, claw_targets)
	if not _require(
		claw_hits.size() == 1,
		"The LV2 arm damaged a virus outside its impact hitbox."
	):
		return
	level_two_hit.frame = 0
	tower.update_claw_attack(0.0, claw_targets)
	claw_target.global_position = left_arm_hitbox.global_position
	level_two_hit.frame = tower.level_2_claw_impact_frame
	tower.update_claw_attack(0.0, claw_targets)
	if not _require(
		claw_hits.size() == 2
			and int(claw_hits[1].get("damage", 0))
				== tower.level_2_claw_damage,
		"The perpetual LV2 arm did not damage at its next impact."
	):
		return
	tower._cancel_level_2_cannon_projectile()
	tower.set_level(3)
	claw_target.global_position = Vector2(5000.0, 5000.0)
	tower.update_claw_attack(
		tower.level_3_cannon_cooldown_seconds,
		claw_targets
	)
	var first_level_three_volley := tower.get_active_cannon_projectiles()
	if not _require(
		tower.is_claw_attack_active()
			and level_three_hit.visible
			and level_three_hit.is_playing()
			and not level_one_head.visible
			and not level_two_head.visible
			and not level_three_head.visible
			and not level_four_head.visible
			and not level_five_head.visible
			and level_one_leg.visible
			and first_level_three_volley.size() == 2,
		"LV3 did not play its shoot animation with a targetless dual volley."
	):
		return
	if not _require(
		first_level_three_volley[0].global_position.is_equal_approx(
			level_three_left_cannon_origin.global_position
		)
			and first_level_three_volley[1].global_position.is_equal_approx(
				level_three_right_cannon_origin.global_position
			)
			and is_equal_approx(
				first_level_three_volley[0].global_rotation,
				tower.get_facing_direction().angle()
			)
			and is_equal_approx(
				first_level_three_volley[1].global_rotation,
				tower.get_facing_direction().angle()
			),
		"LV3 cannon projectiles did not start from both authored arms."
	):
		return
	tower._on_hit_animation_finished(level_three_hit)
	if not _require(
		level_three_head.visible
			and level_one_leg.visible
			and not level_three_hit.visible,
		"LV3 did not restore its head and legs after shooting."
	):
		return
	tower.update_claw_attack(
		tower.level_3_cannon_cooldown_seconds,
		claw_targets
	)
	if not _require(
		tower.get_active_cannon_projectiles().size() == 4
			and tower.is_claw_attack_active(),
		"LV3 dual cannons did not repeat after one second."
	):
		return
	tower._cancel_claw_attack()
	tower._cancel_level_2_cannon_projectile()
	tower.set_level(4)
	var minigun_trail := level_four_minigun_projectile.get_node(
		"Trail"
	) as Line2D
	if not _require(
		minigun_trail != null
			and minigun_trail.points[0].distance_to(
				minigun_trail.points[minigun_trail.points.size() - 1]
			) > 75.0
			and level_four_cannon_origin.global_position.is_equal_approx(
				left_arm_hitbox.global_position
			),
		"LV4 line length or opposite-arm cannon origin is incorrect."
	):
		return
	var minigun_pattern_positions: Array[Vector2] = []
	for minigun_step in range(4):
		tower.update_claw_attack(
			tower.level_4_minigun_cooldown_seconds,
			claw_targets
		)
		var active_level_four_projectiles := \
			tower.get_active_cannon_projectiles()
		var active_minigun_lines: Array[Node2D] = []
		var active_other_arm_cannons: Array[Node2D] = []
		for projectile in active_level_four_projectiles:
			var projectile_kind := StringName(projectile.get_meta(
				"projectile_kind",
				&""
			))
			if projectile_kind == &"level4_minigun":
				active_minigun_lines.append(projectile)
			elif projectile_kind == &"level4_cannon":
				active_other_arm_cannons.append(projectile)
		var visible_muzzle_line_count := 0
		for muzzle_line in level_four_minigun_muzzle_vfx.get_children():
			if muzzle_line.visible:
				visible_muzzle_line_count += 1
		if not _require(
			tower.is_claw_attack_active()
				and level_four_hit.visible
				and level_four_hit.is_playing()
				and not level_one_head.visible
				and not level_two_head.visible
				and not level_three_head.visible
				and not level_four_head.visible
				and not level_five_head.visible
				and level_one_leg.visible
				and level_four_minigun_muzzle_vfx.visible
				and visible_muzzle_line_count == 1
				and level_four_minigun_muzzle_vfx.get_child(
					minigun_step
				).visible
				and active_minigun_lines.size() == 1,
			"LV4 did not show exactly one sequential minigun line."
		):
			return
		var minigun_line := active_minigun_lines[0]
		if not _require(
			String(minigun_line.name).begins_with(
				"Level4MinigunLine"
			)
				and is_equal_approx(
					minigun_line.global_rotation,
					tower.get_facing_direction().angle()
				)
				and int(minigun_line.get_meta("damage", 0)) == 2,
			"An LV4 minigun line has incorrect direction or damage."
		):
			return
		if not _require(
			minigun_line.scale.is_equal_approx(
				level_four_minigun_projectile.global_scale
			)
				and Vector2(minigun_line.get_meta(
					"collision_size",
					Vector2.ZERO
				)).is_equal_approx(expected_minigun_collision_size),
			"An LV4 minigun line did not retain its authored size or doubled hitbox."
		):
			return
		minigun_pattern_positions.append(minigun_line.global_position)
		if not _require(
			active_other_arm_cannons.is_empty(),
			"LV4 opposite-arm cannon fired before its one-second interval."
		):
			return
		tower._on_hit_animation_finished(level_four_hit)
	var minigun_layout_cross := absf(
		(
			minigun_pattern_positions[1]
				- minigun_pattern_positions[0]
		).cross(
			minigun_pattern_positions[2]
				- minigun_pattern_positions[0]
		)
	)
	if not _require(
		minigun_layout_cross > 0.1
			and minigun_pattern_positions[0] \
				!= minigun_pattern_positions[3],
		"LV4 did not retain its four staggered minigun positions."
	):
		return
	tower.update_claw_attack(0.4, claw_targets)
	var level_four_other_arm_cannons: Array[Node2D] = []
	for projectile in tower.get_active_cannon_projectiles():
		if StringName(projectile.get_meta(
			"projectile_kind",
			&""
		)) == &"level4_cannon":
			level_four_other_arm_cannons.append(projectile)
	if not _require(
		level_four_other_arm_cannons.size() == 1
			and level_four_other_arm_cannons[0].global_position \
				.is_equal_approx(
					level_four_cannon_origin.global_position
				)
			and int(level_four_other_arm_cannons[0].get_meta(
				"damage",
				0
			)) == tower.level_4_cannon_damage,
		"LV4 opposite-arm cannon did not fire after one second."
	):
		return
	tower._on_hit_animation_finished(level_four_hit)
	if not _require(
		level_four_head.visible
			and level_one_leg.visible
			and not level_four_hit.visible,
		"LV4 did not restore its head and legs after the minigun volley."
	):
		return
	tower._cancel_level_4_minigun_muzzle_vfx()
	tower._cancel_level_2_cannon_projectile()
	tower.set_level(5)
	claw_target.global_position = Vector2(5000.0, 5000.0)
	tower.update_claw_attack(
		tower.level_5_minigun_cooldown_seconds,
		claw_targets
	)
	var level_five_minigun_lines: Array[Node2D] = []
	for projectile in tower.get_active_cannon_projectiles():
		var projectile_kind := StringName(projectile.get_meta(
			"projectile_kind",
			&""
		))
		if projectile_kind in [
			&"level5_left_minigun",
			&"level5_right_minigun",
		]:
			level_five_minigun_lines.append(projectile)
	var left_visible_muzzle_lines := 0
	var right_visible_muzzle_lines := 0
	for muzzle_line in level_five_left_minigun_muzzle_vfx.get_children():
		if muzzle_line.visible:
			left_visible_muzzle_lines += 1
	for muzzle_line in level_five_right_minigun_muzzle_vfx.get_children():
		if muzzle_line.visible:
			right_visible_muzzle_lines += 1
	if not _require(
		tower.is_claw_attack_active()
			and level_five_hit.visible
			and level_five_hit.is_playing()
			and not level_five_head.visible
			and not level_one_leg.visible
			and level_five_leg.visible
			and level_five_minigun_lines.size() == 2
			and level_five_left_minigun_muzzle_vfx.visible
			and level_five_right_minigun_muzzle_vfx.visible
			and left_visible_muzzle_lines == 1
			and right_visible_muzzle_lines == 1,
		"LV5 did not play its shoot animation with two minigun lines."
	):
		return
	var left_level_five_line: Node2D
	var right_level_five_line: Node2D
	for minigun_line in level_five_minigun_lines:
		var projectile_kind := StringName(minigun_line.get_meta(
			"projectile_kind",
			&""
		))
		if projectile_kind == &"level5_left_minigun":
			left_level_five_line = minigun_line
		elif projectile_kind == &"level5_right_minigun":
			right_level_five_line = minigun_line
	if not _require(
		left_level_five_line != null
			and right_level_five_line != null
			and left_level_five_line.global_position.distance_to(
				level_five_left_minigun_origin.global_position
			) < 25.0
			and right_level_five_line.global_position.distance_to(
				level_five_right_minigun_origin.global_position
			) < 25.0
			and int(left_level_five_line.get_meta("damage", 0)) == 2
			and int(right_level_five_line.get_meta("damage", 0)) == 2
			and left_level_five_line.scale.is_equal_approx(
				level_four_minigun_projectile.global_scale
			)
			and right_level_five_line.scale.is_equal_approx(
				level_four_minigun_projectile.global_scale
			)
			and Vector2(left_level_five_line.get_meta(
				"collision_size",
				Vector2.ZERO
			)).is_equal_approx(expected_minigun_collision_size)
			and Vector2(right_level_five_line.get_meta(
				"collision_size",
				Vector2.ZERO
			)).is_equal_approx(expected_minigun_collision_size)
			and is_equal_approx(
				left_level_five_line.global_rotation,
				tower.get_facing_direction().angle()
			)
			and is_equal_approx(
				right_level_five_line.global_rotation,
				tower.get_facing_direction().angle()
			),
		"LV5 minigun lines did not start from both authored hands."
	):
		return
	var hits_before_minigun_impact := cannon_hits.size()
	claw_target.global_position = left_level_five_line.global_position
	tower.update_claw_attack(0.0, claw_targets)
	if not _require(
		cannon_hits.size() == hits_before_minigun_impact + 1
			and int(cannon_hits.back().get("damage", 0))
				== tower.level_5_minigun_damage
			and not tower.get_active_cannon_projectiles().has(
				left_level_five_line
			)
			and left_level_five_line.is_queued_for_deletion(),
		"An LV5 minigun line did not queue-free immediately on impact."
	):
		return
	tower._on_hit_animation_finished(level_five_hit)
	if not _require(
		level_five_head.visible
			and level_five_leg.visible
			and not level_five_hit.visible,
		"LV5 did not restore its head and legs after shooting."
	):
		return
	tower.update_claw_attack(
		tower.level_5_minigun_cooldown_seconds,
		claw_targets
	)
	var repeated_level_five_lines := 0
	for projectile in tower.get_active_cannon_projectiles():
		if StringName(projectile.get_meta(
			"projectile_kind",
			&""
		)) in [
			&"level5_left_minigun",
			&"level5_right_minigun",
		]:
			repeated_level_five_lines += 1
	if not _require(
		repeated_level_five_lines == 2
			and tower.is_claw_attack_active()
			and level_five_hit.visible,
		"LV5 dual miniguns did not repeat after 0.15 seconds."
	):
		return
	tower._cancel_level_5_minigun_muzzle_vfx()
	tower._cancel_claw_attack()
	tower._cancel_level_2_cannon_projectile()
	tower.set_level(1)
	claw_target.queue_free()
	await process_frame
	print("XDR LV1-LV5 attack behavior checks passed.")

	var head_rest_position := level_one_head.position
	tower.global_position = Vector2(300.0, 300.0)
	tower.set("_placed", true)
	tower.destination_turn_seconds = 0.0
	tower.set_dispatched(true)
	if not _require(tower.set_dispatch_destination(Vector2(500.0, 300.0)), "XDR Mech rejected a valid destination."):
		return
	tower._process(0.5)
	if not _require(tower.global_position.x > 300.0, "XDR Mech did not move toward its destination."):
		return
	if not _require(level_one_leg.animation == &"walk" and level_one_leg.is_playing(), "Level 1 legs did not enter the walk animation."):
		return
	if not _require(not level_one_head.position.is_equal_approx(head_rest_position), "The XDR head did not bob while walking."):
		return
	tower._process(2.0)
	if not _require(not tower.has_dispatch_destination(), "XDR Mech did not clear an arrived destination."):
		return
	if not _require(level_one_leg.animation == &"idle" and not level_one_leg.is_playing(), "XDR Mech did not restore its static idle frame."):
		return
	if not _require(level_one_head.position.is_equal_approx(head_rest_position), "The XDR head did not return to its authored position."):
		return

	tower.set_level(3)
	if not _require(level_three_head.visible and not level_one_head.visible, "Level 3 did not select its corresponding head node."):
		return
	tower.set_level(5)
	if not _require(not level_one_head.visible and not level_one_leg.visible, "Level 1 layers remained visible at level 5."):
		return
	if not _require(level_five_head.visible and level_five_leg.visible, "Level 5 layers were not activated together."):
		return
	print("XDR movement and level swap checks passed.")

	var gameplay_scene := load("res://Scenes/Gameplay/Cutscene_Test_Game.tscn") as PackedScene
	if not _require(gameplay_scene != null, "Cutscene Test Game could not be loaded after XDR integration."):
		return
	var gameplay := gameplay_scene.instantiate()
	if not _require(gameplay.get_node_or_null("Sprites/XDR_Mech") is XDRMechTower, "The gameplay XDR store prototype is missing."):
		return
	var card := gameplay.get_node_or_null("TestDrag/XDRMechCard") as TowerShopCard
	if not _require(card != null, "The authored XDR tower card is missing."):
		return
	var card_resource := card.get("card_resource") as TowerShopCardResource
	if not _require(card_resource != null and card_resource.tower_id == &"xdr_mech", "The XDR card resource is not assigned."):
		return
	gameplay.call("_connect_placed_xdr", tower)
	if not _require(
		tower.claw_damage_requested.is_connected(
			Callable(gameplay, "_on_xdr_claw_damage_requested")
		),
		"The game did not connect XDR claw hits to virus damage."
	):
		return
	if not _require(
		tower.cannon_damage_requested.is_connected(
			Callable(gameplay, "_on_xdr_cannon_damage_requested")
		),
		"The game did not connect XDR cannon hits to virus damage."
	):
		return

	gameplay.free()
	tower.free()
	print("XDR Mech validation passed: layered visuals, movement, level swap, store card, and prototype.")
	quit(0)


func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	quit(1)
	return false
