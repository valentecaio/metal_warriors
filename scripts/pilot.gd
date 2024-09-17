class_name Pilot extends "res://scripts/abstract/playable.gd"
func custom_class_name(): return "Pilot"


@onready var animation_player = $AnimationPlayer
@onready var area_2d = $Area2D

# properties defined in the editor
@export var aim_speed := 150
@export var max_walk_speed := 100
@export var max_fly_speed := 200
@export var jump_speed := -350
# @export var acceleration := 2.0
# @export var friction := 2000

# main state machine
enum State {
  WALK,  # default state: walking on the ground
  FLY,   # flying with jetpack
  ROBOT, # piloting a robot
}
var state := State.WALK

# robot pilotting state machine
enum RobotState {BOARDING, DRIVE, EJECTING}
var robot_state := RobotState.BOARDING

# bullets
const bullet_scene = preload("res://scenes/bullets/fusion_rifle.tscn")
var time_to_next_shot := 0.0

# state variables
var robot = null
var shooting:= false

# constants
var dict_animation_by_angle = {
  "-90": "shoot_1",
  "-45": "shoot_2",
    "0": "shoot_3",
   "45": "shoot_4",
   "90": "shoot_5",
}


### GAME LOOP ###

func _physics_process(delta):
  var dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()

  match state:
    State.WALK:
      process_walk(delta, dir)
    State.FLY:
      process_fly(delta, dir)
    State.ROBOT:
      process_robot(delta, dir)

  # cannon aiming is always enabled
  process_aim(delta, dir)

  move_and_slide()


func process_walk(delta, dir):
  # print("process_walk()")
  move_with_inertia(delta, dir, max_walk_speed)
  apply_gravity(delta)

  process_shoot(delta)

  # walk animation
  if !shooting:
    if dir.x:
      body_animated_sprite.play("walk")
    else:
      body_animated_sprite.pause()

  # check jump button
  if Input.is_action_pressed("button_south"):
    return set_state(State.FLY)

  # check if there is a robot touching the player and board it
  if Input.is_action_just_pressed("button_select"):
    for area in area_2d.get_overlapping_areas():
      robot = area.get_parent()
      return set_state(State.ROBOT)


func process_fly(delta, dir):
  # print("process_fly()")
  move_with_inertia(delta, dir, max_fly_speed)
  apply_gravity(delta)

  process_shoot(delta)
  if !shooting:
    body_animated_sprite.play("fly")

  # state is locked while button is pressed
  if Input.is_action_pressed("button_south"):
    velocity -= get_gravity() * delta # no gravity when flying
    velocity.y = eval_velocity(velocity.y, -1, delta, max_fly_speed)
  else:
    set_state(State.WALK)


func process_robot(_delta, _dir):
  if robot != null:
    # follow robot's position
    global_position = robot.global_position# + Vector2(0, 10)

  match robot_state:
    RobotState.BOARDING:
      # wait until board animation finishes, then start driving
      if !animation_player.is_playing():
        robot_state = RobotState.DRIVE
        robot.drive(self)
    RobotState.DRIVE:
      # wait until robot script triggers eject()
      pass
    RobotState.EJECTING:
      # wait until eject animation finishes, then go to walk state
      if !animation_player.is_playing():
        robot = null
        body_collision_shape.disabled = false
        return set_state(State.WALK)


func process_shoot(delta):
  # update time to next shot
  time_to_next_shot -= delta
  if time_to_next_shot > 0:
    return

  # check shoot button
  shooting = Input.is_action_pressed("button_west")
  if shooting:
    body_animated_sprite.play(dict_animation_by_angle[str(cannon_angle)])
    var bullet = bullet_scene.instantiate()
    var angle = eval_cannon_angle()
    bullet.direction = Vector2(-1 if flipped else 1, 0).rotated(angle).normalized()
    bullet.position = global_position + Vector2(-23 if flipped else 23, -3).rotated(angle)
    get_parent().add_child(bullet)
    time_to_next_shot = 1.0/bullet.fire_frequency


func process_aim(delta, dir):
  if dir == Vector2.ZERO:
    return

  # update cannon angle according to input
  if dir.x and dir.y:
    cannon_angle = 45 if dir.y > 0 else -45
  elif dir.y:
    cannon_angle = 90 if dir.y > 0 else -90
  elif dir.x:
    cannon_angle = 0


func set_state(new_state):
  state = new_state
  match state:
    State.WALK:
      body_animated_sprite.play("idle")
    State.FLY:
      body_animated_sprite.play("fly")
    State.ROBOT:
      body_collision_shape.disabled = true
      robot_state = RobotState.BOARDING
      animation_player.play("board")



### CALLBACKS ###

# called by robot script after ejecting pilot
func eject():
  robot_state = RobotState.EJECTING
  animation_player.play("eject")
