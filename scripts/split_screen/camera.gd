extends Camera2D

# to be defined at instantiation
var target : Node2D = null


func _physics_process(_delta):
  if target:
    position = target.position
