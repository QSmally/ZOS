
; This file is part of ZOS. © Joey Smalen

; depends on echo, echo_str, echo_newline, map_find

; 0x4100 - 0x417F = buffer

shell:
                  ; init command map from filesystem
                  jr .escape

.not_return:      cp 0x08                       ; is backspace?
                  jr z, .backspace
                  cp 0x1B                       ; is escape?
                  jr z, .escape
                  inc l                         ; advance text index
                  jp p, .next_char              ; next char only if no overflow

.newline:         call echo_newline             ; print newline

.escape:          ld a, ">"
                  call echo                     ; print ">"
                  ld a, " "
                  call echo                     ; print space
                  ld hl, 0x4101                 ; h = 0x41, l = offset

.backspace:       dec l                         ; backspace
                  jp m, .newline                ; newline if minus/underflow

.next_char:       in a, (SIOCB)                 ; status word
                  bit 0, a                      ; is char available?
                  jr z, .next_char              ; no, loop
                  in a, (SIOB)                  ; load available char
                  ld (hl), a                    ; append to buffer
                  call echo
                  cp 0x0D                       ; is return?
                  jr nz, .not_return

                  ld (hl), 0                    ; overwrite CR with 0
                  ld hl, 0x4100                 ; hl = buffer
                  ld ix, .builtins              ; ix = command map
                  call map_find

                  jr z, .not_found
                  ld l, (ix)                    ; load addr to jump to
                  ld h, (ix+1)
                  jp (hl)                       ; jump to addr if found

.not_found:       call echo_str                 ; echo buffer
                  ld hl, .not_found_str
                  call echo_str                 ; echo 'not found'
                  jr .escape

.builtins:
                  .asciiz "zmon"
                  .word wozmon
                  .asciiz "loader"
                  .word loader
                  .asciiz "memcpy"
                  .word memcpy
                  .byte 0

.not_found_str:   .asciiz ": command not found\r"
