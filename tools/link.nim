## Mimics icc for the linking and everything
## Calls sdldgb directly.
##
## Not only is this basically a hack off Nim's default linker
## assumptions, but putting this inside config.nims will make it
## run *as* Nim is compiling, which isn't what I want

import os
import ./helpers

import ../romConfig # bleh

import std/streams
import std/strutils
import std/math
import std/algorithm

########################################################################

type
  RecordKind = enum
    Data = 0
    Eof
    ExSegAddr
    StSegAddr
    ExLinAddr
    StLinAddr
  Record = object
    kind: RecordKind
    address: uint16
    data: seq[byte]
  IhxObject = object
    records: seq[Record]

proc toRecord (s: string): Record =
  var ss = s.newStringStream()
  if ss.readChar() != ':':
    raise newException(CatchableError, "starting byte must be ':'")
  let recLength = fromHex[uint8](ss.readStr(2))
  result.data.setLen(recLength)
  result.address = fromHex[uint16](ss.readStr(4))
  result.kind = cast[RecordKind](fromHex[int](ss.readStr(2)))
  for i in 0'u8..<recLength:
    result.data[i] = fromHex[byte](ss.readStr(2))
  # TODO: validate checksum?
  
proc makeBin(ihxFileName: string): seq[byte] =
  var
    s = openFileStream(ihxFileName, fmRead)
    o: string
    i: IhxObject
    highestAddr: uint16 = 0'u16
  while s.readLine(o):
    i.records.add(o.toRecord())
    if (
      let someHighAddr =
        uint16(
          int(i.records[^1].address) + i.records[^1].data.len()
        )
      someHighAddr > highestAddr
    ):
      highestAddr = someHighAddr
  
  var convertedBinary = newSeq[byte](highestAddr)
  for record in i.records:
    for byteIndex in 0..<record.data.len():
      convertedBinary[record.address + uint16(byteIndex)] =
        record.data[byteIndex]
  return convertedBinary

proc ihx2bin(ihxFileName, binFileName, gameName: string): void =
  var
    romImage = ihxFileName.makeBin()
    st = binFileName.openFileStream(fmWrite)
  romImage.setLen(
    ceilDiv(romImage.len, 0x4000) * 0x4000
  )
  
  # write the game title in the header
  if gameName.len > 16:
    raise newException(CatchableError, "game name must be <= 16 characters")
  
  # I want to use romImage[a..b] = string :(
  for i in 0..<0x10:
    if i > (gameName.len - 1):
      break
    romImage[0x134 + i] = byte(gameName[i])
    
  # fix both checksums
  # header
  var headerCheck = 0'u8
  for i in 0x134..0x14c:
    headerCheck += romImage[i]
  romImage[0x14d] = headerCheck
  
  # global
  var globalCheck = 0'u16
  for i in 0..<romImage.len:
    if i in 0x14e..0x14f:
      continue
    globalCheck += uint16(romImage[i])
  romImage[0x14e] = uint8((globalCheck shr 8) and 0xff)
  romImage[0x14f] = uint8(globalCheck and 0xff)
    
  
  # write the actual file
  st.writeData(romImage[0].addr, romImage.len)

proc noi2sym(noiFileName, symFileName: string): void =
  var
    o: string
    syms: seq[string]
    s = openFileStream(noiFileName, fmRead)
  while s.readLine(o):
    if o.startsWith("DEF "):
      let n = o.split(' ')
      assert n.len == 3
      # skip "l_" stuff because that's the section length
      if n[1].startsWith("l_"):
        continue
      when false: # TODO: still assuming non-banked for now, this won't work
        # convert address to gameboy format
        let romAddr = fromHex[int](n[2])
        var (bank, offset) = divmod(romAddr, 0x4000)
        if bank > 1:
          offset += 0x4000
      syms.add("$#:$# $#" % [
        "00",
        n[2][2..^1].align(4, '0'),
        n[1]
      ])
  syms.sort()
  var m = openFileStream(symFileName, fmWrite)
  for sym in syms:
    m.writeLine(sym)

########################################################################

when isMainModule:
  let gbdkRoot = getGbdkRoot()
  var inputs = commandLineParams().join(" ").paramsToSdldInput()

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

  # turn it into a GB ROM
  when true:
    (outfDir / outfName & ".ihx").ihx2bin(outfDir / outfName & outfExt, romTitle)
      # Autosizing already handled
      # Figure out what makebin's -Z option does
    (outfDir / outfName & ".noi").noi2sym(outfDir / outfName & ".sym")
  else:
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
