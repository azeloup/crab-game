extends CanvasLayer

@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_node_ready():
			rect.visible = value
@export var radius: float = 120.0
@export var softness: float = 60.0
@export_node_path("Node2D") var target_path: NodePath

@onready var rect: ColorRect = $ColorRect

var _target: Node2D


func _ready() -> void:
	rect.visible = enabled
	_resolve_target()


func _resolve_target() -> void:
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path)
	if _target == null:
		_target = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	if not enabled:
		return
	if _target == null or not is_instance_valid(_target):
		_resolve_target()
		if _target == null:
			return
	var mat: ShaderMaterial = rect.material
	mat.set_shader_parameter("player_pos", _target.get_global_transform_with_canvas().origin)
	mat.set_shader_parameter("radius", radius)
	mat.set_shader_parameter("softness", softness)
