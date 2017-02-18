# Copyright Evgeny Zuev 2016.

import future, options, logging, sequtils, macros, strutils, mersenne
export future, options, logging, strutils

type Vec2i* = object
  x*, y*: int

type Rect2i* = object
  pos*: Vec2i
  size*: Vec2i

type Direction* = enum
  dirUp,
  dirDown,
  dirLeft,
  dirRight

type Random* = ref object
  mt: MersenneTwister

proc vec*(x, y: int): Vec2i = Vec2i(x: x, y: y)

proc newRect*(pos: Vec2i, size: Vec2i): Rect2i =
  Rect2i(
    pos: pos,
    size: size
  )

iterator perimeter*(rect: Rect2i): Vec2i =
  for i in 0..<rect.size.x:
    yield vec(rect.pos.x + i, rect.pos.y)
  for i in 1..<rect.size.y:
    yield vec(rect.pos.x + rect.size.x - 1, rect.pos.y + i)
  for i in countdown(rect.size.x - 1, 0):
    yield vec(rect.pos.x + i, rect.pos.y + rect.size.y - 1)
  for i in countdown(rect.size.y - 1, 1):
    yield vec(rect.pos.x, rect.pos.y + i)

iterator cells*(rect: Rect2i): Vec2i =
  for x in rect.pos.x..<rect.pos.x + rect.size.x:
    for y in rect.pos.y..<rect.pos.y + rect.size.y:
      yield vec(x, y)

proc contains*(rect: Rect2i, v: Vec2i): bool =
  result = v.x >= rect.pos.x and v.y >= rect.pos.y and
           v.x <= rect.pos.x + rect.size.x - 1 and v.y <= rect.pos.y + rect.size.y - 1

proc vec*(dir: Direction): Vec2i =
  case dir
  of dirUp: vec(0, -1)
  of dirDown: vec(0, 1)
  of dirLeft: vec(-1, 0)
  of dirRight: vec(1, 0)

proc `+`*(v1, v2: Vec2i): Vec2i =
  vec(v1.x + v2.x, v1.y + v2.y)

proc `-`*(v1, v2: Vec2i): Vec2i =
  vec(v1.x - v2.x, v1.y - v2.y)

proc `*`*(v: Vec2i, mult: int): Vec2i =
  vec(v.x * mult, v.y * mult)

proc `div`*(v: Vec2i, divider: int): Vec2i =
  vec(v.x div divider, v.y div divider)

iterator neighbors*(cell: Vec2i): Vec2i =
  for p in perimeter(newRect(cell - vec(1, 1), vec(3, 3))):
    yield p

proc adjacentTo*(v1, v2: Vec2i): bool =
  (abs(v1.x - v2.x) + abs(v1.y - v2.y)) == 1

proc clamp*(v: Vec2i, minVec, maxVec: Vec2i): Vec2i =
  vec(clamp(v.x, minVec.x, maxVec.x), clamp(v.y, minVec.y, maxVec.y))

proc clamp*(rect: Rect2i, minVec, maxVec: Vec2i): Rect2i =
  let pos = clamp(rect.pos, minVec, maxVec)
  let size = clamp(rect.size, vec(0, 0), maxVec - pos)
  result = newRect(pos, size)

iterator directions*(): Direction =
  yield(dirUp)
  yield(dirDown)
  yield(dirLeft)
  yield(dirRight)

proc direction*(v: Vec2i): Direction =
  if v.y > 0:
    dirUp
  elif v.y < 0:
    dirDown
  elif v.x > 0:
    dirRight
  else:
    dirLeft

macro `?`*(cond, body: untyped): untyped =
  if body.kind != nnkInfix or not eqIdent(body[0], "or"):
    error("'or' exprected")
  let arg1 = body[1]
  let arg2 = body[2]
  result = quote do:
    (if `cond`: `arg1` else: `arg2`)

proc findIf*[T](seq1: seq[T], pred: proc (x: T): bool {.closure.}): Option[T] =
  for x in filter(seq1, pred):
    return some(x)
  return none(T)

proc withoutPrefix*(s: string): string =
  var i: int = 0
  for c in s:
    if c.isUpperAscii():
      break
    inc i
  result = s[i..s.len]

template newException*(exceptn: typedesc, message: string, eParent: ref Exception): untyped =
  var
    e: ref exceptn
  new(e)
  e.msg = message
  e.parent = eParent
  e

proc `$`*(exceptn: ref Exception): string =
  result = exceptn.msg != nil ? exceptn.msg or ""
  result.add("\n")
  result.add(getStackTrace(exceptn))
  if exceptn.parent != nil:
    result.add("Caused by:\n")
    result.add($exceptn.parent)

proc newRandom*(seed: uint32): Random =
  Random(
    mt: newMersenneTwister(seed.uint32)
  )

proc getFloat*(random: Random): float =
  random.mt.getNum().float / high(uint32).float

proc getInt*(random: Random, maxValue: int = high(int32)): int =
  min(int(random.getFloat() * maxValue.float), maxValue - 1)

proc getInt*(random: Random, minValue, maxValue: int): int =
  random.getInt(maxValue - minValue) + minValue

proc getVec*(random: Random, maxVec: Vec2i): Vec2i =
  let idx = random.getInt(maxVec.x * maxVec.y)
  result = vec(idx mod maxVec.x, idx div maxVec.x)

proc select*[T](random: Random, values: openarray[T]): T =
  values[random.getInt(values.len)]