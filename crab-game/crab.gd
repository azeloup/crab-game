extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -350.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Saut
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * speed

	move_and_slide()
	_update_animation(direction)


func _update_animation(direction: float) -> void:
	if direction != 0.0 and is_on_floor():
		sprite.play("walk")
	else:
		sprite.play("idle")
