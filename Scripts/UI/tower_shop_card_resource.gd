class_name TowerShopCardResource
extends Resource

@export var tower_id: StringName = &""
@export var display_name := "Tower"
@export var deploy_cost := 0
@export var free_text := "FREE"
@export var display_texture: Texture2D
@export var tower_scene: PackedScene
@export_group("Information")
@export var info_header := ""
@export_multiline var info_description := ""
@export var tower_type := "Tower"
@export var upgrade_costs: Array[int] = []
@export_group("")
