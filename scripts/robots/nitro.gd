class_name Nitro extends "res://scripts/abstract/robot.gd"
func custom_class_name(): return "Nitro"


@onready var shield_collision_shape = $ShieldCollisionShape2D
@onready var cannon = $Cannon
@onready var cannon_animated_sprite = $Cannon/CannonAnimatedSprite2D

# properties defined in the editor
@export var aim_speed := 150
@export var max_walk_speed := 200
@export var max_fly_speed := 300
@export var jump_speed := -350
# @export var acceleration := 2.0
# @export var friction := 2000

# main state machine
enum State {
  WALK,      # default state: walking on the ground
  UNBOARDED, # waiting for pilot to board
  JUMP,      # jumping animation after pressing jump button
  FLY,       # flying in the air while holding jump button
  FALL,      # falling
  LAND,      # landing animation after hitting the ground
  SHIELD,    # shielding while holding shield button
  SWORD,     # sword attack
}

# bullets
const bullet_scene = preload("res://scenes/bullets/fusion_rifle.tscn")
var time_to_next_shot := 0.0

# state variables
var cannon_animation := "idle"
var shooting := false



### OVERRIDDEN FROM ROBOT ###

# show/hide cannon
func cannon_visible(visible):
  cannon.visible = visible


# flip body and cannon horizontally when facing left
func flip_sprites(flip):
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



### GAME LOOP ###

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
  if Input.is_action_pressed("button_south"):
    return set_state(State.JUMP)

  # check shield button
  if Input.is_action_pressed("shoulder_right"):
    return set_state(State.SHIELD)

  # check eject button
  if Input.is_action_pressed("button_select"):
    eject_pilot()
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
  move_with_inertia(delta, Vector2.ZERO, max_walk_speed)
  apply_gravity(delta)

  if dir.x:
    flip_sprites(dir.x < 0)

  # flip shield collision shape when facing left
  shield_collision_shape.position.x = -15 if flipped else 15

  # check shield button
  if not Input.is_action_pressed("shoulder_right"):
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


func set_state(new_state):
  state = new_state
  cannon_visible(state not in [State.SHIELD, State.UNBOARDED])
  match state:
    State.WALK:
      shield_collision_shape.disabled = true
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
      body_animated_sprite.play("shield_start")
    # State.SWORD:
    #   body_animated_sprite.play("sword")
    State.UNBOARDED:
      power_state = PowerState.STOPPING
