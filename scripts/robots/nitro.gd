class_name Nitro extends "res://scripts/abstract/robot.gd"
func custom_class_name(): return "Nitro"


@onready var shield_collision_shape = $ShieldCollisionShape2D
@onready var cannon = $Cannon
@onready var cannon_animated_sprite = $Cannon/CannonAnimatedSprite2D

# properties defined in the editor
@export var aim_speed := 150
@export var max_walk_speed := 200
@export var max_fly_speed := 300
@export var jump_speed := 350           ## controls the height of jump
@export var land_threshold_speed := 350 ## speed to trigger landing animation
# @export var acceleration := 2.0
# @export var friction := 2000

# main state machine
enum State {
  WALK,      # default state: walking on the ground
  UNBOARDED, # waiting for pilot to board
  DEAD,      # exploding
  JUMP,      # jumping animation after pressing jump button
  FLY,       # flying in the air while holding jump button
  FALL,      # falling
  LAND,      # landing animation after hitting the ground
  SHIELD,    # shielding while holding shield button
  SWORD,     # sword attack
}

# scenes
const bullet_scene = preload("res://scenes/bullets/fusion_rifle.tscn")
const remote_shield_scene = preload("res://scenes/stage/remote_shield.tscn")

# state variables
var cannon_animation := "idle"
var shooting := false
var time_to_next_shot := 0.0 # time until next bullet can be shot
var last_y_velocity := 0.0   # last y velocity before colliding with floor
var remote_shield = null     # pointer to dropped remote shield



### GAME LOOP ###

func _physics_process(delta):
  var dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()

  match state:
    State.WALK:
      process_walk(delta, dir)
    State.UNBOARDED:
      process_unboarded(delta, dir)
    State.DEAD:
      apply_gravity(delta)
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

  # cannon aiming is always enabled
  process_aim(delta, dir)

  # cannon animation is set only once per loop
  cannon_animated_sprite.play("shoot" if shooting else cannon_animation)

  last_y_velocity = velocity.y
  move_and_slide()


func process_walk(delta, dir):
  # print("process_walk()")
  move_with_inertia(delta, dir, max_walk_speed)
  apply_gravity(delta)
  process_shoot(delta)
  process_shield_drop()

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
  process_shield_drop()

  # check if should go to fall of fly state
  if not body_animated_sprite.is_playing():
    if Input.is_action_pressed("button_south"):
      return set_state(State.FLY)
    else:
      return set_state(State.FALL)


func process_fall(delta, dir):
  # print("process_fall()")
  move_with_inertia(delta, dir, max_walk_speed)
  apply_gravity(delta)
  process_shoot(delta)
  process_shield_drop()

  # check fly button
  if Input.is_action_pressed("button_south"):
    return set_state(State.FLY)

  # check landing
  if is_on_floor():
    # only trigger landing animation if falling from a considerable height
    if last_y_velocity >= jump_speed:
      return set_state(State.LAND)
    else:
      return set_state(State.WALK)


func process_fly(delta, dir):
  # print("process_fly()")
  move_with_inertia(delta, dir, max_fly_speed)
  apply_gravity(delta)
  process_shoot(delta)
  process_shield_drop()

  # state is locked while button is pressed
  if Input.is_action_pressed("button_south"):
    velocity -= get_gravity() * delta # no gravity when flying
    velocity.y = eval_velocity(velocity.y, -1, delta, max_fly_speed)
  else:
    # check falling
    if velocity.y >= 0:
      return set_state(State.FALL)


func process_land(delta, dir):
  # print("process_land()")
  move_with_inertia(delta, dir, max_fly_speed)
  apply_gravity(delta)
  process_shoot(delta)
  process_shield_drop()

  # go back to walk state after "land" animation ends
  if not body_animated_sprite.is_playing():
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


func process_shield_drop():
  # check drop shield button
  if Input.is_action_just_pressed("button_north"):
    # destroy existing shield
    if remote_shield != null:
      remote_shield.queue_free()
      remote_shield = null
    # drop new shield
    remote_shield = remote_shield_scene.instantiate()
    remote_shield.position = global_position
    get_parent().add_child(remote_shield)


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



### OVERRIDDEN FROM ROBOT / PLAYABLE ###

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


func update_sprite_material():
  super()
  cannon_animated_sprite.material = body_material


func set_state(new_state):
  state = new_state
  cannon.visible = state not in [State.SHIELD, State.UNBOARDED, State.DEAD]
  match state:
    State.WALK:
      shield_collision_shape.disabled = true
      body_animated_sprite.play("idle_on")
    State.JUMP:
      velocity.y = -jump_speed
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
    State.SWORD:
      # body_animated_sprite.play("sword")
      pass
