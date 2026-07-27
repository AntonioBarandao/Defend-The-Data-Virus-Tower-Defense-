class_name WormBossPartTarget
extends PathFollow2D

const PART_HEAD := &"head"
const PART_BODY := &"body"
const PART_TAIL := &"tail"

var _boss: Node
var _part_visual: Node2D
var _part_kind := PART_BODY
var _part_index := -1
var _targetable := false
var _nullifier_suppression_sources: Dictionary = {}


func configure(
	boss: Node,
	part_visual: Node2D,
	part_kind: StringName,
	part_index: int
) -> void:
	_boss = boss
	_part_visual = part_visual
	_part_kind = part_kind
	_part_index = part_index
	rotates = false
	loop = false
	set_meta("worm_boss_part", true)
	set_meta("worm_boss_body_part", _part_kind == PART_BODY)


func sync_to_visual() -> void:
	if is_instance_valid(_part_visual):
		global_position = _part_visual.global_position


func set_targetable(value: bool) -> void:
	_targetable = value


func invalidate() -> void:
	_targetable = false
	clear_nullifier_suppression()
	_boss = null
	_part_visual = null


func is_targetable() -> bool:
	return _targetable \
		and is_instance_valid(_boss) \
		and is_instance_valid(_part_visual) \
		and _part_visual.visible


func is_worm_boss_part() -> bool:
	return true


func is_body_part() -> bool:
	return _part_kind == PART_BODY


func get_part_kind() -> StringName:
	return _part_kind


func get_part_index() -> int:
	return _part_index


func set_nullifier_suppressed(source: Node, active: bool) -> void:
	if source == null:
		return

	var was_suppressed := is_nullifier_suppressed()
	_prune_nullifier_suppression_sources()
	var source_id := source.get_instance_id()
	if active:
		_nullifier_suppression_sources[source_id] = weakref(source)
	else:
		_nullifier_suppression_sources.erase(source_id)
	var is_suppressed := is_nullifier_suppressed()
	if was_suppressed != is_suppressed \
			and is_instance_valid(_boss) \
			and _boss.has_method("set_part_nullifier_suppressed"):
		_boss.call(
			"set_part_nullifier_suppressed",
			_part_index,
			is_suppressed
		)


func is_nullifier_suppressed() -> bool:
	_prune_nullifier_suppression_sources()
	return not _nullifier_suppression_sources.is_empty()


func clear_nullifier_suppression() -> void:
	if _nullifier_suppression_sources.is_empty():
		return
	_nullifier_suppression_sources.clear()
	if is_instance_valid(_boss) \
			and _boss.has_method("set_part_nullifier_suppressed"):
		_boss.call("set_part_nullifier_suppressed", _part_index, false)


func take_damage(amount: int) -> bool:
	if not is_targetable() or not is_instance_valid(_boss):
		return false
	if not _boss.has_method("take_part_damage"):
		return false
	return bool(_boss.call("take_part_damage", _part_index, amount))


func can_be_targeted_by(attacker: Node) -> bool:
	if not is_targetable() or not is_instance_valid(_boss):
		return false
	if not _boss.has_method("can_target_part"):
		return false
	return bool(_boss.call("can_target_part", _part_index, attacker))


func _exit_tree() -> void:
	clear_nullifier_suppression()


func _prune_nullifier_suppression_sources() -> void:
	for source_id in _nullifier_suppression_sources.keys():
		var source_ref := _nullifier_suppression_sources[source_id] as WeakRef
		if source_ref == null or not is_instance_valid(source_ref.get_ref()):
			_nullifier_suppression_sources.erase(source_id)
