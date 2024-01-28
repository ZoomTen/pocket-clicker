; some shims for GBDK stdlib functions
	.module DummyShims

; Define heap area for malloc() impl
	.area _HEAP
___sdcc_heap:: .ds 2047

	.area _HEAP_END
___sdcc_heap_end:: .ds 1