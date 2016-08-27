# Copyright Evgeny Zuev 2016.

import utils
import sdlapp
import world

try:
  var myWorld: World = newWorld()

  var sdlApp = initSDLApp("Game App", myWorld)

  while sdlApp.alive:
    sdlApp.update()
    sdlApp.render()

  sdlApp.destroy()
except:
  error("Unhandled exception:" & repr(getCurrentException()))