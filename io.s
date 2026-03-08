
; This file is part of ZOS. © Joey Smalen

DMA2 = 0x60       ; 0b011
DMA = 0x80        ; 0b100
PORTA = 0xA0      ; 0b101
PORTB = 0xA1
PORTCA = 0xA2
PORTCB = 0xA3
SIOA = 0xC0       ; 0b110
SIOB = 0xC1
SIOCA = 0xC2
SIOCB = 0xC3
CTC0 = 0xE0       ; 0b111
CTC1 = 0xE1
CTC2 = 0xE2
CTC3 = 0xE3

; mass execute I/O operations.
;
; hl = address to mass I/O block format:
;     .byte I/O addr
;     .byte block len
;     .byte data
;     .byte data
;     .byte data
;     .byte data
;     ...
;     .byte 0 (I/O addr 0 = end of all)
;
; clobbers a, b, c, hl, flags

mass_io_helper:
                  ld a, (hl)                    ; I/O addr = byte0
                  or 0
                  ret z                         ; if zero, done
                  ld c, a
                  inc hl
                  ld b, (hl)                    ; counter = byte1
                  inc hl
                  otir                          ; output range
                  jr mass_io_helper

; echos the clear display sequence Esc[2J.
; clobbers a, hl, flags

echo_clear:
                  ld hl, .clear_escseq
                  jr echo_str

.clear_escseq:    .byte 0x1B, 0x5B, 0x32, 0x4A, 0

; echos a newline.
; clobbers a, flags

echo_newline:
                  ld a, 0x0D
                  jr echo

; echo a null-terminated string.
; hl = address of str
; clobbers a, hl, flags

echo_str:
                  ld a, (hl)
                  or 0
                  ret z                         ; return when done
                  call echo
                  inc hl
                  jr echo_str

; echo a null-terminated format string, with arguments.
;
; hl = address of str
; ix = %x
; iy = %X
;
; clobbers a, hl, flags

echo_format_str:
                  ld a, (hl)
                  or 0
                  ret z                         ; return when done
                  inc hl
                  cp "%"                        ; is format char ahead?
                  jr z, .fmt                    ; yes, do special stuff
                  call echo                     ; no, just echo it
                  jr echo_format_str

.fmt:             ld a, (hl)
                  or 0
                  ret z                         ; return when done
                  inc hl
                  cp "%"                        ; is "%%"?
                  call z, echo
                  cp "x"                        ; is "%x"?
                  jr z, .fmt_hex_ix
                  cp "X"                        ; is "%X"?
                  jr z, .fmt_hex_iy
                  call echo                     ; otherwise, just echo itself
                  jr echo_format_str

.fmt_hex_ix:      ld a, ixh
                  call echo_hex_byte            ; print ixh
                  ld a, ixl
                  call echo_hex_byte            ; print ixl
                  jr echo_format_str

.fmt_hex_iy:      ld a, iyh
                  call echo_hex_byte            ; print iyh
                  ld a, iyl
                  call echo_hex_byte            ; print iyl
                  jr echo_format_str

; echo a hex byte, nibble or ASCII character.

echo_hex_byte:
                  push af                       ; save lower
                  srl a                         ; move upper to lower
                  srl a
                  srl a
                  srl a
                  call echo_hex                 ; print upper
                  pop af                        ; restore lower, print lower

echo_hex:
                  and 0x0F                      ; mask lower nibble
                  or "0"                        ; offset by "0"
                  cp 0x3A                       ; is digit?
                  jp m, echo
                  add 0x07                      ; offset by "0" to "A"

echo:
                  out (SIOB), a                 ; print character
                  push af
.sio_busy:        in a, (SIOCB)                 ; status word
                  bit 2, a                      ; is buffer empty?
                  jr z, .sio_busy               ; no, loop
                  pop af
                  ret

; interprets register A as an ASCII hex character and shifts it into DE.
; clobbers a, c, flags
; returns m=1 if invalid character

interpret:
                  xor 0x30                      ; map to 0-9
                  cp 0x0A                       ; is digit?
                  jp m, .is_digit
                  add 0x89                      ; map A-F to FA-FF
                  cp 0xFA                       ; is hex letter?
                  ret m                         ; return m=1 invalid char
.is_digit:        sla a                         ; move lower to upper
                  sla a
                  sla a
                  sla a

                  ld c, 4                       ; shift count
.hex_shift:       sla a                         ; carry = MSB
                  rl e                          ; shift in e
                  rl d                          ; shift in d
                  dec c
                  jp nz, .hex_shift             ; shift if not done yet
                  ret                           ; zero means m=0

; resets all I/O
;
; CTC1 is configured for baudrate generation (for SIOB)
; DMA & DMA2 is reset
; SIOB is configured for 8N1 communication

init_io:
                  ld hl, .init_io_begin
                  call mass_io_helper
                  ret

.init_io_begin:
                  .byte CTC1                    ; init CTC1 for baudrate
                  .byte .init_io_ctc_end - .init_io_ctc
.init_io_ctc:     .byte 0b01010101              ; counter mode, rising edge
                  .byte 12                      ; 1843200 / 12 = 153600
.init_io_ctc_end:

                  .byte DMA2                    ; reset DMA2
                  .byte .init_io_dma2_end - .init_io_dma2
.init_io_dma2:    .byte 0xC3                    ; reset
.init_io_dma2_end:

                  .byte DMA                     ; reset DMA
                  .byte .init_io_dma_end - .init_io_dma
.init_io_dma:     .byte 0xC3                    ; reset
.init_io_dma_end:

                  .byte SIOCB                   ; init SIOB for UART communication
                  .byte .init_io_sio_end - .init_io_sio
.init_io_sio:     .byte 0b00011000              ; reset
                  .byte 4                       ; reg 4
                  .byte 0b01000100              ; 16x, 1 stop bit, no parity
                  .byte 3                       ; reg 3
                  .byte 0b11000001              ; 8 bits, rx enable
                  .byte 5                       ; reg 5
                  .byte 0b01101000              ; 8 bits, tx enable
                  .byte 1                       ; reg 1
                  .byte 0b00000000              ; all int disable
.init_io_sio_end:
                  .byte 0                       ; end of all
