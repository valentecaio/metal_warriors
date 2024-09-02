extends CharacterBody2D

@export var speed := 250
@export var acceleration := 3.0
@export var friction := 600

@onready var body_animated_sprite = $BodyAnimatedSprite2D
@onready var shot_animated_sprite = $ShotAnimatedSprite2D
@onready var default_collision_shape = $DefaultCollisionShape2D
@onready var power_dive_collision_shape = $PowerDiveCollisionShape2D

const bullet_scene = preload("res://scenes/bullets/energy_cannon.tscn")
var time_to_next_shot := 0.0

var power_dive := false:
  set(value):
    power_dive = value
    default_collision_shape.disabled = value
    power_dive_collision_shape.disabled = !value


# angle in degrees
func fire(angle):
  var direction = Vector2(1.0, 0.0).rotated(deg_to_rad(angle)).normalized()
  var bullet = bullet_scene.instantiate()
  bullet.direction = direction
  bullet.position = global_position + Vector2(0,5)
  get_parent().add_child(bullet)
  time_to_next_shot = 1.0/bullet.fire_frequency


# change velocity with inertia
func eval_velocity(initial_velocity, input, delta):
  if input:
    return initial_velocity + input * speed * delta * acceleration
  else:
    return move_toward(initial_velocity, 0, friction * delta)


func _physics_process(delta):
  time_to_next_shot -= delta

  # power dive
  power_dive = Input.is_action_pressed("shoulder_right")
  if power_dive:
    body_animated_sprite.play("power_dive")
    shot_animated_sprite.visible = false
    velocity.x = eval_velocity(velocity.x, 0, delta)
    velocity.y = clamp(eval_velocity(velocity.y, Vector2.DOWN.y, delta), 0, 2*speed)
    move_and_slide()
    return

  ### else ###

  # movement
  var dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()
  if dir.x:
    body_animated_sprite.play("move_right")
    body_animated_sprite.flip_h = dir.x < 0 # flip animation
  elif dir.y > 0:
    body_animated_sprite.play("move_up")
  elif dir.y < 0:
    body_animated_sprite.play("move_down")
  else:
    body_animated_sprite.play("idle")
  velocity.x = clamp(eval_velocity(velocity.x, dir.x, delta), -speed, speed)
  velocity.y = clamp(eval_velocity(velocity.y, dir.y, delta), -speed, speed)
  move_and_slide()

  # shooting (the order of elifs matters)
  var angle = null
  if   Input.is_action_pressed("button_south") and Input.is_action_pressed("button_east"):
    angle = 45
  elif Input.is_action_pressed("button_south") and Input.is_action_pressed("button_west"):
    angle = 135
  elif Input.is_action_pressed("button_north") and Input.is_action_pressed("button_west"):
    angle = 225
  elif Input.is_action_pressed("button_north") and Input.is_action_pressed("button_east"):
    angle = 315
  elif Input.is_action_pressed("button_east"):
    angle = 0
  elif Input.is_action_pressed("button_south"):
    angle = 90
  elif Input.is_action_pressed("button_west"):
    angle = 180
  elif Input.is_action_pressed("button_north"):
    angle = 270

  shot_animated_sprite.visible = angle != null

  if shot_animated_sprite.visible and time_to_next_shot < 0:
    shot_animated_sprite.position = Vector2(0, 5) + Vector2(12, 0).rotated(deg_to_rad(angle))
    shot_animated_sprite.rotation = deg_to_rad(angle + 90) # add 90 because base sprite points upwards
    fire(angle)
