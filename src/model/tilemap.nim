# Copyright Evgeny Zuev 2016.

import utils

type TileInfo* = object
  passable: bool

type TileMap* = ref object
  tiles: seq[TileInfo]
  size: Vec2i

#---TileInfo methods
proc `$`*(this: TileInfo): string =
  this.passable ? "." or "#"

proc passable*(this: TileInfo): bool {.inline.} =
  this.passable
#---


#---TileMap methods
proc `[]`*(this: TileMap, v: Vec2i): var TileInfo =
  this.tiles[v.x + v.y * this.size.x]

iterator cells*(this: TileMap): Vec2i =
  for x in 0..<this.size.x:
    for y in 0..<this.size.y:
      yield vec(x, y)

iterator pairs*(this: TileMap): (Vec2i, var TileInfo) =
  for v in this.cells:
    yield (v, this[v])

proc newTileMap*(size: Vec2i): TileMap =
  result = TileMap(
    size: size,
    tiles: newSeq[TileInfo](size.x * size.y)
  )
  #TODO make generator
  for v in result.cells:
    result[v].passable = not (v.x == 0 or v.y == 0 or v.x == size.x - 1 or v.y == size.y - 1)

proc `$`*(this: TileMap): string =
  result = ""
  for y in 0..<this.size.y:
    for x in 0..<this.size.x:
      result.add($this[vec(x, y)])
    result.add("\n")
#---