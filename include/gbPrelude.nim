# Since pragmas cannot be imported, here's a use case of `include`.

# banked and nonbanked functions
{.pragma: homeProc, codegenDecl: "$# $#$# NONBANKED".}
{.pragma: bankedProc, codegenDecl: "$# $#$# BANKED".}
{.pragma: oldCall, codegenDecl: "$# $#$# __sdcccall(0)".}

# i can't yet find a way to make bank numbers a Nim pragma
# so {.emit: "#pragma bank N".} will have to do for now.

# Bind to GBDK for int-to-str conversions, because Nim's method forces everything
# to int64, and performs an int64/int64 binary long division, which is fine for
# today's computers and probably today's embedded hardware, but is FUCKED when we
# force the same thing on an 8-bit console from 1989.
const MaxIntStrLen = 10
proc iToA (n: cint, s: ptr cstring, radix: uint8): cstring {.importc: "itoa", oldCall.}
proc lToA (n: clong, s: ptr cstring, radix: uint8): cstring {.importc: "ltoa", oldCall.}
proc ulToA (n: culong, s: ptr cstring, radix: uint8): cstring {.importc: "ultoa", oldCall.}

proc `$`* (x: uint32): string =
    let xi: ptr cstring = cstring.create(MaxIntStrLen)
    result = $(x.ulToA(xi, 10.uint8))
    xi.dealloc()

proc `$`* (x: int32): string =
    let xi: ptr cstring = cstring.create(MaxIntStrLen)
    result = $(x.lToA(xi, 10.uint8))
    xi.dealloc()

proc `$`* (x: int16): string =
    let xi: ptr cstring = cstring.create(MaxIntStrLen)
    result = $(x.iToA(xi, 10.uint8))
    xi.dealloc()
