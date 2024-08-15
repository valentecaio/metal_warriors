extends StaticBody2D

@export var speed = 350
@export var fire_frequency = 8 # shots per second

# to be defined on instantiation
var direction = Vector2(1,0)

func _process(delta):
  position = position + speed * direction * delta
