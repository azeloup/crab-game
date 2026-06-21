extends Node

## Gestionnaire de niveaux 
## Accessible partout dans le code via Levels.

signal level_changed(path: String)

var current_scene_path: String = ""


func _ready() -> void:
	var cur := get_tree().current_scene
	if cur != null:
		current_scene_path = cur.scene_file_path


func go_to_scene(scene: PackedScene) -> void:
	if scene == null:
		return
	current_scene_path = scene.resource_path
	get_tree().change_scene_to_packed(scene)
	level_changed.emit(current_scene_path)


func go_to_path(path: String) -> void:
	current_scene_path = path
	get_tree().change_scene_to_file(path)
	level_changed.emit(path)


func reload() -> void:
	get_tree().reload_current_scene()
