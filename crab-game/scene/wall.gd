extends StaticBody2D

@export var size: Vector2 = Vector2(800, 32):
	set(value):
		size = value
		_apply_size()

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply_size()


func _apply_size() -> void:
	if not is_node_ready():
		return
	collision.shape.size = size
	sprite.region_rect = Rect2(Vector2.ZERO, size)
