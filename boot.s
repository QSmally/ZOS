
; This file is part of ZOS. © Joey Smalen

; depends on init_io, echo_clear, echo_str, shell

boot:
                  ld sp, 0xFFFF                 ; sp = 0xFFFF
                  di                            ; no interrupts
                  call init_io                  ; init peripherals

                  call echo_clear

                  ld hl, .boot_str
                  call echo_str

; free memory counter.
; just make absolutely sure block size is less than deepest used stack position.
; this routine will flip block start memory to test writability.

                  ld de, 256                    ; de = 256 byte blocks
                  ld hl, 0                      ; hl = ptr
                  ld ix, 0                      ; ix = written bytes
.free_loop:       ld a, (hl)
                  xor 0xFF
                  ld (hl), a                    ; invert mem location
                  xor (hl)                      ; did it write?
                  jr nz, .no_effect
                  add ix, de                    ; yes, increment counter
.no_effect:       add hl, de                    ; increment ptr
                  ld a, l
                  or h                          ; is ptr zero again?
                  jr nz, .free_loop

                  ld hl, .free_str
                  call echo_format_str

                  ld hl, .name_str
                  call echo_str

                  jp shell                      ; scheduler

.boot_str:        .asciiz "boot\r"
.free_str:        .asciiz "memory available 0x%x bytes\r"
.name_str:        .asciiz "\rZOS System I\r\r"
