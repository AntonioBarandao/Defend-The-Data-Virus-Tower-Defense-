extends SceneTree

const FIREWALL_OUTPUT := (
	"res://assets/Towers/CyberGuardian/Modes/Firewall/"
	+ "CyberGuardianFirewallSpriteFrames.tres"
)
const BURN_OUTPUT := (
	"res://assets/Effects/FirewallBurn/FirewallBurnSpriteFrames.tres"
)

const FIREWALL_FRAME_SIZE := Vector2(720, 720)
const BURN_FRAME_SIZE := Vector2(320, 320)
const ANIMATION_SPEED := 24.0

const FIREWALL_ANIMATIONS := [
	{
		"name": &"idle",
		"loop": true,
		"pages": [
			{
				"path": (
					"res://assets/Towers/CyberGuardian/Modes/Firewall/Idle/"
					+ "Cyberguardian_Firewall_Idle_atlas_24fps_page1.png"
				),
				"frames": 100,
				"columns": 10
			},
			{
				"path": (
					"res://assets/Towers/CyberGuardian/Modes/Firewall/Idle/"
					+ "Cyberguardian_Firewall_Idle_atlas_24fps_page2.png"
				),
				"frames": 45,
				"columns": 10
			}
		]
	},
	{
		"name": &"SummonAnim",
		"loop": false,
		"pages": [
			{
				"path": (
					"res://assets/Towers/CyberGuardian/Modes/Firewall/Declare/"
					+ "Cyberguardian_Firewall_Declare_atlas_24fps.png"
				),
				"frames": 73,
				"columns": 10
			}
		]
	},
	{
		"name": &"ShootAnim",
		"loop": true,
		"pages": [
			{
				"path": (
					"res://assets/Towers/CyberGuardian/Modes/Firewall/Active/"
					+ "Cyberguardian_Firewall_Active_atlas_24fps_page1.png"
				),
				"frames": 100,
				"columns": 10
			},
			{
				"path": (
					"res://assets/Towers/CyberGuardian/Modes/Firewall/Active/"
					+ "Cyberguardian_Firewall_Active_atlas_24fps_page2.png"
				),
				"frames": 45,
				"columns": 10
			}
		]
	}
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var firewall_frames := SpriteFrames.new()
	if firewall_frames.has_animation(&"default"):
		firewall_frames.remove_animation(&"default")
	for definition in FIREWALL_ANIMATIONS:
		if not _add_animation(
			firewall_frames,
			definition,
			FIREWALL_FRAME_SIZE
		):
			quit(1)
			return
	if ResourceSaver.save(firewall_frames, FIREWALL_OUTPUT) != OK:
		push_error("Failed to save Firewall Guardian SpriteFrames.")
		quit(1)
		return

	var burn_frames := SpriteFrames.new()
	burn_frames.set_animation_loop(&"default", true)
	burn_frames.set_animation_speed(&"default", ANIMATION_SPEED)
	if not _add_page_frames(
		burn_frames,
		&"default",
		{
			"path": (
				"res://assets/Effects/FirewallBurn/"
				+ "Fire_VFX_2_atlas_24fps.png"
			),
			"frames": 73,
			"columns": 10
		},
		BURN_FRAME_SIZE
	):
		quit(1)
		return
	if ResourceSaver.save(burn_frames, BURN_OUTPUT) != OK:
		push_error("Failed to save Firewall burn SpriteFrames.")
		quit(1)
		return

	print("Generated Firewall Guardian and burn SpriteFrames resources.")
	quit(0)


func _add_animation(
	frames: SpriteFrames,
	definition: Dictionary,
	frame_size: Vector2
) -> bool:
	var animation_name := definition["name"] as StringName
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, bool(definition["loop"]))
	frames.set_animation_speed(animation_name, ANIMATION_SPEED)
	for page_value in definition["pages"] as Array:
		if not _add_page_frames(
			frames,
			animation_name,
			page_value as Dictionary,
			frame_size
		):
			return false
	return true


func _add_page_frames(
	frames: SpriteFrames,
	animation_name: StringName,
	page: Dictionary,
	frame_size: Vector2
) -> bool:
	var texture := load(String(page["path"])) as Texture2D
	if texture == null:
		push_error("Unable to load Firewall atlas page: %s" % page["path"])
		return false

	var frame_count := int(page["frames"])
	var columns := int(page["columns"])
	for frame_index in range(frame_count):
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(
			Vector2(frame_index % columns, frame_index / columns) * frame_size,
			frame_size
		)
		frames.add_frame(animation_name, atlas_texture)
	return true
