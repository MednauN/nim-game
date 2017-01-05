# Copyright Evgeny Zuev 2016.

import utils, tilemap
import algorithm, sequtils, strutils

type Player = ref object
  name: string

type LogicError* = object of Exception

type ObjectActionKind* = enum
  aMove,
  aInteract

type WorldObjectKind* = enum
  woPlayer,
  woNPC

type WorldObjectId* = distinct int

type MicroTicks* = int64

const ONE_TICK = 1000

type RegVal* = object
  value*: int
  maxValue*: int
  regenSpeed*: MicroTicks
  regenMod*: MicroTicks

proc newRegVal(maxValue: int, regenSpeed: MicroTicks, value: int = 0): RegVal =
  RegVal(
    value: min(value, maxValue),
    maxValue: maxValue,
    regenSpeed: regenSpeed,
    regenMod: 0
  )

proc regenerate*(this: var RegVal, dt: MicroTicks) =
  let ticks = (dt + this.regenMod) div this.regenSpeed
  this.value = min(this.value + ticks.int, this.maxValue)
  if this.value < this.maxValue:
    this.regenMod = (dt + this.regenMod) mod this.regenSpeed
  else:
    this.regenMod = 0

proc timeToFull*(this: RegVal): MicroTicks =
  (this.maxValue - this.value) * this.regenSpeed - this.regenMod

type ObjectAction* = ref object
  needAP: int
  case kind: ObjectActionKind
  of aMove:
    moveDir: Direction
  of aInteract:
    objectId: WorldObjectId

proc newActionMove*(moveDir: Direction): ObjectAction =
  ObjectAction(
    kind: aMove,
    moveDir: moveDir,
    needAP: 10
  )

type SecondaryStat* = enum
  sstMinDamage,
  sstMaxDamage,


type WorldObject* = ref object
  id: WorldObjectId
  pos: Vec2i
  kind: WorldObjectKind

  hp: RegVal

  action: ObjectAction

proc pos*(this: WorldObject): Vec2i =
  this.pos

proc kind*(this: WorldObject): WorldObjectKind = this.kind

proc newWorldObject*(id: WorldObjectId, pos: Vec2i, kind: WorldObjectKind): WorldObject =
  result = WorldObject(
    id: id,
    pos: pos,
    kind: kind,
    action: nil,
    hp: newRegVal(100, 10 * ONE_TICK, 100)
  )

type WorldLevel* = ref object
  tileMap: TileMap
  objects*: seq[WorldObject]
  lastId: WorldObjectId

proc genId(this: WorldLevel): WorldObjectId =
  inc this.lastId
  result = this.lastId

proc newWorldLevel*(): WorldLevel =
  result = WorldLevel(
    tileMap: newTileMap(vec(20, 20)),
    objects: newSeq[WorldObject](),
    lastId: WorldObjectId(0)
  )
  result.objects.add(newWorldObject(result.genId(), vec(10, 10), woPlayer))
  result.objects.add(newWorldObject(result.genId(), vec(5, 5), woNPC))
  result.objects.add(newWorldObject(result.genId(), vec(15, 15), woNPC))

proc map*(this: WorldLevel): TileMap =
  this.tileMap

proc player*(this: WorldLevel): WorldObject =
  result = this.objects.findIf((x) => x.kind == woPlayer).get()

proc isPassable*(this: WorldLevel, pos: Vec2i): bool =
  if not this.map[pos].passable:
    return false
  elif this.objects.anyIt(it.pos == pos):
    return false

  return true

proc moveObject*(this: WorldLevel, obj: WorldObject, pos: Vec2i) =
  if this.isPassable(pos):
    obj.pos = pos

proc invokeAction*(this: WorldLevel, obj: WorldObject, action: ObjectAction) =
  case action.kind
  of aMove:
    debug("Object $# moves $#" % [repr(obj.id), $action.moveDir])
    this.moveObject(obj, obj.pos + vec(action.moveDir))
  else: discard

type AIController* = ref object
  level*: WorldLevel

proc makeDecision*(this: AIController, obj: WorldObject) =
  assert obj.kind == woNPC

  if obj.action == nil:
    let dir = toSeq(directions()).findIf((x) => this.level.isPassable(obj.pos + x.vec))
    obj.action = newActionMove(dir.get())

proc makeTurn*(this: AIController) =
  for obj in this.level.objects:
    if obj.kind == woNPC:
      this.makeDecision(obj)

type World* = ref object
  level*: WorldLevel
  ai: AIController
  player: Player
  age: int64

proc newWorld*(): World =
  result = World(
    level: newWorldLevel(),
    age: 0
  )
  result.ai = AIController(level: result.level)

proc playOnce(this: World, maxdt: int): int =
  this.ai.makeTurn()

  var objects = this.level.objects.filter((x) => x.action != nil)
  objects.sort((x, y) => cmp(x.action.needAP, y.action.needAP))
  if objects.len == 0:
    return 0

  let dt = objects.len == 0 ? maxdt or min(objects[0].action.needAP, maxdt)
  for obj in objects:
    obj.action.needAP -= dt
    if obj.action.needAP == 0:
      this.level.invokeAction(obj, obj.action)
      obj.action = nil

  this.age += dt
  result = dt

proc play*(this: World, dt: int) =
  var dtLeft = dt
  while dtLeft > 0:
    dtLeft -= this.playOnce(dtLeft)

  debug("Turn ended, world age: " & $this.age)

proc inputMove*(world: World, dir: Direction) =
  let newPos = world.level.player.pos + dir.vec
  if world.level.isPassable(newPos):
    world.level.moveObject(world.level.player, newPos)
    world.play(10)