
; This file is part of ZOS. © Joey Smalen

; depends on mass_io_helper, echo_str

; A loader from SIO to memory (0x5000) for 16 bytes.

loader:
                  ld hl, .entry_str
                  call echo_str

                  ld hl, loader_configure_begin
                  call mass_io_helper

.dma_loop:        ld a, 0xBF                    ; read status byte
                  out (DMA), a
                  ld a, 0x87                    ; re-enable dma
                  out (DMA), a
                  in a, (DMA)
                  bit 5, a
                  jr nz, .dma_loop

                  ld a, 0x83                    ; disable dma
                  out (DMA), a
                  ld hl, .done_str
                  call echo_str

                  jp wozmon

.entry_str:       .asciiz " begin typing 16 characters into 0x5000... "
.done_str:        .asciiz "done, returning to Wozmon "

loader_configure_begin:
                  .byte SIOCB
                  .byte .loader_data_sio_end - .loader_data_sio
.loader_data_sio: .byte 0b00000001              ; reg 1
                  .byte 0b11100000              ; ready enable, for receive
.loader_data_sio_end:

                  .byte DMA
                  .byte .loader_data_dma_end - .loader_data_dma
.loader_data_dma: .byte 0xC3                    ; reset
                  .byte 0b01101101              ; transfer, A -> B
                  .byte SIOB                    ; start addr low (SIOB)
                  .byte 15                      ; len low
                  .byte 0                       ; len high (16)

                  .byte 0b00111100              ; A fixed, is I/O

                  .byte 0b00010000              ; B increments, is memory

                  .byte 0b11001101              ; burst mode
                  .byte 0x00                    ; end addr low
                  .byte 0x50                    ; end addr high (0x5000)

                  .byte 0b10000010              ; stop on end, CE only, ready active low

                  .byte 0xBB                    ; read mask
                  .byte 0b00000001              ; only status
                  .byte 0xCF                    ; load
                  .byte 0x87                    ; enable dma
.loader_data_dma_end:
                  .byte 0                       ; end of all
