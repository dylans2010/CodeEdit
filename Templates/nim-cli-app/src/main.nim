import os, strformat

proc main() =
  echo &"Welcome to {{PROJECT_NAME}} in Nim!"
  echo &"Command line arguments: {paramCount()}"

when isMainModule:
  main()
