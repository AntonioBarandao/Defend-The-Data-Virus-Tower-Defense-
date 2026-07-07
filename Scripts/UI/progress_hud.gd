class_name ProgressHUD
extends CanvasLayer

const MAX_KNOWLEDGE_LEVEL := 10
const LEVEL_POINT_REQUIREMENTS := [0, 10, 50, 150, 250, 350, 450, 550, 650, 750]

@onready var _cyberbuck_amount_label: Label = $Root/CyberBuckCounter/CounterBox/Amount
@onready var _level_label: Label = $Root/Panel/Margin/Content/LevelLabel
@onready var _progress_bar: ProgressBar = $Root/Panel/Margin/Content/ProgressBar
@onready var _points_label: Label = $Root/Panel/Margin/Content/PointsLabel

var _knowledge_level := 1
var _current_level_points := 0
var _total_knowledge_points := 0
var _cyberbucks := 0


func _ready() -> void:
	_sync_display()
	_sync_cyberbucks_display()


func add_knowledge_points(amount: int) -> void:
	var points := maxi(0, amount)
	if points <= 0:
		return

	_total_knowledge_points += points
	if _knowledge_level >= MAX_KNOWLEDGE_LEVEL:
		_sync_display()
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

	_sync_display()


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


func _sync_display() -> void:
	if _level_label == null or _progress_bar == null or _points_label == null:
		return

	_level_label.text = "Knowledge LV %d / %d" % [_knowledge_level, MAX_KNOWLEDGE_LEVEL]
	if _knowledge_level >= MAX_KNOWLEDGE_LEVEL:
		_progress_bar.max_value = 1.0
		_progress_bar.value = 1.0
		_points_label.text = "Max Knowledge"
		return

	var requirement := _get_next_level_requirement()
	_progress_bar.max_value = maxf(1.0, float(requirement))
	_progress_bar.value = clampf(float(_current_level_points), 0.0, _progress_bar.max_value)
	_points_label.text = "%d / %d KP" % [_current_level_points, requirement]


func _sync_cyberbucks_display() -> void:
	if _cyberbuck_amount_label != null:
		_cyberbuck_amount_label.text = str(_cyberbucks)
