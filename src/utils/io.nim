import ../hardware/video
import ./codegen

# Bind to GBDK for int-to-str conversions, because Nim's method forces everything
# to int64, and performs an int64/int64 binary long division, which is fine for
# today's computers and probably today's embedded hardware, but is FUCKED when we
# force the same thing on an 8-bit console from 1989.
const
  MaxInt16StrLen = 6
  MaxInt32StrLen = 11

proc iToA(
    n: int16, s: ptr cstring, radix: uint8
): cstring {.importc: "itoa", oldCall.} =
  discard

proc lToA(
    n: int32, s: ptr cstring, radix: uint8
): cstring {.importc: "ltoa", oldCall.} =
  discard

proc ulToA(
    n: uint32, s: ptr cstring, radix: uint8
): cstring {.importc: "ultoa", oldCall.} =
  discard

proc `$`*(x: uint32): string =
  let xi: ptr cstring = cstring.create(MaxInt32StrLen)
  result = $(ulToA(x, xi, 10.uint8))
  xi.dealloc()

proc `$`*(x: int32): string =
  let xi: ptr cstring = cstring.create(MaxInt32StrLen)
  result = $(x.lToA(xi, 10.uint8))
  xi.dealloc()

proc `$`*(x: int16): string =
  let xi: ptr cstring = cstring.create(MaxInt16StrLen)
  result = $(x.iToA(xi, 10.uint8))
  xi.dealloc()

proc echo*(base: ptr UncheckedArray[byte], s: string) =
  ## Echo override, but now you can place it directly in VRAM
  var i: uint8 = 0
  var atAddr: ptr byte = cast[ptr byte](base)
  for letter in s:
    # precalculate destination address to mitigate TOCTTOU problems
    atAddr = base[i].addr
    while busy in rStat[]:
      discard
    atAddr[] = letter.uint8
    i += 1
