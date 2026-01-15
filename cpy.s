
; This file is part of ZOS. © Joey Smalen

; A simple memcpy routine which uses the DMA to transfer 256 bytes from 0x5000
; to 0x6000. This is to test the DMA peripheral.

memcpy:
                  ld hl, dma_configure_begin
                  call mass_io_helper

.dma_loop:        ld a, 0xBF                    ; read status byte
                  out (DMA), a
                  in a, (DMA)
                  bit 5, a
                  jr z, .dma_done
                  ld a, "#"
                  call echo
                  ld a, 0xB3
                  out (DMA), a
                  jr .dma_loop

.dma_done:        ld a, "W"
                  call echo

                  ld a, 0xC3                    ; reset
                  out (DMA), a
                  jp wozmon

dma_configure_begin:
                  .byte DMA
                  .byte .dma_conf_data_end - .dma_conf_data
.dma_conf_data:   .byte 0b01111101              ; transfer, A -> B
                  .byte 0x00                    ; start addr low
                  .byte 0x50                    ; start addr high (0x5000)
                  .byte 0x00                    ; len low
                  .byte 0x01                    ; len high (256)

                  .byte 0b00010100              ; A increments, is memory

                  .byte 0b00010000              ; B increments, is memory

                  .byte 0b11001101              ; burst mode
                  .byte 0x00                    ; end addr low
                  .byte 0x60                    ; end addr high (0x6000)

                  .byte 0b10000010              ; stop on end, CE only, ready active low

                  .byte 0xBB                    ; read mask
                  .byte 0b00000001              ; only status
                  .byte 0xCF                    ; load
                  .byte 0xB3                    ; force ready
                  .byte 0x87                    ; enable dma
.dma_conf_data_end:
                  .byte 0                       ; end of all
