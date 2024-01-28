import macros

template incBin*(filename: static string): untyped =
  ## Lets you include files directly into the ROM.
  ## (Borrowed from exelotl's Natu)
  ##
  ## .. important::
  ##    Use `const` with this, not `let`! Unless you REALLY
  ##    want that file to be loaded wholesale into memory…
  const data = static:
    const str = staticRead(getProjectPath() & "/" & filename)
    var arr: array[str.len, uint8]
    for i, c in str:
      arr[i] = uint8(c)
    arr
  data
