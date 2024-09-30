extends TileMapLayer


### CALLBACKS ###

# destroy tile at bullet position
func hit_at(_damage, position):
  # print("DESTRUCTIBLE_WALL bullet_hit()")
  # var pos = bullet.global_position
  var cell = local_to_map(position)
  erase_cell(cell)
