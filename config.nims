import os, strutils
import ./romConfig

const
  # whether or not we should be able inspect the output here
  buildCacheHere = true

# Precompile "scripts"
#-------------------------------------#
proc precompileTools() =
  let tools = ["compile", "link"]

  for toolName in tools:
    if findExe("tools" / toolName) == "":
      echo "make '" & toolName & "' wrapper..."
      selfExec(
        ["c", "-d:release", "--hints:off", thisDir() / "tools" / toolName & ".nim"].join(
          " "
        )
      )

#-------------------------------------#

# Setup toolchain
#-------------------------------------#
proc setupGbdk() =
  # set c compiler as ""icc"" but is actually sdcc
  switch "cc", "icc"

  # abuse the c compiler options to use a nimscript
  # for compiling, linking and finalization
  put "icc.exe", thisDir() / "tools" / "compile"
  put "icc.options.always", ""

  put "icc.linkerexe", thisDir() / "tools" / "link"
  put "icc.options.linker", ""

  # basic nim compiler options
  switch "os", "standalone"
  switch "gc", "arc"
  switch "cpu", "i386" # hoping this was necessary

  switch "define", "useMalloc"
  switch "define", "noSignalHandler"
  switch "define", "danger"
  switch "define", "nimPreviewSlimSystem"

  ## uncomment to enable nim source lines in the ASM
  # switch "debugger", "native"

  # specifics
  switch "lineTrace", "off"
  switch "stackTrace", "off"
  switch "excessiveStackTrace", "off"
  switch "overflowChecks", "off"
  switch "threads", "off"
  switch "checks", "off"
  switch "boundChecks", "on"
  switch "panics", "on"
  switch "exceptions", "goto"
  switch "noMain", "on"

  ## useAsmProcs: set it to use ASM versions of
  ## critical procs like VRAM manipulation
  # switch "define", "useAsmProcs"

  ## gameDebug: nothing much
  # switch "define", "gameDebug"

#-------------------------------------#

# Set compile options specific to main file
#-------------------------------------#
if projectPath() == thisDir() / mainFile:
  setupGbdk()
  when buildCacheHere:
    switch "nimcache", "_build"
  switch "listCmd"
#-------------------------------------#

# Entry points
#-------------------------------------#
task build, "Build a Game Boy ROM":
  precompileTools()
  let args = commandLineParams()[1 ..^ 1].join(" ")
  selfExec(["c", args, "-o:" & romName & ".gb", thisDir() / mainFile].join(" "))

task clean, "Clean up this directory's compiled files":
  when buildCacheHere:
    # clean up build cache
    rmDir("_build")
    echo("removed build dir")

  # clean up compiled files
  for ext in [".gb", ".ihx", ".map", ".noi", ".sym"]:
    rmFile(romName & ext)
    echo("removed $#$#" % [romName, ext])

task cleanDist, "Clean up this directory's residual files":
  when buildCacheHere:
    # clean up build cache
    rmDir("_build")
    echo("removed build dir")

  # clean up residual files
  for ext in [".ihx", ".map", ".noi"]:
    rmFile(romName & ext)
    echo("removed $#$#" % [romName, ext])

  for ext in ["", ".exe"]:
    for toolProg in ["tools" / "compile", "tools" / "link"]:
      rmFile(toolProg & ext)
      echo("removed $#$#" % [toolProg, ext])
#-------------------------------------#
