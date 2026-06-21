extends Area2D

## Objectif de fin de niveau : affiche un message quand le joueur l'atteint.

@export var size: Vector2 = Vector2(48, 64):
	set(value):
		size = value
		_apply_size()
@export var color: Color = Color(1, 0.85, 0.1, 0.7):
	set(value):
		color = value
		if is_node_ready():
			polygon.color = value

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var polygon: Polygon2D = $Polygon2D

var _done := false


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
	if _done or not body.is_in_group("player"):
		return
	_done = true
