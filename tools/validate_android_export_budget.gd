extends SceneTree

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"
const REQUIRED_DYNAMIC_RESOURCES := [
	"res://Scenes/Gameplay/Normal_Game.tscn",
	"res://Scenes/Gameplay/Admin_Sandbox.tscn",
	"res://Scenes/UI/LoadingScreen.tscn",
	"res://Resources/TowerShopCards/CyberGuardianCard.tres",
	"res://Resources/TowerShopCards/IPSIntrusionCard.tres",
	"res://assets/Towers/CyberGuardian/CyberGuardianSpriteFrames.res",
]
const REQUIRED_EXCLUSIONS := [
	"res://addons/**",
	"res://tools/**",
	"res://build/**",
	"res://sqlite/**",
	"res://APK_Version/**",
	"res://assets/soundtrack/Cyber-Business-Soundtrack.wav",
	"res://assets/soundtrack/Virtual Business.wav",
]

var _failed := false


func _init() -> void:
	var preset_text := FileAccess.get_file_as_string(EXPORT_PRESETS_PATH)
	_check(
		"export_filter=\"resources\"" in preset_text,
		"Android must export the explicit runtime resource manifest."
	)
	for resource_path in REQUIRED_DYNAMIC_RESOURCES:
		_check(
			resource_path in preset_text,
			"Android runtime manifest is missing: %s" % resource_path
		)
	for exclusion in REQUIRED_EXCLUSIONS:
		_check(
			exclusion in preset_text,
			"Android export exclusion is missing: %s" % exclusion
		)

	if _failed:
		quit(1)
		return
	print("Android export budget validation passed.")
	quit(0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
