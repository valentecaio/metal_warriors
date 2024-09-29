extends AnimatableBody2D

@onready var animated_sprite = $AnimatedSprite2D

# properties defined in the editor
@export var type := Global.ElevatorType.Metal
@export var speed := 60        ## movement speed (pixels per second)
@export var max_height := 446  ## max delta height (pixels)
@export var stop_time := 1.0   ## time to wait at the top/bottom (seconds)

enum State {UP, DOWN, STOP}
var state := State.UP
var initial_height := 0.0


func _ready():
  animated_sprite.pause()
  animated_sprite.animation = Global.elevator_type_names[type]
  initial_height = position.y


func _physics_process(delta):
  match state:
    State.UP:
      position.y -= speed * delta
      if position.y < initial_height - max_height:
        state = State.STOP
        await get_tree().create_timer(stop_time).timeout
        state = State.DOWN
    State.DOWN:
      position.y += speed * delta
      if position.y >= initial_height:
        state = State.STOP
        await get_tree().create_timer(stop_time).timeout
        state = State.UP
    State.STOP:
      pass
