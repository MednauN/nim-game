# Copyright Evgeny Zuev 2016.

import model.utils
import model.config, model.world
import visual.sdlapp

try:
  loadConfig()
  var myWorld: World = newWorld()

  var sdlApp = initSDLApp("Game App", myWorld)

  while sdlApp.alive:
    sdlApp.update()
    sdlApp.renderFrame()

  sdlApp.destroy()
except:
  error("Unhandled exception:" & repr(getCurrentException()))