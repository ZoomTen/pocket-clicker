import ../utils/codegen
# VRAM related stuff

# Hardware constants

# scroll stuff
const
  rScy* = cast[ptr byte](0xff42)
  rScx* = cast[ptr byte](0xff43)

# LCD status

type
  rStatModes* {.size: sizeof(byte).} = enum
    mode0 = 0
    mode1
    mode2
    mode3

  rStatFlag* {.size: sizeof(byte).} = enum
    vBlank = 0
    busy
    coincidence
    mode00
    mode01
    mode10
    lycSelect

  rStatFlags* = set[rStatFlag]

const rStat* = cast[ptr rStatFlags](0xff41)

type
  rLcdcFlag* {.size: sizeof(byte).} = enum
    bgEnable = 0
    objEnable
    objTall
    map9c00
    tiles8000
    winEnable
    win9c00
    lcdOn

  rLcdcFlags* = set[rLcdcFlag]

const
  rLcdc* = cast[ptr rLcdcFlags](0xff40)
  rLy* = cast[ptr byte](0xff44)

# graphics tables
const
  vTiles* = cast[ptr array[0x800 * 3, byte]](0x8000)
  vTiles0* = cast[ptr array[0x800, byte]](0x8000)
  vTiles1* = cast[ptr array[0x800, byte]](0x8800)
  vTiles2* = cast[ptr array[0x800, byte]](0x9000)

  vMaps* = cast[ptr array[0x800, byte]](0x9800)
  vMap0* = cast[ptr array[0x400, byte]](0x9800)
  vMap1* = cast[ptr array[0x400, byte]](0x9c00)

# helpers

## Length of 2bpp tiles in bytes
## example: 6.tiles(); or just 6.tiles
template tiles*(i: Natural): int =
  i * 0x10

## Get address of a tile relative to some pointer
template tileOffset*(base: pointer, n: int): ptr UncheckedArray[byte] =
  cast[ptr UncheckedArray[byte]](cast[int](base) + n.tiles())

## Get address corresponding to a coordinate on some BG maps
template mapOffset*(base: pointer, x, y: uint8): ptr UncheckedArray[byte] =
  cast[ptr UncheckedArray[byte]](cast[uint16](base) + x + (y.uint16 * 0x20))

## Enable certain rLCDC flags except lcdOn (use turnOnScreen())
template enableLcdcFeatures*(i: rLcdcFlags): untyped =
  when lcdOn in i:
    {.
      error: "Please use turnOnScreen() to enable the LCD instead of specifying lcdOn!"
    .}
  rLcdc[] = rLcdc[] + i

## Disable certain rLCDC flags except lcdOn (use turnOffScreen())
template disableLcdcFeatures*(i: rLcdcFlags): untyped =
  when lcdOn in i:
    {.
      error:
        "Please use turnOffScreen() to disable the LCD instead of specifying lcdOn!"
    .}
  rLcdc[] = rLcdc[] - i

# Calls to ASM/std functions
func turnOnScreen*(): void {.
  importc: "display_on", codegenDecl: "$# $#$# __preserves_regs(b,c,d,e,h,l)"
.}

func turnOffScreen*(): void {.
  importc: "display_off", codegenDecl: "$# $#$# __preserves_regs(b,c,d,e,h,l)"
.}

## Wait for 1 V-blank interrupt
func waitFrames*(): void {.
  importc: "wait_frame", codegenDecl: "$# $#$# __preserves_regs(b,c,d,e,h,l)"
.}

## Wait N × 1 V-blank interrupt
func waitFrames*(
  nFrames: uint8
): void {.importc: "wait_frames", codegenDecl: "$# $#$# __preserves_regs(b,d,e,h,l)".}

## Alias to waitFrames()
template waitFrame*(): void =
  waitFrames()

# Functions
when not defined(useAsmProcs):
  func setVram*(toAddr: pointer, value: byte, size: Natural) {.homeProc.} =
    ## Fill VRAM locations even when the screen is still on.
    var dest = cast[ptr byte](toAddr)
    for i in 1 ..< size:
      # wait for Vram
      while busy in rStat[]:
        discard

      # we can write to it now
      dest[] = value
      dest = cast[ptr byte](cast[int](dest) + 1)
      # can't do it like this..
      # the resulting code is slow, risking TOCTTOU errors
      #   cast[ptr UncheckedArray[byte]](toAddr)[i] = value

  func copyVram*(toAddr, fromAddr: pointer, size: Natural) {.homeProc.} =
    ## Copy some data to VRAM even when the screen is still on.
    var
      src = cast[ptr byte](fromAddr)
      dest = cast[ptr byte](toAddr)
      val = src[]
    for i in 0 ..< size:
      while busy in rStat[]:
        discard
      dest[] = val
      # can't do it like this either, deferencing both is expensive
      #   dest[] = src[]
      dest = cast[ptr byte](cast[int](dest) + 1)
      src = cast[ptr byte](cast[int](src) + 1)
      val = src[]
else:
  func setVram*(toAddr: pointer, value: byte, size: Natural) {.homeProc.} =
    # from: toAddr → de, value → a, size → [stack]
    #   to: toAddr → hl,            size → bc
    asm """
    ; de -> hl
      ld h, d
      ld l, e
    
    ; a -> e
      ld e, a

    ; get pushed size to bc
      add sp, #2
      pop bc
      add sp, #-4 ; return to what it was before

    ; go about our usual business...
    wait$:
      ldh a, (#0xff41) ; rStat
      bit 1, a
      jr nz, wait$

      ld a, e
      ld (hl+), a
      dec bc
      ld a, c
      or b
      jr nz, wait$
    """

  func copyVram*(toAddr, fromAddr: pointer, size: Natural) {.homeProc.} =
    # from: toAddr → de, fromAddr → bc, size → [stack]
    #   to: toAddr → hl, fromAddr → de, size → bc
    asm """
      ld h, d
      ld l, e

      ld d, b
      ld e, c

      add sp, #2
      pop bc
      add sp, #-4

    wait$:
      ldh a, (#0xff41) ; rStat
      bit 1, a
      jr nz, wait$

      ld a, (de)
      ld (hl+), a
      inc de
      dec bc
      ld a, c
      or b
      jr nz, wait$
    """
