extends CharacterBody2D

@onready var body_animated_sprite = $BodyAnimatedSprite2D
@onready var cannon = $Cannon
@onready var cannon_animated_sprite = $Cannon/CannonAnimatedSprite2D

# properties defined in the editor
@export var aim_speed := 150
@export var max_walk_speed := 80
@export var acceleration := 2.0
@export var friction := 4000

# main state machine
enum State {WALK, FALL, FLAMETHROWER, BLOCKBUILD, SHIELD}
var state := State.WALK

# state machine for fire animation: START -> LOOP -> END
enum FireState {START, LOOP, END}
var fire_state := FireState.START

# bullets
const bullet_scene = preload("res://scenes/bullets/mega_cannon.tscn")
var time_to_next_shot := 0.0
var bullet = null

# air mines
const mine_scene = preload("res://scenes/bullets/aerial_mine.tscn")
var time_to_next_mine := 0.0

# state variables
var cannon_angle := 0.0
var flipped := false
var shooting := false



### GAME LOOP ###

func _ready():
  print("Prometheus ready")


func _physics_process(delta):
  var dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()

  match state:
    State.WALK:
      process_walk(delta, dir)
    State.FALL:
      process_fall(delta, dir)
    State.FLAMETHROWER:
      process_flamethrower(delta, dir)
    State.SHIELD:
      process_shield(delta, dir)
    State.BLOCKBUILD:
      process_block_build(delta, dir)

  # cannon aiming is always enabled
  process_aim(delta, dir)

  move_and_slide()


func process_walk(delta, dir):
  # print("process_walk()")
  move_and_gravity(delta, dir, max_walk_speed)

  process_shoot(delta)
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

  # check falling
  if not is_on_floor():
    return set_state(State.FALL)

  # check flame thrower
  if Input.is_action_just_pressed("button_east"):
    return set_state(State.FLAMETHROWER)

  # check block building
  if Input.is_action_just_pressed("button_south"):
    return set_state(State.BLOCKBUILD)

  # check shield
  if Input.is_action_just_pressed("shoulder_right"):
    return set_state(State.SHIELD)


func process_fall(delta, dir):
  # print("process_fall()")
  move_and_gravity(delta, dir, max_walk_speed)

  process_shoot(delta)
  process_aerial_mine(delta)

  # check landing
  if is_on_floor():
    return set_state(State.WALK)


func process_flamethrower(delta, dir):
  # print("process_flamethrower()")
  velocity.x = move_toward(velocity.x, 0.5, friction * delta)

  if dir.x:
    flip_body_and_cannon(dir.x < 0)

  match fire_state:
    FireState.START:
      # wait until fire_start finishes, then start fire_loop
      if not body_animated_sprite.is_playing():
        fire_state = FireState.LOOP
        body_animated_sprite.play("fire_loop")
    FireState.LOOP:
      # loop animation until button is released, then start fire_end
      if not Input.is_action_pressed("button_east"):
        fire_state = FireState.END
        body_animated_sprite.play("fire_end")
    FireState.END:
      # wait until fire_end finishes, then return to walk state
      if not body_animated_sprite.is_playing():
        return set_state(State.WALK)


func process_shield(delta, dir):
  # print("process_shield()")
  velocity.x = move_toward(velocity.x, 0.5, friction * delta)

  if dir.x:
    flip_body_and_cannon(dir.x < 0)

  # check shield button
  if not Input.is_action_pressed("shoulder_right"):
    return set_state(State.WALK)


func process_block_build(delta, dir):
  # print("process_block_build()")
  velocity.x = 0

  # wait until block_build finishes, then return to walk state
  if not body_animated_sprite.is_playing():
    # TODO: create block
    return set_state(State.WALK)


func process_shoot(delta):
  # update time to next shot
  time_to_next_shot -= delta

  if (time_to_next_shot <= 0) and Input.is_action_just_pressed("button_west"):
    # button pressed, create and shoot bullet
    shooting = true
    var angle = eval_cannon_angle()
    bullet = bullet_scene.instantiate()
    bullet.direction = Vector2(-1 if flipped else 1, 0).rotated(angle).normalized()
    bullet.position = global_position + Vector2(-32 if flipped else 32, -18).rotated(angle)
    get_parent().add_child(bullet)
    time_to_next_shot = 1.0/bullet.fire_frequency
    cannon_animated_sprite.play("shoot")
  elif (bullet != null) and !Input.is_action_pressed("button_west"):
    # button released, explode bullet
    shooting = false
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
    pressed_angle = -45 if dir.y < 0 else 45
  elif dir.y: # up (-90) or down (77.5)
    pressed_angle = -90 if dir.y < 0 else 77.5
  elif dir.x: # left or right
    pressed_angle = 0
  cannon_angle = move_toward(cannon_angle, pressed_angle, aim_speed * delta)

  # rotate cannon sprite
  cannon.rotation = eval_cannon_angle()



### CALLBACKS ###

# TODO
func _on_animation_finished(anim_name: String):
  print("_on_animation_finished() ", anim_name)



### HELPERS ###

# evaluate velocity with inertia
func eval_velocity(initial_velocity, input, delta, max_speed):
  if input:
    var vel = initial_velocity + (input * max_speed * delta * acceleration)
    return clamp(vel, -max_speed, max_speed)
  else:
    return move_toward(initial_velocity, 0, friction * delta)


# evaluate horizontal velocity and flip sprites if necessary
func move_and_gravity(delta, dir, max_speed):
  if dir.x:
    flip_body_and_cannon(dir.x < 0)
  velocity.x = eval_velocity(velocity.x, dir.x, delta, max_speed)
  velocity += get_gravity() * delta


# return cannon angle in radians, rounded to a multiple of 22.5 degrees
# and flipped when facing left
func eval_cannon_angle():
  var angle = -cannon_angle if flipped else cannon_angle
  return deg_to_rad(round(angle / 22.5) * 22.5)


# flip body and cannon horizontally when facing left
func flip_body_and_cannon(flip):
  # save flipped state
  flipped = flip

  # flip sprites
  body_animated_sprite.flip_h = flip
  cannon_animated_sprite.flip_h = flip

  # flip positions
  if flip:
    cannon.position.x = 5
    cannon_animated_sprite.position.x = -12
  else:
    cannon.position.x = -5
    cannon_animated_sprite.position.x = 12


func set_state(new_state):
  state = new_state
  match state:
    State.WALK:
      cannon.show()
    State.FALL:
      body_animated_sprite.play("fall")
    State.FLAMETHROWER:
      cannon.hide()
      fire_state = FireState.START
      body_animated_sprite.play("fire_start")
    State.SHIELD:
      cannon.hide()
      body_animated_sprite.play("shield")
    State.BLOCKBUILD:
      cannon.hide()
      body_animated_sprite.play("block_build")
