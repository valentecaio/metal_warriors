# Global autoload

extends Node

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
}