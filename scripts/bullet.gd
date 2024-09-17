extends Area2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

# bullet type needs to be defined in the editor
enum Type {
  DEFAULT,       ## gun, fusion_rifle, fragment
  AERIAL_MINE,   ## upward moving bullet with random horizontal movement
  ENERGY_CANNON, ## bullet with random error (-10 to 10 degrees)
  MEGA_CANNON,   ## strong bullet with 8 fragments
}
@export var type := Type.DEFAULT

# properties defined in the editor
@export var speed = 400         # movement speed
@export var fire_frequency = 8  # shots per second

# properties defined on instantiation
var direction := Vector2.ZERO

# state used by AERIAL_MINE to add random vertical movement
var velocity := Vector2(1,1)
var init_pos := Vector2.ZERO


func _ready():
  if direction == Vector2.ZERO:
    print("BULLET: invalid direction")
    queue_free()
    return

  init_pos = position

  # connect signals
  self.body_entered.connect(_on_body_entered)
  animated_sprite.animation_finished.connect(_on_animation_finished)

  # add random error to bullet direction (between -10 and 10 degrees)
  if type == Type.ENERGY_CANNON:
    direction = direction.rotated(deg_to_rad(randf_range(-10, 10)))

  # rotate sprite to match direction
  if type == Type.MEGA_CANNON:
    animated_sprite.rotation_degrees = rad_to_deg(direction.angle())


func _physics_process(delta):
  position += speed * direction * delta

  # add a random movement in the orthogonal direction
  if type == Type.AERIAL_MINE:
    var ort_dir = Vector2(direction.y, -direction.x)
    velocity += ort_dir * speed * delta * randf_range(-15, 15)
    position += velocity * delta
    # TODO: the following line only works for vertical bullets
    position.x = clamp(position.x, init_pos.x-35, init_pos.x+35)


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

  # spawn fragments in 8 directions
  if type == Type.MEGA_CANNON:
    var frag_scene = load("res://scenes/bullets/fragment.tscn")
    for angle in [0, 45, 90, 135, 180, 225, 270, 315]:
      var frag = frag_scene.instantiate()
      frag.direction = Vector2(1, 0).rotated(deg_to_rad(angle))
      frag.position = global_position + frag.direction * 7
      get_parent().add_child(frag)

  # stop bullet, disable collision and play hit animation
  speed = 0
  collision_shape.disabled = true
  animated_sprite.play("hit")
