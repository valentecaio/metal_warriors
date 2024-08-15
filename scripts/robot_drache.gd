extends CharacterBody2D

@export var speed = 250.0

@onready var body_animated_sprite = $BodyAnimatedSprite2D
@onready var shot_animated_sprite = $ShotAnimatedSprite2D

const SQRT2 = 1.41421356
const BULLET = preload("res://scenes/bullet_drache.tscn")

var time_to_next_shot = 0.0

# angle in degrees
func fire(angle):
  var direction = Vector2(1.0, 0.0).rotated(deg_to_rad(angle)).normalized()
  var bullet = BULLET.instantiate()
  bullet.direction = direction
  bullet.position = global_position + Vector2(0,5)
  get_parent().add_child(bullet)
  time_to_next_shot = 1.0/bullet.fire_frequency


func _physics_process(delta):
  time_to_next_shot -= delta

  # movement
  var direction_hor = Input.get_axis("left", "right")
  var direction_ver = Input.get_axis("up", "down")
  if direction_hor and direction_ver: # avoid going faster diagonally
    direction_hor /= SQRT2
    direction_ver /= SQRT2
  velocity.x = (direction_hor * speed) if direction_hor else move_toward(velocity.x, 0, speed)
  velocity.y = (direction_ver * speed) if direction_ver else move_toward(velocity.y, 0, speed)

  # movement animation
  if direction_hor:
    body_animated_sprite.play("move_right")
    body_animated_sprite.flip_h = direction_hor < 0 # flip animation
  elif direction_ver:
    body_animated_sprite.play("move_up" if (direction_ver < 0) else "move_down")
  else:
    body_animated_sprite.play("idle")

  # shooting (the order of elifs matters)
  shot_animated_sprite.visible = true
  var angle
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
  else:
    shot_animated_sprite.visible = false

  if shot_animated_sprite.visible and time_to_next_shot < 0:
    shot_animated_sprite.position = Vector2(0, 5) + Vector2(12, 0).rotated(deg_to_rad(angle))
    shot_animated_sprite.rotation = deg_to_rad(angle + 90) # add 90 because base sprite points upwards
    fire(angle)

  move_and_slide()
