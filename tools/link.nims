#!/usr/bin/env -S nim e --hints:off

## Mimics icc for the linking and everything
## Calls sdldgb and makebin directly.
## Maybe ihxcheck and makebin can be rewritten in Nim, too...
##
## Not only is this basically a hack off Nim's default linker
## assumptions, but putting this inside config.nims will make it
## run *as* Nim is compiling, which isn't what I want

import os
import strutils
import ./helpers

import ../romConfig # bleh

when isMainModule:
  # check for gbdk root as in ../config.nims
  let
    gbdkRoot = getEnv("GBDK_ROOT")
  when not defined(nimsuggest):
    assert gbdkRoot != "", "Please set the GBDK_ROOT environment variable."

  # parse the params minus "nim" "e" "--hints:off"
  var inputs = commandLineParams()[3..^1].join(" ").paramsToSdldInput()

  let
    (outfDir, outfName, outfExt) = inputs.outputFile.splitFile()

  # first link everything into an .ihx file
  # going with whatever LCC has as the default
  execWithEcho((@[
    gbdkRoot / "bin" / "sdldgb",
    # "-n", # silent
    "-i", # output to IHX
    "-m", # generate map output
    "-j", # generate NoICE debug file
    "-u", # update all the listing files to reflect actual locations
    # define globals
      "-g _shadow_OAM=0x" & virtualSpritesStart.toHex(4),
      "-g .STACK=0x" & stackStart.toHex(4),
      "-g .refresh_OAM=0x" & oamHramCodeStart.toHex(4),
    # define base addrs
      "-b _DATA=0x" & dataStart.toHex(4),
      "-b _CODE=0x" & codeStart.toHex(4),
    # add libraries
      "-k " & gbdkRoot/"lib"/"sm83", "-l sm83.lib",
    # output to:
      outfDir / outfName & ".ihx",
  ] &
    # order object files as Nim orders them
    inputs.objFiles
  ).join(" "))

  # check if the resulting .ihx file is acceptable
  execWithEcho([
    gbdkRoot / "bin" / "ihxcheck",
    outfDir / outfName & ".ihx"
  ].join(" "))

  # turn it into a GB ROM
  execWithEcho([
    gbdkRoot / "bin" / "makebin",
    "-yN", # skip injecting nintendo logo
    "-Z",  # specify Game Boy binary
    "-yS", # Convert NoICE symfile to NO$GMB/BGB/standard symfile
    "-yo A", # Autosize ROM
    "-yn " & romTitle.quoteShell(), # give the ROM a cartname
    # which file?
      outfDir / outfName & ".ihx",
    # where to?
      outfDir / outfName & outfExt
  ].join(" "))

