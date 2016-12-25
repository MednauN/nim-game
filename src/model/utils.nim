# Copyright Evgeny Zuev 2016.

import future, options, logging, sequtils
export future, options, logging

type Vec2i* = object
  x*, y*: int

proc vec*(x, y: int): Vec2i = Vec2i(x: x, y: y)

type Direction* = enum
  dirUp,
  dirDown,
  dirLeft,
  dirRight

proc vec*(dir: Direction): Vec2i =
  case dir
  of dirUp: vec(0, -1)
  of dirDown: vec(0, 1)
  of dirLeft: vec(-1, 0)
  of dirRight: vec(1, 0)

proc `+`*(v1, v2: Vec2i): Vec2i =
  vec(v1.x + v2.x, v1.y + v2.y)

iterator directions*(): Direction =
  yield(dirUp)
  yield(dirDown)
  yield(dirLeft)
  yield(dirRight)

template `?`*(cond: untyped, vals: (untyped, untyped)): untyped =
  if cond:
    vals[0]
  else:
    vals[1]

proc findIf*[T](seq1: seq[T], pred: proc (x: T): bool {.closure.}): Option[T] =
  for x in filter(seq1, pred):
    return some(x)
  return none(T)