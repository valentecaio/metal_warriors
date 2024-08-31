extends CharacterBody2D


@export var speed := 250
@export var acceleration := 3.0
@export var friction := 2000

@onready var body_animated_sprite = $BodyAnimatedSprite2D
@onready var cannon = $Cannon
@onready var cannon_rotation_node = $Cannon/CannonRotation
@onready var cannon_animated_sprite = $Cannon/CannonRotation/CannonAnimatedSprite2D
@onready var cannon_animation = $Cannon/CannonAnimationPlayer


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
    # cannon.position = Vector(2, -8)
    # cannon.position = Vector2(13 if flip else -13, -2)

# rotate cannon relative to its parent
# the left of the cannon is fixed at the origin
func rotate_cannon(angle):
  angle = deg_to_rad(angle)
  cannon.rotation = angle


func _physics_process(delta):
  # gravity.
  if not is_on_floor():
    velocity += get_gravity() * delta

  var dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()
  if dir.x:
    body_animated_sprite.play("walk")
    cannon_animation.play("cannon_walk")
    print(body_animated_sprite.frame)
    flip_body_and_cannon(dir.x < 0)
  else:
    body_animated_sprite.pause()
    cannon_animation.pause()
  velocity.x = clamp(eval_velocity(velocity.x, dir.x, delta), -speed, speed)
  move_and_slide()

  if dir.y > 0:
    rotate_cannon(45)
  elif dir.y < 0:
    rotate_cannon(-45)
  else:
    rotate_cannon(0)

  # # Handle jump.
  # if Input.is_action_just_pressed("ui_accept") and is_on_floor():
  #   velocity.y = JUMP_VELOCITY

  # # Get the input direction and handle the movement/deceleration.
  # # As good practice, you should replace UI actions with custom gameplay actions.
  # var direction = Input.get_axis("ui_left", "ui_right")
  # if direction:
  #   velocity.x = direction * SPEED
  # else:
  #   velocity.x = move_toward(velocity.x, 0, SPEED)

  # move_and_slide()
