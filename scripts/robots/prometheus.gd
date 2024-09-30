class_name Prometheus extends "res://scripts/abstract/robot.gd"
func custom_class_name(): return "Prometheus"


@onready var cannon = $Cannon
@onready var cannon_animated_sprite = $Cannon/CannonAnimatedSprite2D
@onready var boarding_area = $BoardingArea
@onready var block_building_area = $BlockBuildingArea
@onready var fire_area = $FireArea


# properties defined in the editor
@export var aim_speed := 150
@export var max_walk_speed := 80
@export var fire_damage := 100
@export var fire_damage_frequency := 2 # hits per second
# @export var acceleration := 2.0
# @export var friction := 4000

# main state machine
enum State {
  WALK,         # default state: walking on the ground
  UNBOARDED,    # waiting for pilot to board
  DEAD,         # exploding
  FALL,         # falling
  SHIELD,       # shielding while holding shield button
  FLAMETHROWER, # flamethrower animations
  BLOCKBUILD,   # block building animation
}

# scenes
const bullet_scene = preload("res://scenes/bullets/mega_cannon.tscn")
const mine_scene = preload("res://scenes/bullets/aerial_mine.tscn")
const block_scene = preload("res://scenes/stage/block.tscn")

# state variables
var bullet = null             # pointer to current bullet instance
var shooting := false         # shooting flag
var time_to_next_shot := 0.0  # time until next shot
var time_to_next_mine := 0.0  # time until next aerial mine
var time_to_next_fire_damage := 0.0 # time until next fire damage




### GAME LOOP ###

func _physics_process(delta):
  var dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()

  match state:
    State.WALK:
      process_walk(delta, dir)
    State.UNBOARDED:
      process_unboarded(delta, dir)
    State.DEAD:
      pass
    State.FALL:
      process_fall(delta, dir)
    State.FLAMETHROWER:
      process_flamethrower(delta, dir)
    State.SHIELD:
      process_shield(delta, dir)
    State.BLOCKBUILD:
      process_block_build(delta, dir)

  # cannon aiming and shoot ending are enabled in all states
  process_aim(delta, dir)
  process_shoot_end()

  move_and_slide()


func process_walk(delta, dir):
  # print("process_walk()")
  move_with_inertia(delta, dir, max_walk_speed)
  apply_gravity(delta)

  process_shoot_start(delta)
  process_aerial_mine(delta)

  # update body animation
  var animation
  var cur_angle = cannon.rotation if flipped else -cannon.rotation
  if cur_angle < deg_to_rad(22.5):
    animation = "walk_1"
  elif cur_angle < deg_to_rad(67.5):
    animation = "walk_2"
  else:
    animation = "walk_3"
  if body_animated_sprite.animation != animation:
    body_animated_sprite.animation = animation

  # play animation when walking
  if dir.x:
    body_animated_sprite.play()
    if !shooting:
      cannon_animated_sprite.play("walk")
  else:
    body_animated_sprite.pause()
    if !shooting:
      cannon_animated_sprite.play("idle")

  # check if falling
  if not is_on_floor():
    return set_state(State.FALL)

  # check flame thrower button
  if Input.is_action_pressed("button_east"):
    return set_state(State.FLAMETHROWER)

  # check block building button
  if Input.is_action_pressed("button_south") and can_build_block():
    return set_state(State.BLOCKBUILD)

  # check shield button
  if Input.is_action_pressed("shoulder_right"):
    return set_state(State.SHIELD)

  # check eject button
  if Input.is_action_pressed("button_select"):
    eject_pilot()
    return set_state(State.UNBOARDED)


func process_fall(delta, dir):
  # print("process_fall()")
  move_with_inertia(delta, dir, max_walk_speed)
  apply_gravity(delta)

  process_shoot_start(delta)
  process_aerial_mine(delta)

  # check landing
  if is_on_floor():
    return set_state(State.WALK)


func process_flamethrower(delta, dir):
  # print("process_flamethrower()")
  move_with_inertia(delta, Vector2.ZERO, max_walk_speed)
  apply_gravity(delta)

  if dir.x:
    flip_sprites(dir.x < 0)

  # deal damage to enemies in fire area
  time_to_next_fire_damage -= delta
  if time_to_next_fire_damage <= 0:
    time_to_next_fire_damage = 1.0/fire_damage_frequency
    for body in fire_area.get_overlapping_bodies():
      if body.has_method("burn"):
        body.burn(fire_damage)
      elif body.has_method("hit"):
        body.hit(fire_damage)

  # stop flamethrower when button is released
  if body_animated_sprite.animation == 'fire_loop' and !Input.is_action_pressed("button_east"):
    body_animated_sprite.play("fire_end")
    await body_animated_sprite.animation_finished
    return set_state(State.WALK)


func process_shield(delta, dir):
  # print("process_shield()")
  move_with_inertia(delta, Vector2.ZERO, max_walk_speed)
  apply_gravity(delta)

  if dir.x:
    flip_sprites(dir.x < 0)

  # check shield button
  if not Input.is_action_pressed("shoulder_right"):
    return set_state(State.WALK)


func process_block_build(delta, _dir):
  # print("process_block_build()")
  move_with_inertia(delta, Vector2.ZERO, max_walk_speed)
  apply_gravity(delta)

  # wait until block_build finishes, then return to walk state
  if not body_animated_sprite.is_playing():
    # create block
    var block = block_scene.instantiate()
    block.position = block_building_area.global_position
    block.type = Global.BlockType.BrownGreen
    get_parent().add_child(block)
    # clip block to multiple of 16 (with 8 offset)
    block.position.x = 8 + int(block.position.x/16) * 16
    block.position.y = 8 + int(block.position.y/16) * 16
    # return to walk state
    return set_state(State.WALK)


func process_shoot_start(delta):
  # update time to next shot
  time_to_next_shot -= delta

  if (time_to_next_shot <= 0) and !shooting and Input.is_action_pressed("button_west"):
    # button pressed, create and shoot bullet
    shooting = true
    # create bullet
    var angle = eval_cannon_angle()
    bullet = bullet_scene.instantiate()
    bullet.direction = Vector2(-1 if flipped else 1, 0).rotated(angle).normalized()
    bullet.position = global_position + Vector2(-32 if flipped else 32, -18).rotated(angle)
    get_parent().add_child(bullet)
    # block shooting for some time and play shoot animation
    time_to_next_shot = 1.0/bullet.fire_frequency
    cannon_animated_sprite.play("shoot")


func process_shoot_end():
  if bullet == null:
    # bullet already exploded
    shooting = false
  if shooting and !Input.is_action_pressed("button_west"):
    # button released, explode bullet
    shooting = false
    if (bullet != null):
      bullet.explode()
      bullet = null


func process_aerial_mine(delta):
  time_to_next_mine -= delta
  if time_to_next_mine > 0:
    return

  # if north button is pressed, create and drop an aerial mine
  if Input.is_action_pressed("button_north"):
    var mine = mine_scene.instantiate()
    mine.direction = Vector2(0, -1)
    mine.position = global_position + Vector2(0, -25)
    get_parent().add_child(mine)
    time_to_next_mine = 1.0/mine.fire_frequency


func process_aim(delta, dir):
  if dir == Vector2.ZERO:
    return

  # update cannon angle according to input
  var pressed_angle := 0.0
  if dir.x and dir.y: # diagonal
    pressed_angle = -45.0 if dir.y < 0 else 45.0
  elif dir.y: # up (-90) or down (77.5)
    pressed_angle = -90.0 if dir.y < 0 else 77.5
  elif dir.x: # left or right
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
    cannon.position.x = 5
    cannon_animated_sprite.position.x = -12
    block_building_area.position.x = -24
    fire_area.position.x = -39
  else:
    cannon.position.x = -5
    cannon_animated_sprite.position.x = 12
    block_building_area.position.x = 24
    fire_area.position.x = 39


func set_state(new_state):
  state = new_state
  cannon.visible = state in [State.WALK, State.FALL]
  match state:
    State.FALL:
      body_animated_sprite.play("fall")
    State.FLAMETHROWER:
      start_flamethrower()
    State.SHIELD:
      body_animated_sprite.play("shield")
    State.BLOCKBUILD:
      body_animated_sprite.play("block_build")



### HELPERS ###

# play flamethrower animations
func start_flamethrower():
  body_animated_sprite.play("fire_start")
  await body_animated_sprite.animation_finished
  body_animated_sprite.play("fire_loop")

# check if robot is in a valid position to build a block
func can_build_block():
  return not (block_building_area.has_overlapping_bodies() or block_building_area.has_overlapping_areas())
