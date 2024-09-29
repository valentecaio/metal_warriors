# Global autoload

extends Node

enum RobotState {
  DEFAULT,      ## walking or flying (drache)
  UNBOARDED,    ## waiting for pilot to board
  DEAD,         ## dead
}

enum BulletType {
  DEFAULT,       ## pistol, fusion_rifle, fragment
  AERIAL_MINE,   ## upward moving bullet with random horizontal movement
  ENERGY_CANNON, ## bullet with random error (-10 to 10 degrees)
  MEGA_CANNON,   ## strong bullet with 8 fragments
}

enum BlockType {
  BrownGray,
  BrownGreen,
  Green,
  Ice,
  Orange,
  Red,
  SpaceStationLeft,
  SpaceStationMiddle,
  SpaceStationRight,
  EarthStationFloorLeft,
  EarthStationFloorRight,
  EarthStationWallLeft,
  EarthStationWallMiddle,
  EarthStationWallRight,
}

# lookup table for block type names
var block_type_names = {
  BlockType.BrownGray: "brown_gray",
  BlockType.BrownGreen: "brown_green",
  BlockType.Green: "green",
  BlockType.Ice: "ice",
  BlockType.Orange: "orange",
  BlockType.Red: "red",
  BlockType.SpaceStationLeft: "space_station_left",
  BlockType.SpaceStationMiddle: "space_station_middle",
  BlockType.SpaceStationRight: "space_station_right",
  BlockType.EarthStationFloorLeft: "earth_station_floor_left",
  BlockType.EarthStationFloorRight: "earth_station_floor_right",
  BlockType.EarthStationWallLeft: "earth_station_wall_left",
  BlockType.EarthStationWallMiddle: "earth_station_wall_middle",
  BlockType.EarthStationWallRight: "earth_station_wall_right",
}

enum ElevatorType {
  Wood,
  Metal,
}

var elevator_type_names = {
  ElevatorType.Wood: "wood",
  ElevatorType.Metal: "metal",
}
