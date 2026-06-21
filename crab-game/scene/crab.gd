extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -350.0
@export var wall_climb_speed: float = 250.0
@export var wall_jump_push: float = 250.0
@export var wall_jump_up: float = 350.0
@export var rotation_lerp_speed: float = 12.0
@export var wall_stick_cooldown: float = 0.15
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.4
@export var dash_ghost_fade: float = 0.3
@export var water_gravity_scale: float = 0.25 
@export var water_drag: float = 4.0
@export var water_speed: float = 160.0
@export var swim_impulse: float = -260.0

enum State { NORMAL, WALL_STICK, DASH }

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var state: State = State.NORMAL
var wall_normal: Vector2 = Vector2.ZERO
var stick_cooldown: float = 0.0
var facing: float = 1.0
var dash_dir: float = 1.0
var dash_timer: float = 0.0
var dash_cd_timer: float = 0.0
var air_dash_available: bool = true
var respawn_position: Vector2 = Vector2.ZERO
var _last_water_frame: int = -10


func _ready() -> void:
	add_to_group("player")
	respawn_position = global_position


func _physics_process(delta: float) -> void:
	stick_cooldown = max(0.0, stick_cooldown - delta)
	dash_cd_timer = max(0.0, dash_cd_timer - delta)

	match state:
		State.NORMAL:
			_process_normal(delta)
		State.WALL_STICK:
			_process_wall_stick(delta)
		State.DASH:
			_process_dash(delta)

	_update_rotation(delta)
	_update_animation()


func _process_normal(delta: float) -> void:
	if is_on_floor():
		air_dash_available = true

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = signf(direction)

	# Dash 
	if Input.is_action_just_pressed("dash") and dash_cd_timer == 0.0:
		var grounded := is_on_floor()
		if grounded or air_dash_available:
			if not grounded:
				air_dash_available = false
			_start_dash(direction)
			return

	if _is_in_water():
		_apply_water_physics(direction, delta)
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Saut au sol
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

		velocity.x = direction * speed

	move_and_slide()

	# Accroched
	if not is_on_floor() and is_on_wall() and stick_cooldown == 0.0:
		state = State.WALL_STICK
		wall_normal = get_wall_normal()
		velocity = Vector2.ZERO
		air_dash_available = true


func _process_wall_stick(_delta: float) -> void:
	var tangent := wall_normal.orthogonal()           # direction le long du mur
	var direction := Input.get_axis("move_right", "move_left")
	velocity = tangent * direction * wall_climb_speed - wall_normal * 20.0

	# Saut diagonal opposé -> détache
	if Input.is_action_just_pressed("jump"):
		velocity = wall_normal * wall_jump_push + Vector2.UP * wall_jump_up
		stick_cooldown = wall_stick_cooldown
		state = State.NORMAL
		return

	move_and_slide()

	if is_on_floor() or not is_on_wall():
		stick_cooldown = wall_stick_cooldown
		state = State.NORMAL


func _start_dash(input_dir: float) -> void:
	dash_dir = signf(input_dir) if input_dir != 0.0 else facing
	dash_timer = dash_duration
	dash_cd_timer = dash_cooldown
	state = State.DASH


func _process_dash(delta: float) -> void:
	dash_timer -= delta
	velocity = Vector2(dash_dir * dash_speed, 0.0)
	move_and_slide()
	_spawn_dash_ghost()

	if dash_timer <= 0.0:
		state = State.NORMAL


func _spawn_dash_ghost() -> void:
	var frames := sprite.sprite_frames
	if frames == null:
		return
	var tex := frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return

	var ghost := Sprite2D.new()
	var holder := get_parent()
	if holder == null:
		holder = self
	holder.add_child(ghost)

	ghost.texture = tex
	ghost.centered = sprite.centered
	ghost.offset = sprite.offset
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.global_transform = sprite.global_transform
	ghost.z_index = sprite.z_index - 1

	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, dash_ghost_fade)
	tw.tween_callback(ghost.queue_free)


func _update_rotation(delta: float) -> void:
	var target := 0.0
	if state == State.WALL_STICK:
		target = wall_normal.angle() + PI / 2.0
	sprite.rotation = lerp_angle(
		sprite.rotation, target, 1.0 - exp(-rotation_lerp_speed * delta))


func _update_animation() -> void:
	var moving := Input.get_axis("move_left", "move_right") != 0.0
	if state == State.DASH:
		sprite.play("walk")
	elif state == State.WALL_STICK:
		sprite.play("walk" if moving else "idle")
	elif moving and is_on_floor():
		sprite.play("walk")
	else:
		sprite.play("idle")


func notify_in_water() -> void:
	# Appelé chaque frame par l'eau tant que le crabe est immergé
	_last_water_frame = Engine.get_physics_frames()


func _is_in_water() -> bool:
	return Engine.get_physics_frames() - _last_water_frame <= 1


func _apply_water_physics(direction: float, delta: float) -> void:
	# Gravité réduite : le crabe coule lentement (poussée d'Archimède)
	velocity.y += get_gravity().y * water_gravity_scale * delta
	# Nage : impulsion vers le haut à chaque appui sur saut (illimité dans l'eau)
	if Input.is_action_just_pressed("jump"):
		velocity.y = swim_impulse
	# Résistance de l'eau : amortissement (indépendant du framerate)
	var damp := 1.0 - exp(-water_drag * delta)
	velocity.y = lerp(velocity.y, 0.0, damp)
	velocity.x = lerp(velocity.x, direction * water_speed, damp)


func set_respawn(pos: Vector2) -> void:
	respawn_position = pos


func die() -> void:
	# Réapparition au dernier point de respawn + remise à zéro de l'état
	global_position = respawn_position
	velocity = Vector2.ZERO
	state = State.NORMAL
	dash_timer = 0.0
	dash_cd_timer = 0.0
	stick_cooldown = 0.0
	air_dash_available = true
	sprite.rotation = 0.0

	# Petit clignotement de réapparition
	sprite.modulate.a = 0.2
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 1.0, 0.3)
