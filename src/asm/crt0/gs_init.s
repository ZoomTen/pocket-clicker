    .module Mylib_Gsinit

; I assume this is for pre-init array data
; to be placed into memory so that it can
; be modified, not sure if I need it now

    .area _GSINIT
gsinit::
    ld bc, #l__INITIALIZER
    ld de, #s__INITIALIZER
    ld hl, #s__INITIALIZED
    call .memcpy_simple

    .area _GSFINAL
    ret
