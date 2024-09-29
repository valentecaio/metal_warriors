extends StaticBody2D

@onready var animated_sprite = $AnimatedSprite2D

# properties defined in the editor
@export var type := Global.BlockType.Red
@export var hp := 75


func _ready():
  animated_sprite.pause()
  animated_sprite.animation = Global.block_type_names[type]
    


### CALLBACKS ###

# called when a bullet hits this block
func bullet_hit(bullet):
  hp -= bullet.damage
  animated_sprite.frame = eval_frame()
  if hp <= 0:
    # disable collisions
    collision_layer = 0



### HELPERS ###

func eval_frame():
  if   hp > 50: return 0
  elif hp > 25: return 1
  elif hp > 0:  return 2
  else:         return 3
