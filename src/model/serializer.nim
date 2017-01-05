# Copyright Evgeny Zuev 2016.

import utils
import json, strutils, tables

proc fromJson*(obj: var bool, jobj: JsonNode) =
  obj = jobj.bval

proc fromJson*[T: SomeInteger](obj: var T, jobj: JsonNode) =
  obj = T(jobj.num)

proc fromJson*(obj: var SomeReal, jobj: JsonNode) =
  obj = jobj.fnum

proc fromJson*(obj: var string, jobj: JsonNode) =
  obj = jobj.str

proc fromString*[T: enum](s: string): T =
  for val in low(T)..high(T):
    if withoutPrefix($val) == s:
      return val
  raise newException(KeyError, "Unknown enum key: " & s)

proc fromJson*[T: enum](obj: var T, jobj: JsonNode) =
  obj = fromString[T](jobj.str)

proc fromJson*[T](obj: var seq[T], jobj: JsonNode) =
  obj = @[]
  for val in jobj:
    var elem: T
    fromJson(elem, val)
    obj.add(elem)

proc fromJson*[K: string or enum, V](obj: var TableRef[K, V], jobj: JsonNode) =
  obj = newTable[K, V]()
  for key, val in jobj:
    var data: V
    fromJson(data, val)
    when K is string:
      obj[key] = data
    else:
      obj[fromString[K](key)] = data

template fieldFromJson(obj: untyped, jobj: JsonNode) =
  # Workaround for `fieldPairs` - it doesn't work as expected
  block:
    var newObj: type(obj)
    fromJson(newObj, jobj)
    obj = newObj

proc fromJson*[T: ref object](obj: var T, jobj: JsonNode) =
  new(obj)
  for key, val in fieldPairs(obj[]):
    if key in jobj:
      fieldFromJson(val, jobj[key])

proc loadTableFromFile*[K, V](fname: string, outTable: var TableRef[K, V]) =
  outTable = newTable[K, V]()
  let jobj = parseFile(fname)
  for val in jobj:
    let key = val.getStr("id")
    var data: V
    data.fromJson(val)
    outTable[key] = data