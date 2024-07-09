# Joypad related stuff

# raw hardware constants
const rJoyp* = cast[ptr byte](0xff00)

# joypad result type
type
  joypadButton* {.size: sizeof(byte).} = enum
    buttonA = 0
    buttonB
    buttonSelect
    buttonStart
    buttonRight
    buttonLeft
    buttonUp
    buttonDown

  joypadButtons* = set[joypadButton]

# ASM calls
func getJoypadState*(): joypadButtons {.
  importc: "joypad", codegenDecl: "$# $#$# __preserves_regs(c,d,e,h,l)"
.}
