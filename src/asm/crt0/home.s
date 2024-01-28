    .module Mylib_Home

.include "hardware.s"

    .area _HOME
.memcpy_simple:: ; copy from DE to HL for BC bytes
; exit if bc == 0
    ld a, b
    or c
    ret z
; do copy
    dec bc
    inc b
    inc c
loop$:
    ld a, (de)
    inc de
    ld (hl+), a
    dec c
    jr nz, loop$
    dec b
    ret z
    jr loop$

.memset_simple:: ; fill HL with A for BC bytes
; no bc check here, invalid if BC == 0 !
    dec bc
    inc b
    inc c
loopS$:
    ld (hl+), a
    dec c
    jr nz, loopS$
    dec b
    ret z
    jr loopS$

.display_off::
_display_off::
; exit if screen is already off
    ldh a, (.LCDC)
    and #LCDCF_ON
    ret z
waitvb$:
    ldh a, (.LY)
    cp #145
    jr nc, disable$
    jr waitvb$
disable$:
    ldh a, (.LCDC)
    res #LCDCF_B_ON, a
    ldh (.LCDC), a
    ret

_display_on::
    ldh a, (.LCDC)
    set #LCDCF_B_ON, a
    ldh (.LCDC), a
    ret

_wait_frame::
; ask for vblank
    xor a
    ldh (.vbl_done), a
loopZ$:
    halt
    nop
; check specifically for vblank
    ldh a, (.vbl_done)
    and a
    ret nz
    jr loopZ$

_wait_frames::
    ld c, a
waitmore$:
    call _wait_frame
    dec c
    jr nz, waitmore$
    ret

_joypad::
; read d-pad
    ld a, #.P15
    ldh (.P1), a
.rept 4
    ldh a, (.P1)
.endm
    cpl
    and #0b1111
    swap a
    ld b, a
; read button
    ld a, #.P14
    ldh (.P1), a
.rept 4
    ldh a, (.P1)
.endm
    cpl
    and #0b1111
    or b
    ld b, a
; reset joypad
    ld a, #(.P14 | .P15)
    ldh (.P1), a
; retval in A
    ld a, b
    ret