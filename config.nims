import os, strutils
import ./romConfig

const
  # whether or not we should be able inspect the output here
  buildCacheHere = true

# GBDK dirs
#-------------------------------------#
let
  gbdkRoot = getEnv("GBDK_ROOT")

when not defined(nimsuggest):
  doAssert(
    gbdkRoot != "", "Please set the GBDK_ROOT env var."
  )

let
  gbdkBin = gbdkRoot / "bin"
  gbdkInc = gbdkRoot / "include"
#-------------------------------------#

# Setup scripts
#-------------------------------------#
proc setupGbdk* () =
  # set c compiler as ""icc"" but is actually sdcc
  switch "cc", "icc"

  # abuse the c compiler options to use a nimscript
  # for compiling, linking and finalization
  # only works on unix-like environments unfortunately
  # can't trick it into using the current nim exe :(
  put "icc.exe", thisDir()/"tools"/"compiler.nims"
  put "icc.options.always", ""

  put "icc.linkerexe", thisDir()/"tools"/"link.nims"
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

#-------------------------------------#
if projectPath() == thisDir()/mainFile:
  setupGbdk()
  switch "include", thisDir()/"include"/"gbPrelude.nim"
  when buildCacheHere:
    switch "nimcache", "_build"
  switch "listCmd"
#-------------------------------------#

# Entry points
#-------------------------------------#
task build, "Build a Game Boy ROM":
  let
    args = commandLineParams()[1..^1].join(" ")
  selfExec([
    "c", args, "-o:" & romName & ".gb",
    thisDir() / mainFile
  ].join(" "))

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
#-------------------------------------#
