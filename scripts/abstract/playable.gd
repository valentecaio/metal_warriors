# The base class for all playable objects in the game.

class_name Playable extends CharacterBody2D
func custom_class_name(): return "Playable"


@onready var body_animated_sprite = $BodyAnimatedSprite2D
@onready var body_collision_shape = $BodyCollisionShape2D

# properties defined in the editor
@export var acceleration := 1.5
@export var friction := 2000

# state variables
var cannon_angle := 0.0
var flipped := false



### VIRTUALS ###

# flip all necessary sprites horizontally when facing left
func flip_sprites(flip):
  flipped = flip
  body_animated_sprite.flip_h = flip



### GAME LOOP ###

func _ready():
  print(custom_class_name() + " ready")



### HELPERS ###

# evaluate velocity with inertia
func eval_velocity(initial_velocity, input, delta, max_speed):
  if input:
    var vel = initial_velocity + (input * max_speed * delta * acceleration)
    return clamp(vel, -max_speed, max_speed)
  else:
    return move_toward(initial_velocity, 0, friction * delta)


# evaluate horizontal velocity and flip sprites if necessary
func move_with_inertia(delta, dir, max_speed):
  if dir.x:
    flip_sprites(dir.x < 0)
  velocity.x = eval_velocity(velocity.x, dir.x, delta, max_speed)


# apply gravity to robot
func apply_gravity(delta):
  velocity += get_gravity() * delta


# return cannon angle in radians, rounded to a multiple of 22.5 degrees
# and flipped when facing left
func eval_cannon_angle():
  var angle = -cannon_angle if flipped else cannon_angle
  return deg_to_rad(round(angle / 22.5) * 22.5)
