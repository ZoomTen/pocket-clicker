proc vblank* () {.exportc: "VBlank", homeProc.} =
    ## VBlank interrupt.
    discard