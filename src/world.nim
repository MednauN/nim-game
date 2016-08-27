# Copyright Evgeny Zuev 2016.

import utils, tilemap

type Player = ref object
  name: string

type WorldLevel = ref object
  tileMap: TileMap

proc newWorldLevel(): WorldLevel =
  result = WorldLevel(
    tileMap: newTileMap(vec(20, 20))
  )

proc map*(this: WorldLevel): TileMap =
  this.tileMap

type World* = ref object
  level*: WorldLevel
  player: Player

proc newWorld*(): World =
  result = World(
    level: newWorldLevel()
  )