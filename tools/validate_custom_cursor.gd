extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var controller := root.get_node_or_null("CustomCursorController")
	_check(controller != null, "CustomCursorController autoload is available")
	if controller == null:
		_finish()
		return

	var hover_texture := load("res://assets/UI/Cursor/DFD_Custom_Cursor_Hover.png") as Texture2D
	var press_texture := load("res://assets/UI/Cursor/DFD_Custom_Cursor_Press.png") as Texture2D
	_check(hover_texture != null and hover_texture.get_size() == Vector2(256, 256), "hover cursor is an imported 256x256 texture")
	_check(press_texture != null and press_texture.get_size() == Vector2(256, 256), "press cursor is an imported 256x256 texture")
	_check(controller is CanvasLayer, "custom cursor is an editable CanvasLayer scene")
	_check((controller as CanvasLayer).layer == 2147483647, "custom cursor uses the maximum canvas layer")
	var cursor_pivot := controller.get_node_or_null(^"CursorPivot") as Node2D
	_check(cursor_pivot != null, "cursor scene exposes a transformable pivot")
	_check(cursor_pivot != null and cursor_pivot.z_index == RenderingServer.CANVAS_ITEM_Z_MAX, "cursor visual uses the maximum CanvasItem z-index")
	_check(_cursor_art_preserves_emission(hover_texture), "hover cursor preserves bright blue emission with no visible green background")
	_check(_cursor_art_preserves_emission(press_texture), "press cursor preserves bright blue emission with no visible green background")

	var card_scene := load("res://Scenes/UI/TowerShopCard.tscn") as PackedScene
	var card := card_scene.instantiate() as TowerShopCard
	root.add_child(card)
	await process_frame
	card.open_information_popup()
	await process_frame
	var card_popup_layer := card.get("_information_popup_layer") as CanvasLayer
	_check(card_popup_layer != null and controller.layer > card_popup_layer.layer, "custom cursor renders above the live tower card popup layer")
	_check(cursor_pivot != null and cursor_pivot.visible, "tower card popup cannot hide the custom cursor")
	card.queue_free()
	paused = false
	await process_frame

	var press_event := InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = true
	Input.parse_input_event(press_event)
	await process_frame
	await process_frame
	_check(controller.is_pressed_cursor_active(), "left mouse press activates the pressed cursor")

	var drag_event := InputEventMouseMotion.new()
	drag_event.relative = Vector2(10, 4)
	Input.parse_input_event(drag_event)
	await process_frame
	await process_frame
	_check(controller.is_pressed_cursor_active(), "mouse drag keeps the pressed cursor active")
	paused = true
	if cursor_pivot != null:
		cursor_pivot.hide()
	await process_frame
	await process_frame
	_check(controller.is_pressed_cursor_active(), "paused UI cannot cancel a held press cursor")
	_check(cursor_pivot != null and cursor_pivot.visible, "always-process cursor restores itself above paused and loading UI")
	paused = false

	press_event = InputEventMouseButton.new()
	press_event.button_index = MOUSE_BUTTON_LEFT
	press_event.pressed = false
	Input.parse_input_event(press_event)
	await process_frame
	await process_frame
	_check(not controller.is_pressed_cursor_active(), "left mouse release restores the hover cursor")

	var touch_event := InputEventScreenTouch.new()
	touch_event.index = 0
	touch_event.pressed = true
	Input.parse_input_event(touch_event)
	await process_frame
	await process_frame
	_check(controller.is_custom_cursor_active(), "desktop touch emulation cannot hide the custom cursor")

	Input.parse_input_event(InputEventMouseMotion.new())
	await process_frame
	await process_frame
	_check(controller.is_custom_cursor_active(), "mouse or trackpad movement keeps the custom cursor active")
	_finish()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL: %s" % message)


func _cursor_art_preserves_emission(texture: Texture2D) -> bool:
	if texture == null:
		return false
	var image := texture.get_image()
	var cyan_pixels := 0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a > 0.03 and color.g > color.r + 0.14 and color.g > color.b + 0.14:
				return false
			if color.a > 0.95 and color.g > 0.62 and color.b > 0.72 and color.r < 0.35:
				cyan_pixels += 1
	return cyan_pixels > 250


func _finish() -> void:
	if _failures.is_empty():
		print("Custom cursor validation passed.")
		quit(0)
	else:
		quit(1)
