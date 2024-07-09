{.warning[UnusedImport]: off.}

import ./scenes/game
import ./utils/[interrupts, math]

# I brought my own crt0.s :D
{.compile: "asm/crt0/section_order.s".}
{.compile: "asm/crt0/header_init_rstvectors.s".}
{.compile: "asm/crt0/oam_dma_code.s".}
{.compile: "asm/crt0/home.s".}
{.compile: "asm/crt0/gs_init.s".}
{.compile: "asm/crt0/wram.s".}
{.compile: "asm/crt0/hram.s".}

when isMainModule:
  gameInit()
  gameLoop()

# shims for some GBDK libc functions
{.compile: "asm/shims.s".}
