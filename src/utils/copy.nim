proc copyMem* (toAddr, fromAddr: pointer, size: Natural): pointer {.homeProc.} =
  ## Copy some data from one place to another. Somehow, this is not __memcpy.
  ## We can probably take our sweet time here.
  for i in 0..<size:
    cast[ptr UncheckedArray[byte]](toAddr)[i] = cast[ptr UncheckedArray[byte]](fromAddr)[i]

proc setMem* (toAddr: pointer, value: byte, size: Natural): pointer {.homeProc.} =
  ## Fill a memory location for N bytes
  for i in 0..<size:
    cast[ptr UncheckedArray[byte]](toAddr)[i] = value
