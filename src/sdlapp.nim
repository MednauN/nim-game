# Copyright Evgeny Zuev 2016.

import sdl2/sdl, sdl2/sdl_image as img
import colors
import utils
import world, tilemap

const ScreenSize = vec(1280, 720)
const WindowFlags = 0
const RendererFlags = sdl.RendererAccelerated or sdl.RendererPresentVsync

type SDLLogger* = ref object of Logger

type SDLException = object of Exception

method log*(logger: SDLLogger, level: Level, args: varargs[string, `$`]) =
  let logMsg = substituteLog(logger.fmtStr, level, args)
  case level:
  of lvlDebug, lvlInfo, lvlNotice:
    sdl.logInfo(sdl.LogCategoryApplication, "%s", logMsg)
  of lvlWarn:
    sdl.logWarn(sdl.LogCategoryApplication, "%s", logMsg)
  of lvlError, lvlFatal:
    sdl.logCritical(sdl.LogCategoryError, "%s", logMsg)
  else: discard

template raiseIf(pred: untyped, message: string) =
  if pred:
    raise newException(SDLException, message & ": " & $sdl.getError())

template sdlCall(methodToCall: untyped) =
  let ec {.gensym.} = methodToCall
  raiseIf(ec != 0, "sdl call error " & $ec)

proc setColor(this: sdl.Renderer, color: colors.Color) =
  let (r, g, b) = color.extractRGB()
  sdlCall: this.setRenderDrawColor(r, g, b, 0xFF)

proc fillRect(this: sdl.Renderer, x, y, w, h: int) =
  var rect = sdl.Rect(x: x, y: y, w: w, h: h)
  sdlCall: this.renderFillRect(addr(rect))

type SDLApp* = ref object
  alive: bool
  window: sdl.Window
  renderer: sdl.Renderer
  world: World

proc alive*(this: SDLApp): bool = this.alive

proc exit*(this: SDLApp) =
  this.alive = false

proc initSDLApp*(title: string, world: World): SDLApp =
  addHandler(SDLLogger())
  info "SDL logger initialized"

  result = SDLApp(
    alive: false,
    window: nil,
    renderer: nil,
    world: world
  )

  sdlCall: sdl.init(sdl.InitVideo)

  result.window = sdl.createWindow(
    title,
    sdl.WindowPosUndefined,
    sdl.WindowPosUndefined,
    ScreenSize.x,
    ScreenSize.y,
    WindowFlags
  )
  raiseIf(result.window == nil, "Can't create window")

  result.renderer = sdl.createRenderer(result.window, -1, RendererFlags)
  raiseIf(result.renderer == nil, "Can't create renderer")

  result.alive = true
  info "SDL initialized"

proc render*(this: SDLApp) =
  let r = this.renderer
  r.setColor(colBlack)
  sdlCall: r.renderClear()

  let level = this.world.level
  for v, tile in level.map:
    r.setColor(tile.passable ? (colors.Color(0x3D3C41), colors.Color(0x1E1D21)))
    r.fillRect(32 * v.x, 32 * v.y, 32, 32)

  for obj in level.objects:
    r.setColor(colors.Color(0x5F5293))
    r.fillRect(32 * obj.pos.x, 32 * obj.pos.y, 32, 32)

  r.renderPresent()

proc onKeyDown(this: SDLApp, key: sdl.Keycode) =
  let player = this.world.level.player
  var playerPos = player.pos

  case key:
  of sdl.K_W: playerPos.y -= 1
  of sdl.K_S: playerPos.y += 1
  of sdl.K_A: playerPos.x -= 1
  of sdl.K_D: playerPos.x += 1
  else: discard

  if playerPos != player.pos:
    this.world.level.moveObject(player, playerPos)

proc update*(this: SDLApp) =
  var e: sdl.Event

  while this.alive and sdl.pollEvent(addr(e)) != 0:
    case e.kind:

    of sdl.Quit:
      this.exit()

    of sdl.KeyDown:
      if e.key.keysym.sym == sdl.K_Escape:
        this.exit()
      else:
        this.onKeyDown(e.key.keysym.sym)

    else: discard

proc destroy*(this: SDLApp) =
  this.renderer.destroyRenderer()
  this.window.destroyWindow()
  img.quit()
  info "SDL destroyed"
  sdl.quit()
