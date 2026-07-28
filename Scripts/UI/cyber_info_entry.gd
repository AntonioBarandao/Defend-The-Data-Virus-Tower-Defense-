@tool
class_name CyberInfoEntry
extends Resource

enum Category {
	TOWER,
	VIRUS,
}

@export var entry_id: StringName = &""
@export var category: Category = Category.TOWER
@export var display_name := ""
@export var type_label := ""
@export_multiline var description := ""
@export var images: Array[Texture2D] = []
@export var slide_labels: Array[String] = []


func get_slide_label(index: int) -> String:
	if index >= 0 and index < slide_labels.size() and not slide_labels[index].is_empty():
		return slide_labels[index]
	return "Variant %d" % (index + 1)
