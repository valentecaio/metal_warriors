extends StaticBody2D

@onready var animated_sprite = $AnimatedSprite2D

# properties defined in the editor
@export var type: Global.BlockType = Global.BlockType.Red
@export var hp: int = 75


func _ready():
  animated_sprite.pause()
  match type:
    Global.BlockType.BrownGray:
      animated_sprite.animation = "brown_gray"
    Global.BlockType.BrownGreen:
      animated_sprite.animation = "brown_green"
    Global.BlockType.Green:
      animated_sprite.animation = "green"
    Global.BlockType.Ice:
      animated_sprite.animation = "ice"
    Global.BlockType.Orange:
      animated_sprite.animation = "orange"
    Global.BlockType.Red:
      animated_sprite.animation = "red"
    Global.BlockType.SpaceStationLeft:
      animated_sprite.animation = "space_station_left"
    Global.BlockType.SpaceStationMiddle:
      animated_sprite.animation = "space_station_middle"
    Global.BlockType.SpaceStationRight:
      animated_sprite.animation = "space_station_right"
    


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
