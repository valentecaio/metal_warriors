extends StaticBody2D

@onready var animated_sprite = $AnimatedSprite2D


# properties defined in the editor
@export var type: Global.BlockType = Global.BlockType.Red
@export var hp: int = 100


func _ready():
  match type:
    Global.BlockType.BrownGray:
      animated_sprite.play("brown_gray")
    Global.BlockType.BrownGreen:
      animated_sprite.play("brown_green")
    Global.BlockType.Green:
      animated_sprite.play("green")
    Global.BlockType.Ice:
      animated_sprite.play("ice")
    Global.BlockType.Orange:
      animated_sprite.play("orange")
    Global.BlockType.Red:
      animated_sprite.play("red")
    Global.BlockType.SpaceStationLeft:
      animated_sprite.play("space_station_left")
    Global.BlockType.SpaceStationMiddle:
      animated_sprite.play("space_station_middle")
    Global.BlockType.SpaceStationRight:
      animated_sprite.play("space_station_right")
    


### callbacks ###

# called when a bullet hits this block
func bullet_hit(bullet):
  hp -= bullet.damage
  if hp <= 0:
    queue_free()
