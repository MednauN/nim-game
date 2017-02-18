# Copyright (c) Evgeny Zuev 2017.

import utils

type
  WorldObjectId* = int

  WorldObjectKind* {.pure.} = enum
    Door
    Container
    Stairs
    Character

  CharacterFraction* {.pure.} = enum
    Monster
    Player

  BattleStats* = ref object
    health*: int
    maxHealth*: int

  LootStats* = ref object

  LockStats* = ref object
    closed*: bool
    locked*: bool

  FractionStats* = ref object
    fraction*: CharacterFraction

  WorldObject* = ref object
    id*: WorldObjectId
    pos*: Vec2i
    kind*: WorldObjectKind

    battleStats*: BattleStats
    lootStats*: LootStats
    lockStats*: LockStats
    fractionStats*: FractionStats

proc alive*(stats: BattleStats): bool =
  stats.health > 0

proc passable*(obj: WorldObject): bool =
  case obj.kind:
  of WorldObjectKind.Door:
    not obj.lockStats.closed
  of WorldObjectKind.Container:
    false
  of WorldObjectKind.Stairs:
    true
  of WorldObjectKind.Character:
    obj.battleStats.alive

proc newWorldObject*(id: WorldObjectId, pos: Vec2i, kind: WorldObjectKind): WorldObject =
  result = WorldObject(
    id: id,
    pos: pos,
    kind: kind
  )
  case kind:
  of WorldObjectKind.Door:
    result.lockStats = LockStats()
  of WorldObjectKind.Container:
    result.lockStats = LockStats()
    result.lootStats = LootStats()
  of WorldObjectKind.Stairs:
    discard
  of WorldObjectKind.Character:
    result.battleStats = BattleStats()
    result.fractionStats = FractionStats()
