# The base class for all robots in the game.

class_name Robot extends "res://scripts/abstract/playable.gd"
func custom_class_name(): return "Robot"


# state machine for start/stop animations: STOPPING -> OFF -> STARTING
enum PowerState {STOPPING, OFF, STARTING}
var power_state := PowerState.OFF

# state variables
var pilot = null



# all robots have UNBOARDED state
func process_unboarded(delta, _dir):
  move_with_inertia(delta, Vector2.ZERO, 500)
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
      # wait until "power_on" animation finishes, then go to default state
      if not body_animated_sprite.is_playing():
        default_state()



### CALLBACKS ###

# called by pilot script after boarding robot
func drive(new_pilot):
  print(custom_class_name() + " boarded")
  if (pilot != null) or (power_state != PowerState.OFF):
    return # robot already occupied

  # start robot
  pilot = new_pilot
  power_state = PowerState.STARTING
  body_animated_sprite.play("power_on")



### HELPERS ###

# unbord pilot from robot
func eject_pilot():
  if pilot != null:
    pilot.eject()
    pilot = null
  body_animated_sprite.play("power_off")
