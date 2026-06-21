extends Area2D

@export var size: Vector2 = Vector2(48, 64):
	set(value):
		size = value
		_apply_size()
@export var color: Color = Color(0, 0, 0, 0):
	set(value):
		color = value
		if is_node_ready():
			polygon.color = value

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var polygon: Polygon2D = $Polygon2D


func _ready() -> void:
	_apply_size()
	polygon.color = color
	body_entered.connect(_on_body_entered)


func _apply_size() -> void:
	if not is_node_ready():
		return
	(collision.shape as RectangleShape2D).size = size
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	polygon.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	])


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("set_respawn"):
		body.set_respawn(global_position)
