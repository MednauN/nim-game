# Copyright Evgeny Zuev 2016.

import sdl2/sdl, sdl2/sdl_image as img, sdl2/sdl_ttf as ttf
import model.utils
import model.world, model.tilemap

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

proc rgba(color: int64 or uint32): Color =
  Color(
    r: (color shr 16) and 0xFF,
    g: (color shr 8) and 0xFF,
    b: color and 0xFF,
    a: (color shr 24) and 0xFF
  )

proc setColor(this: sdl.Renderer, color: Color) =
  sdlCall: this.setRenderDrawColor(color.r, color.g, color.b, color.a)

proc fillRect(this: sdl.Renderer, x, y, w, h: int) =
  var rect = sdl.Rect(x: x, y: y, w: w, h: h)
  sdlCall: this.renderFillRect(addr(rect))

proc renderText(this: sdl.Renderer, pos: Vec2i, text: string, font: ttf.Font, color: Color) =
  var surface = font.renderUTF8_Blended(text, color)
  var texture = sdl.createTextureFromSurface(this, surface)
  var rect = sdl.Rect(x: pos.x, y: pos.y, w: surface.w, h: surface.h)
  sdlCall: this.renderCopy(texture, nil, addr(rect))
  destroyTexture(texture)
  sdl.freeSurface(surface)

type SDLApp* = ref object
  alive: bool
  window: sdl.Window
  renderer: sdl.Renderer
  font: ttf.Font
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

  sdlCall: ttf.init()

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

  result.font = ttf.openFont("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 18)
  raiseIf(result.font == nil, "Cannot load font")

  result.alive = true
  info "SDL initialized"

proc renderFrame*(this: SDLApp) =
  let r = this.renderer
  r.setColor(rgba(0xFF000000))
  sdlCall: r.renderClear()

  let level = this.world.level
  for v, tile in level.map:
    r.setColor(tile.passable ? (rgba(0xFF5777BC), rgba(0xFF5B24A4)))
    r.fillRect(32 * v.x, 32 * v.y, 32, 32)

  for obj in level.objects:
    case obj.kind
    of woPlayer:
      r.setColor(rgba(0xFFA07BD2))
    of woNPC:
      r.setColor(rgba(0xFF088F4A))
    r.fillRect(32 * obj.pos.x, 32 * obj.pos.y, 32, 32)

  r.renderText(vec(650, 10), "Hello, world", this.font, rgba(0xFFffffff))

  r.renderPresent()

proc onKeyDown(this: SDLApp, key: sdl.Keycode) =
  case key:
  of sdl.K_W: this.world.inputMove(dirUp)
  of sdl.K_S: this.world.inputMove(dirDown)
  of sdl.K_A: this.world.inputMove(dirLeft)
  of sdl.K_D: this.world.inputMove(dirRight)
  else: discard


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
  ttf.closeFont(this.font)
  ttf.quit()
  img.quit()
  info "SDL destroyed"
  sdl.quit()
