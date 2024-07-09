import ../utils/[io, sprites]
import ../hardware/[video, joypad]
import ../assets
import std/[sugar, math]

type
  # This is a pretty big struct, so it has to be a ref.
  # Otherwise, creating this struct inside of a function
  # and then passing it around apparently creates
  # an SDCC internal error (specifically unbalanced stack).
  gameStruct = ref object
    counter: uint32
    counterStr: string

    curLvl: uint8
    curLvlStr: string

    toNext: uint32

    toNextDifference: uint32
    toNextDifferenceStr: string

    prevJoyState: joypadButtons
    joyState: joypadButtons

    sprites: seq[sprite]
    sprPos: tuple[x, y: uint8]

    animTimer: uint8

const # all of these reduced to a LUT at compile time! :D
  ## assuming Medium-Fast growth rate
  levelThresholds: seq[uint32] = collect(newSeq):
    for i in 1'u32 .. 100'u32:
      if i == 1'u32:
        0'u32
      else:
        i * i * i

  ## for the sprite Y-pos animation
  curveball: seq[uint8] = collect(newSeq):
    for i in 0 ..< 10:
      let j = i.float

      (max((abs(((j - 5.0) / 3.4).pow(3))) + 3, 0.0)).round().uint8 + 66

const maxExp = 1_000_000'u32

proc gameInit*() {.inline.} =
  turnOffScreen() # to make VRAM ops about 25% faster

  # BG tiles
  vTiles2.tileOffset(0x20).copyVram(font.addr, 0x60.tiles)

  # OBJ tiles
  vTiles0.copyVram(eevee.addr, (6 * 6).tiles)

  # setup titles
  type InitialLayout = tuple[x: uint8, y: uint8, text: string]

  const initLayout: seq[InitialLayout] =
    @[
      (2'u8, 14'u8, "POCKET CLICKER!"),
      (3'u8, 16'u8, "Just tap A..."),
      (3'u8, 1'u8, "Level:"),
      (4'u8, 3'u8, "Exp.:"),
      (1'u8, 5'u8, "To next:"),
    ]

  for (x, y, text) in initLayout:
    vMap0.mapOffset(x = x, y = y).echo text

  turnOnScreen()
  enableLcdcFeatures({bgEnable, objEnable})

proc gameStep*(gs: var gameStruct) =
  # no vars here, especially ones marked {.global.}
  # because if I do, the heap is just gonna be overloaded
  # and the game would refuse to work, so here I pass
  # a global game state struct

  # For detecting a single button press, simply compare the
  # current joyState with the one from the previous frame
  gs.prevJoyState = gs.joyState
  gs.joyState = getJoypadState()

  if gs.counter < maxExp:
    if (buttonA in gs.joyState) and (buttonA notin gs.prevJoyState):
      gs.animTimer = curveball.len
      gs.counter += 1
      gs.counterStr = $gs.counter

      # cheap (and wasteful) way of ensuring "correct" display in some
      # emulators (when you don't have much time): just print twice!
      vMap0.mapOffset(x = 10'u8, y = 3'u8).echo gs.counterStr
      vMap0.mapOffset(x = 10'u8, y = 3'u8).echo gs.counterStr

      if gs.counter == maxExp:
        vTiles0.copyVram(flareon.addr, (6 * 6).tiles)
        vMap0.mapOffset(x = 2'u8, y = 14'u8).echo "  YOU DID IT!  "
        vMap0.mapOffset(x = 2'u8, y = 14'u8).echo "  YOU DID IT!  "

      if gs.counter == gs.toNext:
        gs.curLvl += 1
        gs.curLvlStr = $gs.curLvl.uint32
        vMap0.mapOffset(x = 10'u8, y = 1'u8).echo gs.curLvlStr
        # curLvl starts at 1, list is 0-index, so
        # it's the same thing as [level + 1]
        gs.toNext =
          if gs.curLvl == 100:
            gs.counter
          else:
            levelThresholds[gs.curLvl]

      gs.toNextDifference = gs.toNext - gs.counter
      gs.toNextDifferenceStr = $(gs.toNextDifference)
      vMap0.mapOffset(x = 10'u8, y = 5'u8).echo "       " # cheap way of clearing
      vMap0.mapOffset(x = 10'u8, y = 5'u8).echo gs.toNextDifferenceStr
      vMap0.mapOffset(x = 10'u8, y = 5'u8).echo gs.toNextDifferenceStr

  when defined(gameDebug):
    if (buttonB in gs.joyState) and (buttonB notin gs.prevJoyState):
      gs.curLvl = 99
      gs.counter = 1_000_000 - 10
      gs.toNext = levelThresholds[gs.curLvl]
      gs.toNextDifference = gs.toNext - gs.counter

  # Make the sprite jump
  # Bunch of optimizations here to make the animation actually run
  # smoothly and not get bogged down by incorrectly using u16 ops
  # where unnecessary
  if gs.animTimer > 0:
    gs.animTimer -= 1
    var
      whichRow: uint8 = 1
      # Update the virtual OAM directly :/
      byteToChange: ptr byte = cast[ptr byte](virtualOam)
      i: byte = 0 # can't use for because they cast to int (AGAIN)??

    # Unqualified integers are cast to effectively int16 in the C output
    # Gotta be extra careful and throw 'u8 everywhere
    while whichRow <= 6:
      # also whichRow shl 3 == whichRow * 8
      byteToChange[] = ((whichRow - 1).uint8 shl 3'u8) + curveball[gs.animTimer]
      byteToChange = cast[ptr byte](cast[uint16](byteToChange) + sizeof(sprite).uint8)
      # even mod is one slow _moduchar call, so cannot use `i mod 6` here,
      # modelling what would've been done in ASM works well here and makes it fast
      if i == 6:
        i = 0
        whichRow += 1
      i += 1'u8

proc makeSquareSprite(
    spr: var seq[sprite],
    squareSize: uint8,
    beginTile: uint8,
    beginCoords: tuple[x, y: uint8],
) =
  spr = @[]
  var tile = beginTile

  # for some reason, the first sprite is bugged
  # and i don't have time yet to investigate why
  # (spent on the other issues :/)
  # so here's a dud sprite
  spr.add sprite()

  for y in 0'u8 ..< squareSize:
    for x in 0'u8 ..< squareSize:
      spr.add sprite(
        x: beginCoords.x + (x * 8'u8),
        y: beginCoords.y + (y * 8'u8),
        tile: tile,
        flags: spriteFlags(),
      )
      tile.inc()

proc gameLoop*() {.inline.} =
  var gameState = gameStruct(
    counter: 0,
    counterStr: $(0'u32),
    curLvl: 1,
    curLvlStr: $(1'u32),
    toNext: levelThresholds[1],
    toNextDifference: 8'u32,
    toNextDifferenceStr: $(8'u32),
    prevJoyState: {buttonA},
    joyState: {},
    sprites: @[],
    sprPos: (x: 64'u8, y: 72'u8),
  )
  gameState.sprites.makeSquareSprite(
    squareSize = 6, beginTile = 0, beginCoords = gameState.sprPos
  )
  updateSprites(gameState.sprites)

  # print status for the first time
  vMap0.mapOffset(x = 10'u8, y = 3'u8).echo $gameState.counter
  vMap0.mapOffset(x = 10'u8, y = 1'u8).echo $gameState.curLvl.uint32
  vMap0.mapOffset(x = 10'u8, y = 5'u8).echo $gameState.toNextDifference

  while true:
    gameStep(gameState)
    waitFrames()
