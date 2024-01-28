    .module Mylib_SectionOrder

; ordering of segments
    .area _OAMDMA_CODE
    .area _HOME
    .area _BASE
    .area _CODE ; my code here
    .area _CODE_0
; constants
    .area _LIT
; init _DATA
    .area _INITIALIZER
    .area _GSINIT
    .area _GSFINAL
; uninitialized RAM
    .area _DATA
    .area _BSS
; initialized RAM
    .area _INITIALIZED
; malloc stuff
    .area _HEAP
    .area _HEAP_END
