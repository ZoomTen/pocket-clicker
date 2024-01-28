    .module Mylib_OamDma

.include "hardware.s"

    .area _OAMDMA_CODE
.OAM_DMA_update::
; set target
    ld a, #>_shadow_OAM
    ldh (.DMA), a
; wait a while
    ld a, #0x28
wait$:
    dec a
    jr nz, wait$
    ret
