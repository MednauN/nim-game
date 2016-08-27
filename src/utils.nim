# Copyright Evgeny Zuev 2016.

import future, options, logging, sequtils
export future, options, logging

type Vec2i* = object
  x*, y*: int

proc vec*(x, y: int): Vec2i = Vec2i(x: x, y: y)

template `?`*(cond: untyped, vals: (untyped, untyped)): untyped =
  if cond:
    vals[0]
  else:
    vals[1]

proc findIf*[T](seq1: seq[T], pred: proc (x: T): bool {.closure.}): Option[T] =
  for x in filter(seq1, pred):
    return some(x)
  return none(T)