# Package

version       = "0.1.0"
author        = "Pesets"
description   = "Simple rouge-like game written in nim"
license       = "GPLv3"

bin = @["game"]
binDir = "bin"
srcDir = "src"

# Dependencies

requires "nim >= 0.14.3", "sdl2_nim >= 0.95"

