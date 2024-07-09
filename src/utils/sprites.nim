import ../../romConfig

const virtualOam* = cast[ptr array[40 * 4, byte]](virtualSpritesStart)

type
  dmgSpriteFlag* {.size: sizeof(byte).} = enum
    cgbBank1 = 0
    useObp1
    xFlip
    yFlip
    priority

  spriteFlags* = object
    cgbPalette* {.bitsize: 3.}: uint8
    attributes* {.bitsize: 5.}: set[dmgSpriteFlag]

  sprite* = object
    y*: uint8
    x*: uint8
    tile*: uint8
    flags*: spriteFlags

proc clearSprites*(): void =
  virtualOam.zeroMem(virtualOam[].len)

proc updateSprites*(spriteList: seq[sprite]): void =
  ## it's pretty slow… i mean…
  if spriteList.len > 0:
    for i in 0 ..< spriteList.len:
      virtualOam[i * sizeof(sprite)].addr.copyMem(spriteList[i].addr, sizeof(sprite))
