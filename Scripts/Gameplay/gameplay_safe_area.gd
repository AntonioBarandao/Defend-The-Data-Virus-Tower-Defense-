class_name GameplaySafeArea
extends RefCounted

const FALLBACK_DESIGN_SIZE := Vector2(1920.0, 1080.0)


static func get_centered_screen_rect(viewport: Viewport) -> Rect2:
	if viewport == null:
		return Rect2(Vector2.ZERO, FALLBACK_DESIGN_SIZE)

	var viewport_rect := viewport.get_visible_rect()
	if viewport_rect.size.x <= 0.0 or viewport_rect.size.y <= 0.0:
		return Rect2(Vector2.ZERO, FALLBACK_DESIGN_SIZE)

	var design_size := Vector2(
		float(ProjectSettings.get_setting(
			"display/window/size/viewport_width",
			FALLBACK_DESIGN_SIZE.x
		)),
		float(ProjectSettings.get_setting(
			"display/window/size/viewport_height",
			FALLBACK_DESIGN_SIZE.y
		))
	)
	var design_aspect := design_size.x / maxf(1.0, design_size.y)
	var safe_size := viewport_rect.size
	if safe_size.x / safe_size.y > design_aspect:
		safe_size.x = safe_size.y * design_aspect
	else:
		safe_size.y = safe_size.x / design_aspect

	return Rect2(
		viewport_rect.position + (viewport_rect.size - safe_size) * 0.5,
		safe_size
	)
