# Copyright Evgeny Zuev 2016.

import utils, sequtils

type
  TileKind* {.pure.} = enum
    Wall,
    Floor

  TileInfo* = object
    kind*: TileKind
    roomId*: int

  TileMapRoom* = ref object
    id*: int
    rect*: Rect2i
    adjacentRooms*: seq[int]

  TileMapCorridor* = ref object
    startRoomId*: int
    endRoomId*: int
    cells*: seq[Vec2i]

  TileMap* = ref object
    random: Random
    tiles*: seq[TileInfo]
    rooms*: seq[TileMapRoom]
    corridors*: seq[TileMapCorridor]
    size*: Vec2i

#---TileInfo methods
proc passable*(this: TileInfo): bool {.inline.} =
  this.kind in {TileKind.Floor}

proc `$`*(this: TileInfo): string =
  this.passable ? "." or "#"
#---

#---TileMapRoom methods
proc newTileMapRoom(id: int, rect: Rect2i): TileMapRoom =
  TileMapRoom(
    id: id,
    rect: rect,
    adjacentRooms: @[]
  )

#---

#---TileMap methods
proc `[]`*(this: TileMap, v: Vec2i): var TileInfo =
  this.tiles[v.x + v.y * this.size.x]

iterator cells*(this: TileMap): Vec2i =
  for x in 0..<this.size.x:
    for y in 0..<this.size.y:
      yield vec(x, y)

proc contains*(this: TileMap, v: Vec2i): bool =
  v.x >= 0 and v.y >= 0 and v.x < this.size.x and v.y < this.size.y

iterator pairs*(this: TileMap): (Vec2i, var TileInfo) =
  for v in this.cells:
    yield (v, this[v])

proc placeRect*(this: TileMap, minSize, size: Vec2i): Option[Rect2i] =
  let pos = this.random.getVec(this.size - size)
  var bottomRight = pos + size
  let checkRect = newRect(pos, bottomRight - pos)
  for cell in checkRect.cells():
    if this[cell].kind != TileKind.Wall:
      bottomRight.x = min(bottomRight.x, cell.x - 1)
      bottomRight.y = min(bottomRight.y, cell.y - 1)

  var realSize = bottomRight - pos
  if realSize.x < minSize.x and realSize.y >= minSize.y:
    while realSize.x < size.x:
      let rightRect = newRect(pos + vec(realSize.x, 0), vec(1, realSize.y))
      if toSeq(rightRect.cells).anyIt(this[it].kind != TileKind.Wall):
        break
      inc realSize.x
  elif realSize.y < minSize.y and realSize.x >= minSize.x:
    while realSize.y < size.y:
      let bottomRect = newRect(pos + vec(0, realSize.y), vec(realSize.x, 1))
      if toSeq(bottomRect.cells).anyIt(this[it].kind != TileKind.Wall):
        break
      inc realSize.y

  if realSize.x < minSize.x and realSize.y < minSize.y:
    return none(Rect2i)

  result = some(newRect(pos, realSize))

proc generateRooms*(this: TileMap) =
  let cellsCount = this.size.x * this.size.y
  let desiredFillRate = 0.25
  let maxFailCount = 50
  let minRoomSize = vec(3, 3)
  let maxRoomSize = vec(10, 10)
  let wallThickness = vec(2, 2)
  var takenSpace = 0
  var failCount = 0
  while (takenSpace.float / float(cellsCount)) < desiredFillRate and failCount < maxFailCount:
    let roomSize = this.random.getVec(maxRoomSize - minRoomSize + vec(1, 1)) + minRoomSize
    let outerRect = this.placeRect(minRoomSize + wallThickness * 2, roomSize + wallThickness * 2)
    if outerRect.isSome:
      failCount = 0
      let room = newTileMapRoom(
        this.rooms.len + 1,
        newRect(outerRect.get().pos + wallThickness, outerRect.get().size - wallThickness * 2)
      )
      this.rooms.add(room)
      for cell in room.rect.cells():
        this[cell].kind = TileKind.Floor
        this[cell].roomId = room.id
      takenSpace += room.rect.size.x * room.rect.size.y
      info "Placed room $# size: $#, takenSpace = $#% ($#/$#)" %
           [$room.id, $room.rect.size, $int(100.0 * takenSpace.float / cellsCount.float), $takenSpace, $cellsCount]
    else:
      inc failCount

proc corridorEndPos(this: TileMap, pos: Vec2i, startRoom: TileMapRoom): Option[seq[Vec2i]] =
  for dir in directions():
    let cell = pos + vec(dir)
    if cell notin this:
      continue
    if this[cell].passable and this[cell].roomId != startRoom.id:
      return some(@[cell])

  for cell in neighbors(pos):
    if cell notin this:
      continue
    if this[cell].passable and this[cell].roomId != startRoom.id:
      return some(@[pos + vec(direction(pos - cell)), cell])

  return none(seq[Vec2i])

proc makeCorridor*(this: TileMap, startRoom, endRoom: TileMapRoom): seq[Vec2i] =
  let startRect = newRect(startRoom.rect.pos + vec(1, 1), startRoom.rect.size - vec(2, 2))
  let startPoint = this.random.select(toSeq(startRect.perimeter()))
  let endPoint = this.random.select(toSeq(endRoom.rect.perimeter()))
  result = @[startPoint]

  var dirX = this.random.getInt(100) <= 50
  var pos = startPoint
  while pos != endPoint:
    let endPos = this.corridorEndPos(pos, startRoom)
    if endPos.isSome:
      result &= endPos.get()
      break
    if dirX and pos.x == endPoint.x:
      dirX = false
    if not dirX and pos.y == endPoint.y:
      dirX = true
    if dirX:
      pos.x += pos.x < endPoint.x ? 1 or -1
    else:
      pos.y += pos.y < endPoint.y ? 1 or -1
    result.add(pos)
    if this[pos].passable and this[pos].roomId != startRoom.id:
      break

  let realEndRoomId = this[result[^1]].roomId
  if realEndRoomId == 0 or realEndRoomId in startRoom.adjacentRooms:
    return nil

proc generateCorridors*(this: TileMap) =
  let maxOutConnections = 4
  let maxConnections = 6
  for room in this.rooms:
    let requiredConnections = this.random.getInt(maxOutConnections) + 1
    for i in 1..(requiredConnections - room.adjacentRooms.len):
      var desiredRoom = this.random.select(this.rooms)
      if desiredRoom.id == room.id:
        continue
      let corridor = this.makeCorridor(room, desiredRoom)
      if corridor == nil:
        continue
      let destRoomId = this[corridor[^1]].roomId
      let destRoom = this.rooms[destRoomId - 1]
      if destRoom.adjacentRooms.len >= maxConnections:
        continue
      room.adjacentRooms.add(destRoomId)
      destRoom.adjacentRooms.add(room.id)
      info "Corridor from $# to $# len $#" % [$room.id, $destRoom.id, $corridor.len]
      for cell in corridor:
        this[cell].kind = TileKind.Floor
      var startIndex = 0
      while this[corridor[startIndex]].roomId != 0:
        inc startIndex
      var endIndex = corridor.len - 1
      while this[corridor[endIndex]].roomId != 0:
        dec endIndex
      this.corridors.add(TileMapCorridor(
        startRoomId: room.id,
        endRoomId: destRoom.id,
        cells: corridor[startIndex..endIndex]
      ))


proc newTileMap*(size: Vec2i, random: Random): TileMap =
  result = TileMap(
    size: size,
    tiles: newSeq[TileInfo](size.x * size.y),
    rooms: @[],
    corridors: @[],
    random: random
  )
  result.generateRooms()
  result.generateCorridors()

proc `$`*(this: TileMap): string =
  result = ""
  for y in 0..<this.size.y:
    for x in 0..<this.size.x:
      result.add($this[vec(x, y)])
    result.add("\n")
#---