class_name ProgressHUD
extends CanvasLayer

const MAX_KNOWLEDGE_LEVEL := 10
const LEVEL_POINT_REQUIREMENTS := [0, 5, 7, 10, 250, 350, 450, 550, 650, 750]

@onready var _cyberbuck_amount_label: Label = $Root/CyberBuckCounter/CounterBox/Amount
@onready var _level_label: Label = $Root/Panel/Margin/Content/LevelLabel
@onready var _progress_bar: ProgressBar = $Root/Panel/Margin/Content/ProgressBar
@onready var _points_label: Label = $Root/Panel/Margin/Content/PointsLabel

var _knowledge_level := 1
var _current_level_points := 0
var _total_knowledge_points := 0
var _cyberbucks := 0
var _progress_value_tween: Tween


func _ready() -> void:
	_sync_display()
	_sync_cyberbucks_display()


func add_knowledge_points(amount: int, animate_progress := false) -> void:
	var points := maxi(0, amount)
	if points <= 0:
		return

	_total_knowledge_points += points
	if _knowledge_level >= MAX_KNOWLEDGE_LEVEL:
		_sync_display(animate_progress)
		return

	_current_level_points += points
	while _knowledge_level < MAX_KNOWLEDGE_LEVEL:
		var requirement := _get_next_level_requirement()
		if requirement <= 0 or _current_level_points < requirement:
			break

		_current_level_points -= requirement
		_knowledge_level += 1

	if _knowledge_level >= MAX_KNOWLEDGE_LEVEL:
		_current_level_points = 0

	_sync_display(animate_progress)


func steal_knowledge_points(amount: int) -> int:
	var requested_points := maxi(0, amount)
	if requested_points <= 0 or _current_level_points <= 0:
		return 0

	var stolen_points := mini(requested_points, _current_level_points)
	_current_level_points -= stolen_points
	_total_knowledge_points = maxi(0, _total_knowledge_points - stolen_points)
	_sync_display(true)
	return stolen_points


func restore_knowledge_points(amount: int) -> void:
	add_knowledge_points(maxi(0, amount), true)


func get_current_level_points() -> int:
	return _current_level_points


func reset_knowledge() -> void:
	_knowledge_level = 1
	_current_level_points = 0
	_total_knowledge_points = 0
	_sync_display()


func get_knowledge_level() -> int:
	return _knowledge_level


func get_total_knowledge_points() -> int:
	return _total_knowledge_points


func set_cyberbucks(amount: int) -> void:
	_cyberbucks = maxi(0, amount)
	_sync_cyberbucks_display()


func _get_next_level_requirement() -> int:
	if _knowledge_level >= MAX_KNOWLEDGE_LEVEL:
		return 0

	return int(LEVEL_POINT_REQUIREMENTS[_knowledge_level])


func _sync_display(animate_progress := false) -> void:
	if _level_label == null or _progress_bar == null or _points_label == null:
		return

	_level_label.text = "Knowledge LV %d / %d" % [_knowledge_level, MAX_KNOWLEDGE_LEVEL]
	if _knowledge_level >= MAX_KNOWLEDGE_LEVEL:
		_progress_bar.max_value = 1.0
		_set_progress_value(1.0, animate_progress)
		_points_label.text = "Max Knowledge"
		return

	var requirement := _get_next_level_requirement()
	_progress_bar.max_value = maxf(1.0, float(requirement))
	_set_progress_value(clampf(float(_current_level_points), 0.0, _progress_bar.max_value), animate_progress)
	_points_label.text = "%d / %d KP" % [_current_level_points, requirement]


func _set_progress_value(target_value: float, animate: bool) -> void:
	if _progress_value_tween != null:
		_progress_value_tween.kill()
		_progress_value_tween = null
	if not animate or not is_inside_tree():
		_progress_bar.value = target_value
		return

	_progress_value_tween = create_tween()
	_progress_value_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_progress_value_tween.tween_property(_progress_bar, "value", target_value, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_progress_value_tween.tween_callback(func() -> void:
		_progress_value_tween = null
	)


func _sync_cyberbucks_display() -> void:
	if _cyberbuck_amount_label != null:
		_cyberbuck_amount_label.text = str(_cyberbucks)
