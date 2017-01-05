# Copyright Evgeny Zuev 2016.

import utils
import tables

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
    weapons*: Table[string, WeaponClassConfig]
    armor*: Table[string, ArmorClassConfig]
    modifiers*: Table[string, EquipmentModifier]

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
    statMultipliers*: Table[PrimaryStat, float]
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
    skills*: Table[string, SkillConfig]
    modifiers*: Table[string, SkillModifier]

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
    defenseMult*: Table[string, DamageType]

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
    monsters*: Table[string, MonsterClassConfig]
    dungeons*: Table[string, DungeonConfig]
    player*: PlayerConfig

var gConfig: GameConfig

proc initConfig*() =
  discard #TODO

proc config*(): GameConfig =
  gConfig