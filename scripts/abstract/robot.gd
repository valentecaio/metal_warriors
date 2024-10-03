# The base class for all robots in the game.

class_name Robot extends "res://scripts/abstract/playable.gd"
func custom_class_name(): return "Robot"


# properties defined in the editor
@export var init_boarded := false  # start boarded, for debug
@export var max_hp := 1000

# state variables
var pilot = null
var state := 0
var hp := max_hp
var body_material = null
var damage_ratio = 0.0


### VIRTUALS ###

func set_state(_state): pass


### GAME LOOP ###

func _ready():
  super()
  if init_boarded:
    body_animated_sprite.play("idle_on")
    set_state(Global.RobotState.DEFAULT)
  else:
    body_animated_sprite.play("idle_off")
    set_state(Global.RobotState.UNBOARDED)


# all robots have UNBOARDED state
# wait until a pilot script triggers start()
func process_unboarded(delta, _dir):
  move_with_inertia(delta, Vector2.ZERO, 500)
  apply_gravity(delta)



### CALLBACKS ###

# called by pilot script BEFORE boarding robot
func board(new_pilot):
  if pilot != null:
    return # robot already occupied
  pilot = new_pilot
  update_sprite_material()
  print(custom_class_name(), " boarded by player ", pilot.id)


# called by pilot script AFTER boarding robot
func start():
  body_animated_sprite.play("power_on")
  await body_animated_sprite.animation_finished
  set_state(Global.RobotState.DEFAULT)


# called by bullet/power_dive on hit
func hit(damage):
  hp -= damage
  damage_ratio = 1 - float(hp)/max_hp
  # TODO:
  # < 0.7: blend sprite with damage colours -> DONE
  # > 0.7: add fire sprite
  # > 0.9: remove cannon
  update_sprite_material()
  if hp <= 0:
    explode()


# called by prometheus fire on hit
func burn(damage):
  hit(damage)
  print("burning")
  # TODO: burn animation



### HELPERS ###

func eject_pilot():
  if pilot != null:
    pilot.eject()
    pilot = null
  body_animated_sprite.play("power_off")
  await body_animated_sprite.animation_finished
  set_state(Global.RobotState.UNBOARDED)


# start explosion animation, go to dead state and delete robot
func explode():
  if state == Global.RobotState.DEAD:
    return # already exploding
  if state == Global.RobotState.UNBOARDED:
    body_animated_sprite.play("explode_off")
  else:
    body_animated_sprite.play("explode_on")
  set_state(Global.RobotState.DEAD)
  await body_animated_sprite.animation_finished
  queue_free()


func is_empty_robot():
  return (state == Global.RobotState.UNBOARDED) and (pilot == null)


# change robot colour palette
func update_sprite_material():
  if pilot == null:
    return
  body_material = load(Global.colour_materials[pilot.id-1])
  var shader_ratio = clamp(damage_ratio / 0.7, 0.0, 1.0)
  body_material.set("shader_param/damage_percent", shader_ratio);
  body_animated_sprite.material = body_material
