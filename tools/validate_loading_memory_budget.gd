extends SceneTree

const ASSETS_ROOT := "res://assets"
const PROJECT_SETTINGS_PATH := "res://project.godot"
const ASSET_CACHE_PATH := "res://Scripts/Menus/asset_cache.gd"

var _failed := false


func _init() -> void:
	var project_settings_text := FileAccess.get_file_as_string(
		PROJECT_SETTINGS_PATH
	)
	_check(
		"textures/vram_compression/import_s3tc_bptc=true"
			in project_settings_text,
		"Desktop VRAM texture compression must remain enabled."
	)
	_check(
		"textures/vram_compression/import_etc2_astc=true"
			in project_settings_text,
		"Mobile VRAM texture compression must remain enabled."
	)
	_check(
		"import/use_multiple_threads=false" in project_settings_text,
		"Large atlas imports must remain single-threaded to limit editor RAM."
	)

	var asset_cache_text := FileAccess.get_file_as_string(ASSET_CACHE_PATH)
	var ready_start := asset_cache_text.find("func _ready()")
	var next_function := asset_cache_text.find("\nfunc ", ready_start + 1)
	var ready_body := asset_cache_text.substr(
		ready_start,
		next_function - ready_start
	)
	_check(
		"load_startup_resources()" not in ready_body,
		"AssetCache must not eagerly load Cyber Guardian animations."
	)

	_validate_texture_imports(ASSETS_ROOT)
	if _failed:
		quit(1)
		return

	print("Loading memory budget validation passed.")
	quit(0)


func _validate_texture_imports(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	_check(directory != null, "Assets directory should be readable.")
	if directory == null:
		return

	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var entry_path := directory_path.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with("."):
				_validate_texture_imports(entry_path)
		elif entry.ends_with(".import"):
			_validate_texture_import(entry_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _validate_texture_import(import_path: String) -> void:
	var import_text := FileAccess.get_file_as_string(import_path)
	if "importer=\"texture\"" not in import_text:
		return

	var source_path := _read_source_path(import_text)
	var is_animation_atlas := "atlas" in source_path.to_lower()
	var is_loading_art := source_path.begins_with(
		"res://assets/LoadingScreen/"
	)
	if not is_animation_atlas and not is_loading_art:
		return

	_check(
		"compress/mode=2" in import_text,
		"Large startup texture must use VRAM compression: %s" % source_path
	)


func _read_source_path(import_text: String) -> String:
	const PREFIX := "source_file=\""
	var start := import_text.find(PREFIX)
	if start < 0:
		return ""
	start += PREFIX.length()
	var finish := import_text.find("\"", start)
	if finish < 0:
		return ""
	return import_text.substr(start, finish - start)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
