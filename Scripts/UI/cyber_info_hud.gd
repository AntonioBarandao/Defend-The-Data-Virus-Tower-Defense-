class_name CyberInfoHUD
extends CanvasLayer

enum Page {
	TOWERS,
	VIRUSES,
}

@export var catalog: CyberInfoCatalog
@export_range(0.1, 1.0, 0.01) var open_duration := 0.3
@export_range(0.1, 1.0, 0.01) var close_duration := 0.22

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = $Root/Panel
@onready var _title_label: Label = $Root/Panel/Margin/Layout/Header/TitleLabel
@onready var _close_button: Button = $Root/Panel/Margin/Layout/Header/CloseButton
@onready var _tower_tab: Button = $Root/Panel/Margin/Layout/Tabs/TowerTab
@onready var _virus_tab: Button = $Root/Panel/Margin/Layout/Tabs/VirusTab
@onready var _scroll: ScrollContainer = $Root/Panel/Margin/Layout/Scroll
@onready var _tower_section: VBoxContainer = \
	$Root/Panel/Margin/Layout/Scroll/Pages/TowerSection
@onready var _virus_section: VBoxContainer = \
	$Root/Panel/Margin/Layout/Scroll/Pages/VirusSection
@onready var _tower_grid: GridContainer = \
	$Root/Panel/Margin/Layout/Scroll/Pages/TowerSection/TowerGrid
@onready var _virus_grid: GridContainer = \
	$Root/Panel/Margin/Layout/Scroll/Pages/VirusSection/VirusGrid

var _current_page := Page.TOWERS
var _open := false
var _previous_pause_state := false
var _panel_rest_position := Vector2.ZERO
var _transition_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_close_button.pressed.connect(close)
	_tower_tab.pressed.connect(func() -> void: show_page(Page.TOWERS))
	_virus_tab.pressed.connect(func() -> void: show_page(Page.VIRUSES))
	get_viewport().size_changed.connect(_update_grid_columns)
	_panel_rest_position = _panel.position
	_show_authored_page(Page.TOWERS)
	_root.hide()
	_update_grid_columns()


func open(page: Page = Page.TOWERS) -> void:
	if _open:
		show_page(page)
		return

	_open = true
	_previous_pause_state = get_tree().paused
	get_tree().paused = true
	show_page(page)
	_root.show()
	_root.modulate.a = 0.0
	_panel.position = _panel_rest_position + Vector2(84.0, 0.0)

	var tween := _create_transition_tween()
	tween.set_parallel(true)
	tween.tween_property(_root, "modulate:a", 1.0, open_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "position", _panel_rest_position, open_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(_close_button.grab_focus)


func close() -> void:
	if not _open:
		return

	_open = false
	var tween := _create_transition_tween()
	tween.set_parallel(true)
	tween.tween_property(_root, "modulate:a", 0.0, close_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_property(_panel, "position", _panel_rest_position + Vector2(84.0, 0.0), close_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(_finish_close)


func is_open() -> bool:
	return _open


func show_page(page: Page) -> void:
	_current_page = page
	_tower_tab.button_pressed = page == Page.TOWERS
	_virus_tab.button_pressed = page == Page.VIRUSES
	_title_label.text = "CYBER-INFO  /  %s" % ("TOWERS" if page == Page.TOWERS else "VIRUSES")
	_show_authored_page(page)


func _show_authored_page(page: Page) -> void:
	_tower_section.visible = page == Page.TOWERS
	_virus_section.visible = page == Page.VIRUSES
	_scroll.scroll_vertical = 0
	_update_grid_columns()


func _update_grid_columns() -> void:
	if _tower_grid == null or _virus_grid == null:
		return
	var viewport_width := get_viewport().get_visible_rect().size.x
	var columns := 1
	if viewport_width >= 1550.0:
		columns = 4
	elif viewport_width >= 1120.0:
		columns = 3
	elif viewport_width >= 760.0:
		columns = 2
	_tower_grid.columns = columns
	_virus_grid.columns = columns


func _create_transition_tween() -> Tween:
	if _transition_tween != null:
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return _transition_tween


func _finish_close() -> void:
	if _open:
		return
	_root.hide()
	_root.modulate.a = 1.0
	_panel.position = _panel_rest_position
	get_tree().paused = _previous_pause_state


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
