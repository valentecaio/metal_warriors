class_name Drache extends "res://scripts/abstract/robot.gd"
func custom_class_name(): return "Drache"


@onready var shot_animated_sprite = $ShotAnimatedSprite2D
@onready var shield_collision_shape = $ShieldCollisionShape2D

# properties defined in the editor
@export var max_fly_speed := 250
# @export var acceleration := 3.0
# @export var friction := 600

# main state machine
@export var state := State.FLY
enum State {FLY, SHIELD, UNBOARDED}

# bullets
const bullet_scene = preload("res://scenes/bullets/energy_cannon.tscn")
var time_to_next_shot := 0.0



### OVERRIDDEN FROM ROBOT ###

func default_state():
  set_state(State.FLY)



### GAME LOOP ###

func _ready():
  print(custom_class_name() + " ready")

  if state == State.UNBOARDED:
    body_animated_sprite.play("idle_off")
  else:
    body_animated_sprite.play("idle_on")


func _physics_process(delta):
  var dir = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()

  match state:
    State.FLY:
      process_fly(delta, dir)
    State.SHIELD:
      process_shield(delta, dir)
    State.UNBOARDED:
      process_unboarded(delta, dir)

  move_and_slide()


func process_fly(delta, dir):
  process_shoot(delta)

  # movement
  velocity.x = eval_velocity(velocity.x, dir.x, delta, max_fly_speed)
  velocity.y = eval_velocity(velocity.y, dir.y, delta, max_fly_speed)

  # animation
  if dir.x:
    body_animated_sprite.play("move_right")
    flip_sprites(dir.x < 0)
  elif dir.y > 0:
    body_animated_sprite.play("move_up")
  elif dir.y < 0:
    body_animated_sprite.play("move_down")
  else:
    body_animated_sprite.play("idle_on")

  # check shield button
  if Input.is_action_just_pressed("shoulder_right"):
    return set_state(State.SHIELD)

  # check eject button
  if Input.is_action_just_pressed("button_select"):
    return set_state(State.UNBOARDED)


func process_shield(delta, _dir):
  if Input.is_action_pressed("shoulder_right"):
    velocity.x = eval_velocity(velocity.x, 0, delta, max_fly_speed)
    velocity.y = eval_velocity(velocity.y, 1, delta, 2*max_fly_speed)
  else:
    set_state(State.FLY)


func process_unboarded(delta, _dir):
  velocity.x = eval_velocity(velocity.x, 0, delta, max_fly_speed)
  apply_gravity(delta)

  print(power_state)
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
      # wait until "power_on" animation finishes, then go to FLY state
      if not body_animated_sprite.is_playing():
        return set_state(State.FLY)


func process_shoot(delta):
  time_to_next_shot -= delta

  # the order of elifs matters
  var angle = null
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

  shot_animated_sprite.visible = angle != null

  # shoot
  if shot_animated_sprite.visible and time_to_next_shot < 0:
    var direction = Vector2.RIGHT.rotated(deg_to_rad(angle))
    shot_animated_sprite.position = 5*direction
    shot_animated_sprite.rotation = deg_to_rad(angle)

    var bullet = bullet_scene.instantiate()
    bullet.direction = direction
    bullet.position = global_position + Vector2(0, 3)
    get_parent().add_child(bullet)

    time_to_next_shot = 1.0/bullet.fire_frequency


func set_state(new_state):
  state = new_state
  body_collision_shape.disabled   = (state == State.SHIELD)
  shield_collision_shape.disabled = (state != State.SHIELD)
  match state:
    State.SHIELD:
      body_animated_sprite.play("power_dive")
    State.UNBOARDED:
      if pilot != null:
        pilot.eject()
        pilot = null
      power_state = PowerState.STOPPING
      body_animated_sprite.play("power_off")
