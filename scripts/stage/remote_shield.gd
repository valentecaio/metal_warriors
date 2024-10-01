extends StaticBody2D

# properties defined in the editor
@export var hp := 200
@export var lifetime := 5.0  ## seconds


func _ready():
  # TODO: set collision mask
  await get_tree().create_timer(lifetime).timeout
  queue_free()


# func _process(delta):
#   pass


### CALLBACKS ###

func hit(damage):
  hp -= damage
  if hp <= 0:
    queue_free()
