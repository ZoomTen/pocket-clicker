## Mimics icc for compiling. Its purpose is to discern between
## C sources and ASM sources and makes it somewhat manageable.
##
## Calls sdcc directly.
##
## Compilation is slow, but I guess that's the kinda
## price to pay for *full* control over the C compiler invocation.
## *shrug*

import os
import strutils
import ./helpers

when isMainModule:
  let gbdkRoot = getGbdkRoot()
  var inputs = commandLineParams().join(" ").paramsToSdldInput()

  # I would hope this was invoked as 1 source file = 1 object file
  let
    (outfDir, outfName, outfExt) = inputs.outputFile.splitFile()
    (srcfDir, srcfName, srcfExt) = inputs.objFiles[0].splitFile()

  execWithEcho((
    case srcfExt.toLowerAscii()
    
    # run SDCC if we get a C file
    of ".c":
      @[
        gbdkRoot / "bin" / "sdcc",
        "-c", # compile only
        # basic includes
          "-I" & gbdkRoot / "include", # gbdk libraries
          "-I" & getCurrentDir() / "include", # our stuff and our nimbase.h
        # target architecture
          "-msm83",
          "-D" & "__TARGET_gb",
          "-D" & "__PORT_sm83",
        "--opt-code-speed",
        "--max-allocs-per-node", "50000",
        # LCC defaults
          "--no-std-crt0",
          "--fsigned-char",
          "-Wa-pogn",
        # which files
          "-o", outfDir / outfName & outfExt,
          srcfDir / srcfName & srcfExt
      ]
    
    # run SDAS if we get an ASM file
    of ".s", ".asm":
      @[
        gbdkRoot / "bin" / "sdasgb",
        "-l", # generate listing
        # LCC defaults
          "-pogn",
          "-o", outfDir / outfName & outfExt,
          srcfDir / srcfName & srcfExt
      ]
    
    else: raise newException(Exception, "unknown format")
  ).join(" ")) # bypass warnings 
