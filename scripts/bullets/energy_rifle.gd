extends Area2D

@export var speed = 400
@export var fire_frequency = 8 # shots per second

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

# to be defined on instantiation
var direction = Vector2(1,0)


func _ready():
  # connect signals
  self.body_entered.connect(_on_body_entered)
  animated_sprite.animation_finished.connect(_on_animation_finished)


func _process(delta):
  position = position + speed * direction * delta


# collision detection
func _on_body_entered(_body):
  speed = 0
  animated_sprite.play("hit")


func _on_animation_finished():
  queue_free()
