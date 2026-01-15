
; This file is part of ZOS. © Joey Smalen

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

; resets all I/O

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

                  .byte DMA                     ; reset DMA
                  .byte .init_io_dma_end - .init_io_dma
.init_io_dma:     .byte 0xC3                    ; reset
.init_io_dma_end:
                  .byte 0                       ; end of all
