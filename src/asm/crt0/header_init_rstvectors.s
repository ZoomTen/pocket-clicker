    .module Mylib_Header

; Header and Game Boy init stuffs, some things are
; done the same as GBDK

.include "hardware.s"

    .area _HEADER (ABS)
;.org 0x00

;.org 0x08

;.org 0x10

;.org 0x18

;.org 0x20
;.call_hl:: jp (hl)

.org 0x28
.MemcpySmall:: ; copy from DE to HL for C bytes
    ld a, (de)
    ld (hl+), a
    inc de
    dec c
    jr nz, .MemcpySmall
    ret

.org 0x30
.MemsetSmall:: ; fill HL for C bytes with A
    ld (hl+), a
    dec c
    jr nz, .MemsetSmall
    ret

;.org 0x38 ; 0xFF = rst 0x38, can put a crash handler here

.org 0x40 ; vblank
    jp .vblank

;.org 0x48 ; LCD

;.org 0x50 ; Timer

;.org 0x58 ; Serial

;.org 0x60 ; Joypad

.org 0x68 ; free space...
.vblank::
    push af
    push hl
; increment frame counter
    ld hl, #.sys_time
    inc (hl)
    jr nz, noOverflow$
    inc hl
    inc (hl)
noOverflow$:
; acknowledge VBlank
    ld a, #1
    ldh (.vbl_done), a
; user vblank function (src/utils/interrupts.nim)
    call _VBlank
; update sprites
    call .refresh_OAM
    pop hl
    pop af
    reti

.org 0x100 ; Header area
.header::
    jr .program_init

.org 0x104 ; Nintendo logo
    .byte 0xCE,0xED,0x66,0x66
    .byte 0xCC,0x0D,0x00,0x0B
    .byte 0x03,0x73,0x00,0x83
    .byte 0x00,0x0C,0x00,0x0D
    .byte 0x00,0x08,0x11,0x1F
    .byte 0x88,0x89,0x00,0x0E
    .byte 0xDC,0xCC,0x6E,0xE6
    .byte 0xDD,0xDD,0xD9,0x99
    .byte 0xBB,0xBB,0x67,0x63
    .byte 0x6E,0x0E,0xEC,0xCC
    .byte 0xDD,0xDC,0x99,0x9F
    .byte 0xBB,0xB9,0x33,0x3E

.org 0x150 ; init
.reset::
.program_init::
    di
    ld sp, #.STACK
; store gameboy type
    ldh (__cpu), a
    cp #.CGB_TYPE
    jr nz, dmg$
; for GBA detection
    xor a
    srl e
    rla
    ldh (__is_GBA), a
dmg$:
    call .display_off

; copy DMA routine
    ld de, #.OAM_DMA_update
    ld hl, #.refresh_OAM
    ld c, #l__OAMDMA_CODE
    rst 0x28 ; MemcpySmall

; init stuff; A == 0 throughout
; starting with the display...
    xor a
    ldh (.SCX), a
    ldh (.SCY), a
    ldh (.STAT), a

; then the time
    ld hl, #.sys_time
    ld (hl+), a
    ld (hl), a

; clear interrupt flags
    ldh (.IF), a

; turn sound off
    ldh (.NR52), a

; clear virtual OAM;
; location of virtual OAM is not expected to change
    ld hl, #_shadow_OAM
    ld c, #(40 << 2) ; 40 entries × 4 bytes
    rst 0x30 ; MemsetSmall

; I want nimInErrorMode to somehow be initialized, but 
; I can't do it from the Nim program
; Hope the linker places Nim's stuff at the beginning
    ld hl, #s__DATA
    ld c, #11
    rst 0x30 ; MemsetSmall

; initialize the heap
    call ___sdcc_heap_init

; show window (A == 0)
    ldh (.WY), a
    ld a, #7
    ldh (.WX), a

; init palettes
    ld a, #0b11100100
    ldh (.BGP), a
    ldh (.OBP0), a
    ldh (.OBP1), a

; set curbank = 1
    inc a
    ldh (__current_bank), a

; init the memory explicitly initialized (if any)
    call gsinit
    
; update OAM *now*
    call .refresh_OAM

; enable vblank interrupt
    ld a, #.VBL_IFLAG
    ldh (.IE), a
    ei

; Main Screen Turn On !! (but screen elements are off)
    ld a, #(LCDCF_ON | LCDCF_WIN9C00 | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ8 | LCDCF_OBJOFF | LCDCF_BGOFF)
    ldh (.LCDC), a

; finally, start the program directly
    call _NimMainModule

_exit::
1$:
; pause forever
    halt
    nop
    jr 1$
