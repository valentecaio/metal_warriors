extends Area2D

@export var speed = 400
@export var fire_frequency = 8 # shots per second

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

# to be defined on instantiation
var direction = Vector2(1,0)

func _ready():
  # add random error to bullet direction (between -10 and 10 degrees)
  direction = direction.rotated(deg_to_rad(randf_range(-10, 10)))


func _process(delta):
  position = position + speed * direction * delta


# collision detection
func _on_body_entered(body):
  speed = 0
  animated_sprite.play("hit")


func _on_animated_sprite_2d_animation_finished():
  queue_free()
