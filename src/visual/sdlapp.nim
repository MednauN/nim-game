# Copyright Evgeny Zuev 2016.

import sdl2/sdl, sdl2/sdl_image as img, sdl2/sdl_ttf as ttf
import tables
import model.utils
import model.worldobject, model.world, model.tilemap

const ScreenSize = vec(1280, 720)
const CellSize = vec(48, 48)
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

proc fillRect(this: sdl.Renderer, rect: Rect2i) =
  var sdlRect = sdl.Rect(x: rect.pos.x, y: rect.pos.y, w: rect.size.x, h: rect.size.y)
  sdlCall: this.renderFillRect(addr(sdlRect))

proc drawRect(this: sdl.Renderer, rect: Rect2i) =
  var sdlRect = sdl.Rect(x: rect.pos.x, y: rect.pos.y, w: rect.size.x, h: rect.size.y)
  sdlCall: this.renderDrawRect(addr(sdlRect))

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
  charFont: ttf.Font
  world: World
  viewport: Rect2i

proc alive*(this: SDLApp): bool = this.alive

proc exit*(this: SDLApp) =
  this.alive = false

proc initSDLSystem*() =
  addHandler(SDLLogger())
  info "SDL logger initialized"
  sdlCall: sdl.init(sdl.InitVideo)
  sdlCall: ttf.init()

proc updateViewport*(this: SDLApp) =
  this.viewport = newRect(vec(0, 0), vec(19, 15))
  this.viewport.pos = clamp(this.world.playerObj.pos - (this.viewport.size div 2),
                            vec(0, 0),
                            this.world.map.size - this.viewport.size)

proc initSDLApp*(title: string, world: World): SDLApp =
  result = SDLApp(
    alive: false,
    window: nil,
    renderer: nil,
    world: world
  )

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
  raiseIf(result.font == nil, "Cannot load main font")

  result.charFont = ttf.openFont("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 36)
  raiseIf(result.charFont == nil, "Cannot load character font")

  result.updateViewport()
  result.alive = true
  info "SDL initialized"

proc screenCellRect(this: SDLApp, cell: Vec2i): Rect2i =
  var screenPos = cell - this.viewport.pos
  screenPos.x *= CellSize.x
  screenPos.y *= CellSize.y
  result = newRect(screenPos, CellSize)

proc drawCharacter(this: SDLApp, cell: Vec2i, charStr: string, bgColor: Color, charColor: Color) =
  let screenRect = this.screenCellRect(cell)
  this.renderer.setColor(bgColor)
  this.renderer.fillRect(screenRect)
  if charStr.len == 0:
    return
  var surface = this.charFont.renderUTF8_Blended(charStr, charColor)
  var texture = sdl.createTextureFromSurface(this.renderer, surface)
  try:
    let offset = (screenRect.size - vec(surface.w, surface.h)) div 2
    var rect = sdl.Rect(x: screenRect.pos.x + offset.x, y: screenRect.pos.y + offset.y, w: surface.w, h: surface.h)
    sdlCall: this.renderer.renderCopy(texture, nil, addr(rect))
  finally:
    destroyTexture(texture)
    sdl.freeSurface(surface)

proc renderFrame*(this: SDLApp) =
  let r = this.renderer
  r.setColor(rgba(0xFF000000))
  sdlCall: r.renderClear()

  # Render world
  let world = this.world

  # Render tiles
  sdlCall: r.setRenderDrawBlendMode(BLENDMODE_NONE)
  for v in this.viewport.cells:
    let tile = world.map[v]

    r.setColor(tile.passable ? rgba(0xFF9F6D47) or rgba(0xFF5D310F))
    r.fillRect(this.screenCellRect(v))

  # Render grid at the top of tiles
  r.setColor(rgba(0x40000000))
  sdlCall: r.setRenderDrawBlendMode(BLENDMODE_BLEND)
  for v in this.viewport.cells:
    r.drawRect(this.screenCellRect(v))

  for obj in world.objects.values:
    if obj.pos notin this.viewport:
      continue
    case obj.kind
    of WorldObjectKind.Door:
      var screenRect = this.screenCellRect(obj.pos)
      let isVertical = world.map[obj.pos + vec(1, 0)].passable
      if obj.lockStats.closed:
        if isVertical:
          screenRect.pos.x += screenRect.size.x div 3
          screenRect.size.x = screenRect.size.x div 3
        else:
          screenRect.pos.y += screenRect.size.y div 3
          screenRect.size.y = screenRect.size.y div 3
      else:
        if isVertical:
          screenRect.size.y = screenRect.size.y div 4
        else:
          screenRect.size.x = screenRect.size.x div 4
      r.setColor(rgba(0xFF45250d))
      r.fillRect(screenRect)
    else: discard

  # Render player
  this.drawCharacter(world.playerObj.pos, "\u263A", rgba(0xFF41823A), rgba(0xFF000000))

  r.renderText(vec(650, 10), "Hello, world", this.font, rgba(0xFFffffff))

  r.renderPresent()

proc onKeyDown(this: SDLApp, key: sdl.Keycode) =
  case key:
  of sdl.K_W: this.world.inputMove(dirUp)
  of sdl.K_S: this.world.inputMove(dirDown)
  of sdl.K_A: this.world.inputMove(dirLeft)
  of sdl.K_D: this.world.inputMove(dirRight)
  of sdl.K_F:
    block mainCycle:
      for dir in directions():
        let cell = this.world.playerObj.pos + vec(dir)
        for obj in this.world.objectsAt(cell):
          if obj.lockStats != nil:
            this.world.inputOpenCloseDoor(obj.id)
            break mainCycle
  else: discard

  this.world.play()
  this.updateViewport()


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
