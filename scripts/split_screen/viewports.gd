extends HBoxContainer

@onready var viewport1 = $ViewportContainer1/Viewport1
@onready var viewport2 = $ViewportContainer2/Viewport2
@onready var camera1 = $ViewportContainer1/Viewport1/Camera2D
@onready var camera2 = $ViewportContainer2/Viewport2/Camera2D
@onready var stage = $ViewportContainer1/Viewport1/Stage


func _ready():
  get_viewport().size_changed.connect(on_size_changed)
  on_size_changed()
  viewport2.world_2d = viewport1.world_2d
  camera1.target = stage.get_node("Players/Player1")
  camera2.target = stage.get_node("Players/Player2")



### CALLBACKS ###

func on_size_changed():
  print('_on_size_changed')
  var screen_size = get_viewport().get_visible_rect().size
  size = screen_size
