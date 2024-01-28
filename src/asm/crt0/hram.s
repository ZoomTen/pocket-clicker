    .module Mylib_HRAM

    .area _HRAM (ABS)
.org 0xff90
__current_bank:: .ds 1
__cpu:: .ds 1
__is_GBA:: .ds 1

.vbl_done:: .ds 1
