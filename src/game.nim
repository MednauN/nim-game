# Copyright Evgeny Zuev 2016.

import model.utils
import visual.sdlapp
import model.world

try:
  var myWorld: World = newWorld()

  var sdlApp = initSDLApp("Game App", myWorld)

  while sdlApp.alive:
    sdlApp.update()
    sdlApp.render()

  sdlApp.destroy()
except:
  error("Unhandled exception:" & repr(getCurrentException()))