
; This file is part of ZOS. © Joey Smalen

            .org 0x0000
            .include "boot.s"                   ; entrypoint
            .include "io.s"
            .include "stdlib.s"
            .include "zmon.s"                   ; reserves 0x4000 - 0x40FF
            .include "shell.s"                  ; reserves 0x4100 - 0x41FF

            .include "memcpy.s"
            .include "loader.s"
