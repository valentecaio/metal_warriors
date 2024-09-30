extends StaticBody2D

@onready var animated_sprite = $AnimatedSprite2D

# properties defined in the editor
@export var type := Global.BlockType.Red
@export var hp := 75


func _ready():
  animated_sprite.pause()
  animated_sprite.animation = Global.block_type_names[type]
    


### CALLBACKS ###

func hit(damage):
  hp -= damage
  animated_sprite.frame = eval_frame()
  # disable collisions when destroyed, stay on last frame
  if hp <= 0:
    collision_layer = 0



### HELPERS ###

func eval_frame():
  if   hp > 50: return 0
  elif hp > 25: return 1
  elif hp > 0:  return 2
  else:         return 3
