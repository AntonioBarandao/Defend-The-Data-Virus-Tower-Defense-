extends CanvasLayer

const DESKTOP_PLATFORMS := [
	"Windows",
	"macOS",
	"Linux",
	"FreeBSD",
	"NetBSD",
	"OpenBSD",
	"BSD",
]
const ABSOLUTE_CURSOR_CANVAS_LAYER := 2147483647

@export var cursor_pivot_path: NodePath = ^"CursorPivot"
@export var hover_sprite_path: NodePath = ^"CursorPivot/HoverCursor"
@export var press_sprite_path: NodePath = ^"CursorPivot/PressCursor"

var _cursor_pivot: Node2D
var _hover_sprite: Sprite2D
var _press_sprite: Sprite2D
var _desktop_platform := false
var _custom_cursor_active := false
var _pressed_cursor_active := false
var _window_focused := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = ABSOLUTE_CURSOR_CANVAS_LAYER
	_cursor_pivot = get_node_or_null(cursor_pivot_path) as Node2D
	_hover_sprite = get_node_or_null(hover_sprite_path) as Sprite2D
	_press_sprite = get_node_or_null(press_sprite_path) as Sprite2D
	_desktop_platform = OS.get_name() in DESKTOP_PLATFORMS
	if not _desktop_platform:
		_set_cursor_visual_visible(false)
		return

	get_tree().root.focus_exited.connect(_on_window_focus_exited)
	get_tree().root.focus_entered.connect(_on_window_focus_entered)
	_set_custom_cursor_active(true)
	_sync_cursor_position(get_viewport().get_mouse_position())


func _process(_delta: float) -> void:
	if not _desktop_platform or not _window_focused:
		return

	# Keep the cursor authoritative across loading screens, paused menus, and
	# HUDs that consume mouse events before gameplay receives them.
	if not _custom_cursor_active:
		_set_custom_cursor_active(true)
	if layer != ABSOLUTE_CURSOR_CANVAS_LAYER:
		layer = ABSOLUTE_CURSOR_CANVAS_LAYER
	if _cursor_pivot != null:
		_cursor_pivot.z_as_relative = false
		_cursor_pivot.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	_sync_cursor_position(get_viewport().get_mouse_position())
	var left_button_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if _pressed_cursor_active != left_button_pressed:
		_pressed_cursor_active = left_button_pressed
		_sync_cursor_pose()
	if _cursor_pivot != null and not _cursor_pivot.visible:
		_cursor_pivot.visible = true
	if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _input(event: InputEvent) -> void:
	if not _desktop_platform:
		return

	# Desktop mouse emulation can generate touch events after a click. They must
	# never hide the universal desktop cursor or cancel its held pose.
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return

	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		_set_custom_cursor_active(true)
		_sync_cursor_position(mouse_motion.position)
		return

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		_set_custom_cursor_active(true)
		_sync_cursor_position(mouse_button.position)
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			set_pressed_cursor(mouse_button.pressed)


func set_pressed_cursor(pressed: bool) -> void:
	if not _desktop_platform:
		return
	if _pressed_cursor_active == pressed:
		return

	_pressed_cursor_active = pressed
	_sync_cursor_pose()


func is_custom_cursor_active() -> bool:
	return _custom_cursor_active


func is_pressed_cursor_active() -> bool:
	return _pressed_cursor_active


func _set_custom_cursor_active(active: bool) -> void:
	if _custom_cursor_active == active:
		return

	_custom_cursor_active = active
	if not active:
		_pressed_cursor_active = false
	_sync_cursor_pose()
	_apply_pointer_visibility()


func _sync_cursor_pose() -> void:
	if _hover_sprite != null:
		_hover_sprite.visible = not _pressed_cursor_active
	if _press_sprite != null:
		_press_sprite.visible = _pressed_cursor_active


func _sync_cursor_position(screen_position: Vector2) -> void:
	if _cursor_pivot != null:
		_cursor_pivot.position = screen_position


func _apply_pointer_visibility() -> void:
	var show_custom_cursor := _custom_cursor_active and _window_focused
	_set_cursor_visual_visible(show_custom_cursor)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if show_custom_cursor else Input.MOUSE_MODE_VISIBLE


func _set_cursor_visual_visible(value: bool) -> void:
	if _cursor_pivot != null:
		_cursor_pivot.visible = value


func _on_window_focus_exited() -> void:
	_window_focused = false
	_pressed_cursor_active = false
	_sync_cursor_pose()
	_apply_pointer_visibility()


func _on_window_focus_entered() -> void:
	_window_focused = true
	_apply_pointer_visibility()


func _exit_tree() -> void:
	if _desktop_platform:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
