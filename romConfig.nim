when defined(nimscript): # for things that need outside access
  import os

  const
    # main source to build the ROM
    mainFile* = "src" / "main.nim"

# everything else

const
  # ROM file name, without the file extension
  # (extension is currently .gb for now)
  romName* = "PocketClicker"

  # Name to use inside the ROM header
  romTitle* = "STORYLESS"

  # where in WRAM should the virtual OAM start
  virtualSpritesStart* = 0xc000

  # where in WRAM should the stack grow from
  stackStart* = 0xe000 # assuming DMG only

  # where in HRAM should the sprite update code go
  oamHramCodeStart* = 0xff80

  # where in WRAM should variables go
  dataStart* = 0xc0a0

  # where in ROM should the compiled code start
  codeStart* = 0x200
