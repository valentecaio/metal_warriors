extends StaticBody2D

@export var speed = 400
@export var fire_frequency = 8 # shots per second

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

# to be defined on instantiation
var direction = Vector2(1,0)

func _ready():
  # add error to bullet direction (random error between -10 and 10 degrees)
  var rand_angle = deg_to_rad(randf_range(-10, 10))
  direction = direction.rotated(rand_angle)

func _process(delta):
  position = position + speed * direction * delta
