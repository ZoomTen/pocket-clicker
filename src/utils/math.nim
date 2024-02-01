import std/bitops
import ./codegen

# this function has an Emulicious profiler result of 528 min/3468 max/2607 avg, 46860 total cycles
# GBDK lib's counterpart is 3924 min/3976 max/3950 avg, 71028 total cycles
# who knew just adding stuff would be faster (?)
func mulLong* (x, y: clong): clong {.exportc: "_mullong", homeProc.} =
  var
    res: clong = 0
    x1 = x
    y1 = y
  while y1 > 0:
    if y1.bitAnd(1) == 1: res += x1
    x1 = x1 shl 1
    y1 = y1 shr 1
  return res

# # there's a reason why GBDK doesn't implement this function
# # it's slow as shit, but unfortunately Nim's default int-to-string impl uses this
# func divULongLong* (x, y: culonglong): culonglong {.exportc: "_divulonglong", homeProc.} =
#   var
#     res: culonglong = 0
#     remainder: culonglong = 0
#   for i in countdown(63, 0):
#     remainder = (remainder shl 1).bitOr((x shr i).bitAnd(1))
#     if remainder >= y:
#       remainder -= y
#       res = res.bitOr(1'u64 shl i)
#   return res
