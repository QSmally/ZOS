
; This file is part of ZOS. © Joey Smalen

            .org 0x0000
            .include "zmon.s"                   ; entrypoint
            .include "io.s"

            .org 0x1000
            .include "cpy.s"

            .org 0x1100
            .include "loader.s"
