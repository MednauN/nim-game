# Copyright Evgeny Zuev 2016.

import utils, tilemap, worldobject
import algorithm, sequtils, strutils, tables

type LogicError* = object of Exception

type
  ActionKind* {.pure.} = enum
    Wait,
    Move,
    Open,
    Close

  ObjectAction* = ref object
    duration*: int
    kind*: ActionKind
    targetId*: WorldObjectId
    targetCell*: Vec2i

  Player* = ref object
    id*: WorldObjectId

  World* = ref object
    random*: Random
    map*: TileMap
    lastId*: WorldObjectId
    objects*: TableRef[WorldObjectId, WorldObject]
    pendingActions*: TableRef[WorldObjectId, ObjectAction]
    player*: Player
    age*: int64

proc genId(this: World): WorldObjectId =
  inc this.lastId
  result = this.lastId

proc playerObj*(this: World): WorldObject =
  this.objects[this.player.id]

iterator objectsAt*(this: World, cell: Vec2i): WorldObject =
  for obj in this.objects.values:
    if obj.pos == cell:
      yield obj

proc isPassable*(this: World, pos: Vec2i): bool =
  if not this.map[pos].passable:
    return false
  for obj in objectsAt(this, pos):
    if not obj.passable:
      return false
  return true

proc moveObject*(this: World, obj: WorldObject, pos: Vec2i) =
  if this.isPassable(pos):
    obj.pos = pos

proc invokeAction*(this: World, obj: WorldObject, action: ObjectAction) =
  case action.kind
  of ActionKind.Move:
    debug "Object $# moves to $#" % [repr(obj.id), $action.targetCell]
    this.moveObject(obj, action.targetCell)
  of ActionKind.Open:
    let door = this.objects.getOrDefault(action.targetId)
    if door == nil or door.kind != WorldObjectKind.Door:
      debug "Object $# is not a door" % $action.targetId
    elif not door.pos.adjacentTo(obj.pos):
      debug "Must stay at adjacent cell to close door"
    elif not door.lockStats.closed:
      debug "Door is already opened"
    elif door.lockStats.locked:
      debug "Door is locked"
    else:
      debug "Opened door $#" % $action.targetId
      door.lockStats.closed = false
  of ActionKind.Close:
    let door = this.objects.getOrDefault(action.targetId)
    if door == nil or door.kind != WorldObjectKind.Door:
      debug "Object $# is not a door" % $action.targetId
    elif not door.pos.adjacentTo(obj.pos):
      debug "Must stay at adjacent cell to close door"
    elif door.lockStats.closed:
      debug "Door is already closed"
    else:
      debug "Closed door $#" % $action.targetId
      door.lockStats.closed = true
  else: discard

proc newWorld*(): World =
  result = World(
    random: newRandom(100500),
    objects: newTable[WorldObjectId, WorldObject](),
    pendingActions: newTable[WorldObjectId, ObjectAction]()
  )
  let world = result
  world.map = newTileMap(vec(60, 40), world.random)
  world.player = Player(
    id: world.genId()
  )
  let startRoom = world.random.select(world.map.rooms)
  info "Placing player in room " & $startRoom.id
  let startPos = world.random.getVec(startRoom.rect.size - vec(1, 1)) + startRoom.rect.pos
  let playerObj = newWorldObject(world.player.id, startPos, WorldObjectKind.Character)
  playerObj.fractionStats.fraction = CharacterFraction.Player
  world.objects[playerObj.id] = playerObj

  for corridor in world.map.corridors:
    for pos in @[corridor.cells[0], corridor.cells[^1]]:
      if world.isPassable(pos):
        let door = newWorldObject(world.genId(), pos, WorldObjectKind.Door)
        door.lockStats.closed = true
        world.objects[door.id] = door

proc playOnce(this: World) =
  var actionsSeq = toSeq(this.pendingActions.pairs)
  # TODO shuffle actionsSeq
  let dt = actionsSeq.foldL(max(a, b[1].duration), 0)
  assert dt > 0
  for id, action in actionsSeq.items():
    if action.duration <= dt:
      this.pendingActions.del(id)
      this.invokeAction(this.objects[id], action)
    else:
      action.duration -= dt

  this.age += dt

proc waitingForInput*(this: World): bool =
  this.player.id notin this.pendingActions

proc play*(this: World) =
  if this.waitingForInput():
    return

  while not this.waitingForInput():
    this.playOnce()

  debug("Turn ended, world age: " & $this.age)

proc inputAction*(world: World, action: ObjectAction) =
  assert world.waitingForInput()
  world.pendingActions[world.player.id] = action

proc inputMove*(world: World, dir: Direction) =
  let newPos = world.playerObj.pos + dir.vec
  if world.isPassable(newPos):
    let action = ObjectAction(
      duration: 10,
      kind: ActionKind.Move,
      targetCell: newPos
    )
    world.inputAction(action)

proc inputOpenCloseDoor*(world: World, id: WorldObjectId) =
  let obj = world.objects.getOrDefault(id)
  if obj != nil and obj.kind == WorldObjectKind.Door:
    let action = ObjectAction(
      duration: 10,
      kind: obj.lockStats.closed ? ActionKind.Open or ActionKind.Close,
      targetId: id
    )
    world.inputAction(action)