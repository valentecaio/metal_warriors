extends CharacterBody2D


@onready var body_animated_sprite = $BodyAnimatedSprite2D
@onready var shield_collision_shape = $ShieldCollisionShape2D
@onready var cannon = $Cannon
@onready var cannon_animated_sprite = $Cannon/CannonAnimatedSprite2D
@onready var boarding_area = $BoardingArea2D

# properties defined in the editor
@export var aim_speed := 150
@export var max_walk_speed := 200
@export var max_fly_speed := 300
@export var acceleration := 2.0
@export var friction := 2000
@export var jump_speed := -350

# main state machine
@export var state := State.WALK
enum State {WALK, JUMP, FALL, FLY, LAND, SHIELD, SWORD, UNBOARDED}

# state machine for start/stop animations: STOPPING -> OFF -> STARTING
enum PowerState {STOPPING, OFF, STARTING}
var power_state := PowerState.OFF

# bullets
const bullet_scene = preload("res://scenes/bullets/fusion_rifle.tscn")
var time_to_next_shot := 0.0

# state variables
var cannon_angle := 0.0
var flipped := false
var cannon_animation := "idle"
var shooting := false
var pilot = null
# var flight_time := 0.0


func _ready():
  print("Nitro ready")
  # body_animated_sprite.connect("animation_finished", self, _on_animation_finished)

  if state == State.UNBOARDED:
    cannon.hide()
    body_animated_sprite.play("idle_off")
  else:
    cannon.show()
    body_animated_sprite.play("idle_on")


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
    State.SHIELD:
      process_shield(delta, dir)
    # State.SWORD:
    #   process_sword(delta, dir)
    State.UNBOARDED:
      process_unboarded(delta, dir)

  # cannon aiming is always enabled
  process_aim(delta, dir)

  # cannon animation is set only once per loop
  cannon_animated_sprite.play("shoot" if shooting else cannon_animation)

  move_and_slide()


func process_walk(delta, dir):
  # print("process_walk()")
  move_with_inertia(delta, dir, max_walk_speed)
  apply_gravity(delta)

  process_shoot(delta)

  # walk animation
  if dir.x:
    body_animated_sprite.play("walk")
    cannon_animation = "walk"
  else:
    body_animated_sprite.pause()
    cannon_animation = "idle"

  # check if falling
  if not is_on_floor():
    return set_state(State.FALL)

  # check jump button
  if Input.is_action_just_pressed("button_south"):
    return set_state(State.JUMP)

  # check shield button
  if Input.is_action_just_pressed("shoulder_right"):
    return set_state(State.SHIELD)

  # check eject button
  if Input.is_action_just_pressed("button_select"):
    return set_state(State.UNBOARDED)


func process_jump(delta, dir):
  # print("process_jump()")
  move_with_inertia(delta, dir, max_walk_speed)
  apply_gravity(delta)

  process_shoot(delta)

  # check if should go to fall of fly state
  # TODO: should be done at animation end callback
  if velocity.y >= 0:
    if Input.is_action_pressed("button_south"):
      return set_state(State.FLY)
    else:
      return set_state(State.FALL)


func process_fall(delta, dir):
  # print("process_fall()")
  move_with_inertia(delta, dir, max_walk_speed)
  apply_gravity(delta)

  process_shoot(delta)

  # check fly button
  if Input.is_action_pressed("button_south"):
    return set_state(State.FLY)

  # check landing
  if is_on_floor():
    return set_state(State.LAND)


func process_fly(delta, dir):
  # print("process_fly()")
  move_with_inertia(delta, dir, max_fly_speed)
  apply_gravity(delta)

  process_shoot(delta)

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
  # print("process_land()")
  move_with_inertia(delta, dir, max_fly_speed)
  apply_gravity(delta)

  process_shoot(delta)

  # TODO: should be done at animation end callback
  set_state(State.WALK)


func process_shield(delta, dir):
  # print("process_shield()")
  move_with_inertia(delta, Vector2.ZERO)
  apply_gravity(delta)

  if dir.x:
    flip_body_and_cannon(dir.x < 0)

  # flip shield collision shape when facing left
  shield_collision_shape.position.x = -15 if flipped else 15

  # check shield button
  if not Input.is_action_pressed("shoulder_right"):
    return set_state(State.WALK)


func process_unboarded(delta, _dir):
  move_with_inertia(delta, Vector2.ZERO)
  apply_gravity(delta)

  match power_state:
    PowerState.STOPPING:
      # wait until "power_off" animation finishes, then go to OFF state
      if not body_animated_sprite.is_playing():
        body_animated_sprite.play("idle_off")
        power_state = PowerState.OFF
    PowerState.OFF:
      # wait until a pilot script triggers drive()
      pass
    PowerState.STARTING:
      # wait until "power_on" animation finishes, then go to WALK state
      if not body_animated_sprite.is_playing():
        return set_state(State.WALK)


func process_shoot(delta):
  # update time to next shot
  time_to_next_shot -= delta
  if time_to_next_shot > 0:
    return

  # check shoot button
  shooting = Input.is_action_pressed("button_west")
  if shooting:
    var bullet = bullet_scene.instantiate()
    var angle = eval_cannon_angle()
    bullet.direction = Vector2(-1 if flipped else 1, 0).rotated(angle).normalized()
    bullet.position = global_position + Vector2(-23 if flipped else 23, -3).rotated(angle)
    get_parent().add_child(bullet)
    time_to_next_shot = 1.0/bullet.fire_frequency
  else:
    cannon_animation = "idle"


func process_aim(delta, dir):
  if dir == Vector2.ZERO:
    return

  # update cannon angle according to input
  var pressed_angle := 0.0
  if dir.x and dir.y:
    pressed_angle = 45 if dir.y > 0 else -45
  elif dir.y:
    pressed_angle = 90 if dir.y > 0 else -90
  elif dir.x:
    pressed_angle = 0
  cannon_angle = move_toward(cannon_angle, pressed_angle, aim_speed * delta)

  # rotate cannon sprite
  cannon.rotation = eval_cannon_angle()



### CALLBACKS ###

# TODO
func _on_animation_finished(anim_name: String):
  print("_on_animation_finished() ", anim_name)


# called by pilot script after boarding robot
func drive(new_pilot):
  print("Nitro boarded")
  if (pilot != null) or (power_state != PowerState.OFF):
    return # robot already occupied

  # start robot
  pilot = new_pilot
  power_state = PowerState.STARTING
  body_animated_sprite.play("power_on")



### HELPERS ###

# evaluate velocity with inertia
func eval_velocity(initial_velocity, input, delta, max_speed):
  if input:
    var vel = initial_velocity + (input * max_speed * delta * acceleration)
    return clamp(vel, -max_speed, max_speed)
  else:
    return move_toward(initial_velocity, 0, friction * delta)


# evaluate horizontal velocity and flip sprites if necessary
func move_with_inertia(delta, dir, max_speed = max_walk_speed):
  if dir.x:
    flip_body_and_cannon(dir.x < 0)
  velocity.x = eval_velocity(velocity.x, dir.x, delta, max_speed)


func apply_gravity(delta):
  velocity += get_gravity() * delta


# return cannon angle in radians, rounded to a multiple of 22.5 degrees
# and flipped when facing left
func eval_cannon_angle():
  # cannon rotation is inverted when facing left
  var angle = -cannon_angle if flipped else cannon_angle

  # round to a multiple of 22.5 degrees
  angle = round(angle / 22.5) * 22.5

  # return angle in radians
  return deg_to_rad(angle)


# flip body and cannon horizontally when facing left
func flip_body_and_cannon(flip):
  # save flipped state
  flipped = flip

  # flip sprites
  body_animated_sprite.flip_h = flip
  cannon_animated_sprite.flip_h = flip

  # flip positions
  if flip:
    cannon.position.x = -2
    cannon_animated_sprite.position.x = -10.5
  else:
    cannon.position.x = 2
    cannon_animated_sprite.position.x = 10.5


func set_state(new_state):
  state = new_state
  cannon.visible = (state not in [State.SHIELD, State.UNBOARDED])
  match state:
    State.WALK:
      shield_collision_shape.disabled = true
      cannon.show()
      body_animated_sprite.play("idle_on")
    State.JUMP:
      velocity.y = jump_speed
      body_animated_sprite.play("jump")
    State.FALL:
      body_animated_sprite.play("fall")
    State.FLY:
      body_animated_sprite.play("fly")
    State.LAND:
      body_animated_sprite.play("land")
    State.SHIELD:
      shield_collision_shape.disabled = false
      cannon.hide()
      body_animated_sprite.play("shield_start")
    # State.SWORD:
    #   body_animated_sprite.play("sword")
    State.UNBOARDED:
      if pilot != null:
        pilot.eject()
        pilot = null
      power_state = PowerState.STOPPING
      body_animated_sprite.play("power_off")
