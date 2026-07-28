extends SceneTree

const SignalBoostBalanceScript := preload(
	"res://Scripts/Towers/signal_boost_balance.gd"
)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_profile(1, 1.15)
	_check_profile(2, 1.30)
	_check_profile(10, 2.50)
	_finish()


func _check_profile(knowledge_level: int, expected_multiplier: float) -> void:
	var profile := SignalBoostBalanceScript.get_profile(
		knowledge_level,
		1
	) as Dictionary
	_check(
		is_equal_approx(float(profile["damage_multiplier"]), expected_multiplier),
		"Knowledge LV%d damage multiplier is %.2fx" % [
			knowledge_level,
			expected_multiplier
		]
	)
	_check(
		is_equal_approx(float(profile["range_multiplier"]), expected_multiplier),
		"Knowledge LV%d radius multiplier is %.2fx" % [
			knowledge_level,
			expected_multiplier
		]
	)
	_check(
		is_equal_approx(
			float(profile["cooldown_multiplier"]),
			1.0 / expected_multiplier
		),
		"Knowledge LV%d attack speed multiplier is %.2fx" % [
			knowledge_level,
			expected_multiplier
		]
	)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("Signal Boost stat validation passed.")
		quit(0)
	else:
		quit(1)
