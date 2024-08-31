extends CharacterBody2D


@export var aim_speed := 250
@export var speed := 250
@export var acceleration := 3.0
@export var friction := 2000
@export var jump_speed := -500

@onready var body_animated_sprite = $BodyAnimatedSprite2D
@onready var cannon = $Cannon
@onready var cannon_rotation_node = $Cannon/CannonRotation
@onready var cannon_animated_sprite = $Cannon/CannonRotation/CannonAnimatedSprite2D
@onready var cannon_animation = $Cannon/CannonAnimationPlayer

var cannon_angle = 0
var flipped = false

# change velocity with inertia
func eval_velocity(initial_velocity, input, delta):
  if input:
    return initial_velocity + input * speed * delta * acceleration
  else:
    return move_toward(initial_velocity, 0, friction * delta)

func flip_body_and_cannon(flip):
  # flip sprites
  body_animated_sprite.flip_h = flip
  cannon_animated_sprite.flip_h = flip

  # flip positions
  if flip:
    cannon.position = Vector2(-2, -8)
    cannon_rotation_node.position = Vector2(-11, 4)
  else:
    cannon.position = Vector2(2, -8)
    cannon_rotation_node.position = Vector2(11, 4)

func rotate_cannon(angle):
  # only acceptable values are -90, -45, 0, 45, 90
  angle = round(angle / 45) * 45
  cannon.rotation = deg_to_rad(angle)


func _physics_process(delta):
  # gravity
  if not is_on_floor():
    velocity += get_gravity() * delta

  var dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()

  # walk
  if dir.x:
    body_animated_sprite.play("walk")
    cannon_animation.play("cannon_walk")
    flipped = dir.x < 0
    flip_body_and_cannon(flipped)
  else:
    body_animated_sprite.pause()
    cannon_animation.pause()
  velocity.x = clamp(eval_velocity(velocity.x, dir.x, delta), -speed, speed)

  # cannon aiming
  cannon_angle += dir.y * aim_speed * delta
  cannon_angle = clamp(cannon_angle, -90, 90)
  rotate_cannon(-cannon_angle if flipped else cannon_angle)

  # jump
  # if Input.is_action_just_pressed("button_south") and is_on_floor():
  #   velocity.y = jump_speed
  #   body_animated_sprite.play("jump")


  move_and_slide()
