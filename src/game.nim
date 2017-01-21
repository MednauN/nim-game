# Copyright Evgeny Zuev 2016.

import model.utils
import model.config, model.world
import visual.sdlapp

try:
  initSDLSystem()
  loadConfig()
  var myWorld = newWorld()
  var myApp = initSDLApp("Game App", myWorld)

  try:
    while myApp.alive:
      myApp.update()
      myApp.renderFrame()

    myApp.destroy()
  except:
    error("Unhandled exception: " & $getCurrentException())

except:
  echo getCurrentException()