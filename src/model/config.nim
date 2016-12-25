# Copyright Evgeny Zuev 2016.

import utils
import tables

type
  PrimaryStat* = enum
    psStrength
    psAgility
    psIntelligence

  ItemKind* = enum
    ikWeapon
    ikArmor
    ikConsumable
    ikMaterial

  EquipmentSlot* = enum
    esMainHand
    esOffHand
    esHead
    esBody
    esLegs
    esFeet

  ItemConfig* = ref object
    id*: string
    slots*: set[EquipmentSlot]
    case kind*: ItemKind
    of ikWeapon:
      minDamage*: int
      maxDamage*: int
    of ikArmor:
      defense*: int
    of ikConsumable, ikMaterial:
      discard

  SkillEffectModifier* = enum
    emNone
    emStrength
    emAgility
    emIntelligence
    emDamageMainHand
    emDamageOffHand
    emDamageBothHands

  SkillEffectKind* = enum
    ekDamage

  SkillEffect* = ref object
    modifier*: SkillEffectModifier
    power*: float
    kind*: SkillEffectKind

  SkillConfig* = ref object
    id*: string
    apCost*: int
    maxDistance*: int
    effects*: seq[SkillEffect]

  PlayerConfig* = ref object
    skills*: seq[string]

  GameConfig* = ref object
    skills*: TableRef[string, SkillConfig]
    player*: PlayerConfig
    items*: TableRef[string, ItemConfig]

var gConfig: GameConfig

proc initConfig*() =
  gConfig = GameConfig(
    skills: newTable[string, SkillConfig]()
  )
  gConfig.player = PlayerConfig(
    skills: @["attack"]
  )

  gConfig.skills["attack"] = SkillConfig(
    id: "attack",
    apCost: 10,
    maxDistance: 1,
    effects: @[]
  )
  gConfig.skills["attack"].effects.add(SkillEffect(
    kind: ekDamage,
    modifier: emDamageMainHand,
    power: 1.0
  ))
