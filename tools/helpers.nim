## Helper functions, not compiled into anything but
## used by the other two files.

import std/os
import std/parseopt
import std/strutils
import std/osproc

type
  SdldInput* = object
    outputFile*: string
    objFiles*: seq[string]

proc getGbdkRoot* (): string =
  let
    gbdkRoot = getEnv("GBDK_ROOT")
  when not defined(nimsuggest):
    assert gbdkRoot != "", "Please set the GBDK_ROOT environment variable."
  return gbdkRoot

proc paramsToSdldInput* (cmdline: string): SdldInput =
  var
    opts = cmdline.initOptParser()
    forOutput = false # accomodate short option separated by space
  while true:
    opts.next()
    case opts.kind
    of cmdShortOption:
      if opts.key == "o": forOutput = true
    of cmdArgument:
      if forOutput:
        result.outputFile = opts.key
        forOutput = false
      else:
        result.objFiles.add opts.key
    of cmdLongOption:
      discard
    of cmdEnd:
      break
  return result

proc execWithEcho* (command: string, exceptOnError: bool = true) =
  #echo command.strip()
  let (outStr, exitCode) = execCmdEx(command)
  let outStrDisp = outStr.strip()
  if exceptOnError:
    if exitCode != 0:
      raise newException(Exception, outStr)
    else:
      if outStrDisp != "": echo outStrDisp
  else:
    if outStrDisp != "": echo outStrDisp

