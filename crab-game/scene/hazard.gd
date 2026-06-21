@tool
extends Area2D

@export var size: Vector2 = Vector2(64, 16):
	set(value):
		size = value
		_apply_size()

@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_apply_size()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _apply_size() -> void:
	if not is_node_ready():
		return
	var rect := collision.shape as RectangleShape2D
	if rect != null:
		rect.size = size


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		body.die()
