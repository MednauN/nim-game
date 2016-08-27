# Copyright Evgeny Zuev 2016.

import utils, tilemap

type Player = ref object
  name: string

type WorldObjectKind* = enum
  woPlayer

type WorldObject* = ref object
  pos: Vec2i
  kind: WorldObjectKind

proc pos*(this: WorldObject): Vec2i =
  this.pos

proc newWorldObject*(pos: Vec2i, kind: WorldObjectKind): WorldObject =
  result = WorldObject(
    pos: pos,
    kind: kind
  )

type WorldLevel = ref object
  tileMap: TileMap
  objects*: seq[WorldObject]

proc newWorldLevel(): WorldLevel =
  result = WorldLevel(
    tileMap: newTileMap(vec(20, 20)),
    objects: newSeq[WorldObject]()
  )
  result.objects.add(newWorldObject(vec(10, 10), woPlayer))

proc map*(this: WorldLevel): TileMap =
  this.tileMap

proc player*(this: WorldLevel): WorldObject =
  result = this.objects.findIf((x) => x.kind == woPlayer).get()

proc moveObject*(this: WorldLevel, obj: WorldObject, pos: Vec2i) =
  if this.map[pos].passable:
    obj.pos = pos

type World* = ref object
  level*: WorldLevel
  player: Player

proc newWorld*(): World =
  result = World(
    level: newWorldLevel()
  )