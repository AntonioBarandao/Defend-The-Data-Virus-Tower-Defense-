class_name BotnetNodeProgressBar
extends CanvasLayer

@export var root_path: NodePath = ^"Root"
@export var progress_bar_path: NodePath = \
	^"Root/BossPanel/Margin/Content/HealthBar"
@export var health_label_path: NodePath = \
	^"Root/BossPanel/Margin/Content/Header/HealthLabel"
@export_range(0.05, 2.0, 0.05) var health_tween_duration := 0.22
@export_range(0.05, 2.0, 0.05) var defeat_fade_duration := 0.45

var _root: Control
var _progress_bar: ProgressBar
var _health_label: Label
var _health_tween: Tween
var _visibility_tween: Tween


func _ready() -> void:
	_root = get_node_or_null(root_path) as Control
	_progress_bar = get_node_or_null(progress_bar_path) as ProgressBar
	_health_label = get_node_or_null(health_label_path) as Label
	set_bar_visible(false)


func set_health(current: int, maximum: int, animate: bool = true) -> void:
	if _progress_bar == null:
		return
	var safe_maximum := maxi(1, maximum)
	var safe_current := clampi(current, 0, safe_maximum)
	_progress_bar.max_value = float(safe_maximum)
	if _health_label != null:
		_health_label.text = "%d / %d" % [safe_current, safe_maximum]

	if _health_tween != null:
		_health_tween.kill()
		_health_tween = null
	if not animate:
		_progress_bar.value = float(safe_current)
		return

	_health_tween = create_tween()
	_health_tween.tween_property(
		_progress_bar,
		"value",
		float(safe_current),
		health_tween_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_bar_visible(value: bool) -> void:
	visible = value
	if _root == null:
		return
	_root.visible = value
	if value:
		if _visibility_tween != null:
			_visibility_tween.kill()
			_visibility_tween = null
		_root.modulate = Color.WHITE


func play_defeat_fade() -> void:
	if _root == null:
		set_bar_visible(false)
		return
	if _visibility_tween != null:
		_visibility_tween.kill()
	_visibility_tween = create_tween()
	_visibility_tween.tween_property(
		_root,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.0),
		defeat_fade_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_visibility_tween.tween_callback(
		Callable(self, "set_bar_visible").bind(false)
	)
