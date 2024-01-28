import std/parseopt

type
  SdldInput* = object
    outputFile*: string
    objFiles*: seq[string]

proc paramsToSdldInput* (cmdline: string): SdldInput =
  var
    opts = cmdline.initOptParser()
    forOutput = false # accomodate short option separated by space
    result: SdldInput
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
  #echo command
  let (outStr, exitCode) = gorgeEx(command)
  if exceptOnError:
    if exitCode != 0:
      raise newException(Exception, outStr)
    else:
      echo outStr
  else:
    echo outStr

