task build, "Build project":
  switch("out", "bin/game")
  --define: debug
  --debuginfo
  --debugger: native
  --linedir: on
  --stacktrace: on
  --linetrace: on
  --verbosity: 1
  setCommand "c", "src/game.nim"