# Copyright Evgeny Zuev 2016.

type Vec2i* = object
  x*, y*: int

proc vec*(x, y: int): Vec2i = Vec2i(x: x, y: y)

template `?`*(cond: untyped, vals: (untyped, untyped)): untyped =
  if cond:
    vals[0]
  else:
    vals[1]
