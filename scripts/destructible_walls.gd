extends TileMapLayer


### callbacks ###

# destroy tile at bullet position
func bullet_hit(bullet):
  # print("DESTRUCTIBLE_WALL bullet_hit()")
  var pos = bullet.global_position
  var cell = local_to_map(pos)
  erase_cell(cell)
  
