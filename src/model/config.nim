# Copyright Evgeny Zuev 2016.

import utils, serializer
import tables, json, streams, os

type

  #---Common---

  PrimaryStat* = enum
    statStrength
    statMastery
    statConcentration

  SocialStat* = enum
    statCharm
    statPersuation
    statIntimidation

  DamageType* = enum
    # Physical
    dtBlunt
    dtPiercing
    # Magical
    dtArcane
    dtChaotic
    # Mixed
    dtFire
    dtPoison

  #---Items---

  ItemKind* = enum
    ikWeapon
    ikArmor
    ikOther

  EquipmentSlot* = enum
    # Weapon slots
    slotMainHand
    slotOffHand
    # Armor slots
    slotHead
    slotBody
    slotArms
    slotLegs
    slotFeet

  ItemQualityClass* = enum
    qualityJunk
    qualityCommon
    qualityGood
    qualityExellent
    qualityTreasure
    qualityArtifact

  WeaponClassConfig* = ref object
    id*: string
    name*: string
    possibleModifiers*: seq[string]
    slots*: set[EquipmentSlot]
    primaryDamage*: DamageType
    secondaryDamage*: seq[DamageType]
    attackSpeed*: float
    attackRange*: int
    damageSpread*: float

  ArmorClassConfig* = ref object
    id*: string
    name*: string
    possibleModifiers*: seq[string]
    slots*: set[EquipmentSlot]
    primaryDefenses*: seq[string]
    secondaryDefenses*: seq[string]

  EquipmentModifier* = ref object
    id*: string
    isMajor*: bool
    namePattern*: string
    qualityMult*: float
    statsBalance*: TableRef[PrimaryStat, float]
    damageTypeBalance*: TableRef[DamageType, float]

  GlobalItemsConfig* = ref object
    weapons*: TableRef[string, WeaponClassConfig]
    armor*: TableRef[string, ArmorClassConfig]
    modifiers*: TableRef[string, EquipmentModifier]

  #---Skills---

  SkillRequirements* = ref object
    weapons*: seq[string]
    damageTypes*: seq[DamageType]

  SkillLogicType* = enum
    slWeaponDamage
    slDirectDamage

  SkillConfig* = ref object
    id*: string
    name*: string
    description*: string
    castMessage*: string
    possibleModifiers*: seq[string]
    apCost*: int
    spCost*: int
    requirements*: SkillRequirements
    basePower*: float
    statMultipliers*: TableRef[PrimaryStat, float]
    case logic*: SkillLogicType
    of slDirectDamage:
      damageType*: DamageType
      skillRange*: int
    of slWeaponDamage:
      discard

  SkillModifier* = ref object
    id*: string
    namePattern*: string
    powerMult*: float
    chanceWeight*: float

  GlobalSkillsConfig* = ref object
    skills*: TableRef[string, SkillConfig]
    modifiers*: TableRef[string, SkillModifier]

  #---Monsters---

  MonsterClassConfig* = ref object
    id*: string
    name*: string
    graphics*: string
    levels*: Slice[int]
    possibleModifiers*: seq[string]
    possibleWeapons*: seq[string]
    possibleSkills*: seq[string]
    moraleMult*: float
    hpMult*: float
    defenseMult*: TableRef[string, DamageType]

  MonsterModifier* = ref object
    id*: string
    namePattern*: string
    powerMult*: float
    hpMult*: float
    chanceWeight*: float

  #---Dungeons---

  DungeonFloorConfig* = ref object
    id*: string
    monsters*: seq[string]

  DungeonConfig* = ref object
    id*: string
    possibleFloors*: seq[string]

  #---Global---

  PlayerConfig* = ref object
    startSkills*: seq[string]

  GameConfig* = ref object
    skills*: GlobalSkillsConfig
    items*: GlobalItemsConfig
    monsters*: TableRef[string, MonsterClassConfig]
    dungeons*: TableRef[string, DungeonConfig]
    player*: PlayerConfig

var gConfig: GameConfig

proc loadConfig*() =
  let configDir = "config"
  new gConfig
  new gConfig.skills
  new gConfig.items
  gConfig.monsters = newTable[string, MonsterClassConfig]()
  gConfig.dungeons = newTable[string, DungeonConfig]()
  new gConfig.player
  try:
    loadTableFromFile(configDir / "skills.json", gConfig.skills.skills)
    loadTableFromFile(configDir / "skill_modifiers.json", gConfig.skills.modifiers)
  except:
    echo getCurrentExceptionMsg()
    echo getStackTrace(getCurrentException())

proc config*(): GameConfig =
  gConfig