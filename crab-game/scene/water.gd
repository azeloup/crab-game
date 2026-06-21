extends Area2D

@export var size: Vector2 = Vector2(6000, 4000):
	set(value):
		size = value
		_apply_size()
@export var color: Color = Color(0.2, 0.5, 0.9, 0.45):
	set(value):
		color = value
		if is_node_ready():
			polygon.color = value
@export var rise_speed: float = 30.0
@export var drown_time: float = 3.0 
@export var has_max_level: bool = false
@export var max_level_y: float = 0.0  

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var polygon: Polygon2D = $Polygon2D

var _time_in: Dictionary = {}
var _start_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_apply_size()
	polygon.color = color
	add_to_group("water")
	_start_position = position


func reset() -> void:
	# Remet l'eau à son niveau de départ
	position = _start_position
	_time_in.clear()


func _apply_size() -> void:
	if not is_node_ready():
		return
	(collision.shape as RectangleShape2D).size = size
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	polygon.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)
	])


func _physics_process(delta: float) -> void:
	position.y -= rise_speed * delta
	if has_max_level:
		var surface_y := position.y - size.y * 0.5
		if surface_y < max_level_y:
			position.y = max_level_y + size.y * 0.5

	var still := {}
	for body in get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		if body.has_method("notify_in_water"):
			body.notify_in_water()
		var t: float = _time_in.get(body, 0.0) + delta
		if t >= drown_time:
			t = 0.0
			if body.has_method("die"):
				body.die()
		still[body] = t
	_time_in = still
