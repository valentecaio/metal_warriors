extends Area2D

# custom properties per bullet type
@export var speed = 400
@export var fire_frequency = 8  # shots per second
@export var error := false      # add error to bullet direction
@export var fragments := false  # spawn fragments on hit
@export var rotate := false     # rotate bullet sprite to match direction

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

# to be defined on instantiation
var direction := Vector2(1,0)


func _ready():
  # connect signals
  self.body_entered.connect(_on_body_entered)
  animated_sprite.animation_finished.connect(_on_animation_finished)

  # add random error to bullet direction (between -10 and 10 degrees)
  if error:
    direction = direction.rotated(deg_to_rad(randf_range(-10, 10)))

  # rotate sprite to match direction
  if rotate:
    animated_sprite.rotation_degrees = rad_to_deg(direction.angle())


func _process(delta):
  position = position + speed * direction * delta


# collision detection
func _on_body_entered(_body):
  # print("BULLET _on_body_entered() ", _body)
  explode()


func _on_animation_finished():
  # print("BULLET _on_animation_finished()")
  queue_free()


func explode():
  if collision_shape.disabled:
    return # already exploded

  # stop bullet, disable collision and play hit animation
  speed = 0
  collision_shape.disabled = true
  animated_sprite.play("hit")

  # spawn fragments in 8 directions
  if fragments:
    var frag_scene = load("res://scenes/bullets/fragment.tscn")
    for angle in [0, 45, 90, 135, 180, 225, 270, 315]:
      var frag = frag_scene.instantiate()
      frag.direction = Vector2(1, 0).rotated(deg_to_rad(angle))
      frag.position = global_position + frag.direction * 7
      get_parent().add_child(frag)
    # var frag = frag_scene.instantiate()
    # frag.direction = Vector2(-1, 0)
    # frag.position = global_position + Vector2(-10, 0)
    # get_parent().add_child(frag)
