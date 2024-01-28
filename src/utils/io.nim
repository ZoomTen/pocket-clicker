import ../hardware/video

proc echo* (base: ptr UncheckedArray[byte], s: string) =
  ## Echo override, but now you can place it directly in VRAM
  var i: uint8 = 0
  var atAddr: ptr byte = cast[ptr byte](base)
  for letter in s:
  # precalculate destination address to mitigate TOCTTOU problems
    atAddr = base[i].addr
    while busy in rStat[]: discard
    atAddr[] = letter.uint8
    i += 1
