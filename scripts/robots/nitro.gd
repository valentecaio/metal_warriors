extends CharacterBody2D


@export var aim_speed := 250
@export var max_walk_speed := 200
@export var max_fly_speed := 300
@export var acceleration := 2.0
@export var friction := 2000
@export var jump_speed := -350

@onready var body_animated_sprite = $BodyAnimatedSprite2D
@onready var cannon = $Cannon
@onready var cannon_rotation_node = $Cannon/CannonRotation
@onready var cannon_animated_sprite = $Cannon/CannonRotation/CannonAnimatedSprite2D
@onready var cannon_animation = $Cannon/CannonAnimationPlayer

enum State {WALK, JUMP, FALL, FLY, LAND, SHIELD, SWORD}


# state variables
var state := State.WALK
var cannon_angle := 0.0
var flipped := false
# var flight_time := 0.0


func _ready():
  # set initial state
  state = State.WALK
  body_animated_sprite.play("walk")
  body_animated_sprite.pause()
  # body_animated_sprite.connect("animation_finished", self, _on_animation_finished)


func _physics_process(delta):
  var dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()

  match state:
    State.WALK:
      process_walk(delta, dir)
    State.JUMP:
      process_jump(delta, dir)
    State.FALL:
      process_fall(delta, dir)
    State.FLY:
      process_fly(delta, dir)
    State.LAND:
      process_land(delta, dir)
    # State.SHIELD:
    #   process_shield(delta, dir)
    # State.SWORD:
    #   process_sword(delta, dir)

  # cannon aiming is always active
  cannon_angle += dir.y * aim_speed * delta
  cannon_angle = clamp(cannon_angle, -90, 90)
  rotate_cannon(-cannon_angle if flipped else cannon_angle)

  move_and_slide()


func process_walk(delta, dir):
  print("process_walk()")
  move_and_gravity(delta, dir, max_walk_speed)

  # walk animation
  if dir.x:
    body_animated_sprite.play("walk")
    cannon_animation.play("cannon_walk")
  else:
    body_animated_sprite.pause()
    cannon_animation.pause()

  # check falling
  if not is_on_floor():
    cannon_animation.pause()
    return set_state(State.FALL)

  # check jump button
  if Input.is_action_just_pressed("button_south"):
    cannon_animation.pause()
    velocity.y = jump_speed
    return set_state(State.JUMP)


func process_jump(delta, dir):
  print("process_jump()")
  move_and_gravity(delta, dir, max_walk_speed)

  # check if should go to fall of fly state
  # TODO: should be done at animation end callback
  if velocity.y >= 0:
    if Input.is_action_pressed("button_south"):
      return set_state(State.FLY)
    else:
      return set_state(State.FALL)


func process_fall(delta, dir):
  print("process_fall()")
  move_and_gravity(delta, dir, max_walk_speed)

  # check fly button
  if Input.is_action_pressed("button_south"):
    return set_state(State.FLY)

  # check landing
  if is_on_floor():
    return set_state(State.LAND)


func process_fly(delta, dir):
  print("process_fly()")
  move_and_gravity(delta, dir, max_fly_speed)

  # state is locked while button is pressed
  if Input.is_action_pressed("button_south"):
    velocity -= get_gravity() * delta # no gravity when flying
    velocity.y = eval_velocity(velocity.y, -1, delta, max_fly_speed)
  else:
    # check falling
    if velocity.y >= 0:
      return set_state(State.FALL)

    # check landing
    if is_on_floor():
      return set_state(State.LAND)


func process_land(delta, dir):
  print("process_land()")
  move_and_gravity(delta, dir, max_fly_speed)
  # TODO: should be done at animation end callback
  set_state(State.WALK)



### CALLBACKS ###

# TODO
func _on_animation_finished(anim_name: String):
  print("_on_animation_finished() ", anim_name)
  pass



### HELPERS ###

# evaluate velocity with inertia
func eval_velocity(initial_velocity, input, delta, max_speed):
  if input:
    var vel = initial_velocity + (input * max_speed * delta * acceleration)
    return clamp(vel, -max_speed, max_speed)
  else:
    return move_toward(initial_velocity, 0, friction * delta)


# flip body and cannon horizontally when facing left
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


# rotate cannon relative to the body
func rotate_cannon(angle):
  # round to one of [-90, -45, 0, 45, 90]
  angle = round(angle / 45) * 45
  cannon.rotation = deg_to_rad(angle)


func set_state(new_state):
  state = new_state
  match state:
    State.WALK:
      body_animated_sprite.play("idle")
    State.JUMP:
      body_animated_sprite.play("jump")
    State.FALL:
      body_animated_sprite.play("fall")
    State.FLY:
      body_animated_sprite.play("fly")
    State.LAND:
      body_animated_sprite.play("land")
    State.SHIELD:
      body_animated_sprite.play("shield")
    # State.SWORD:
    #   body_animated_sprite.play("sword")


# evaluate horizontal velocity and flip sprites if necessary
func move_and_gravity(delta, dir, max_speed):
  if dir.x:
    flipped = dir.x < 0
    flip_body_and_cannon(flipped)
  velocity.x = eval_velocity(velocity.x, dir.x, delta, max_speed)
  velocity += get_gravity() * delta
