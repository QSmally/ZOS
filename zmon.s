
; This file is part of ZOS. © Joey Smalen

; depends on interpret, echo_hex_byte, echo, echo_newline

; Steve Wozniak's wozmon ported to the Z80, using the Z80-family of peripherals.
; Monitor runs in EEPROM (16k) from address 0x0000.
; Input buffer is placed at 0x4000 - 0x407F, with one extra RAM variable needed.
; The stack is initialised to the top of RAM (48k), 0xFFFF.
;
; Assembled using Vasm oldstyle [http://www.compilers.de/vasm.html].
;
; © 2025 Joey Smalen

; b = mode
; c = temporary
; de = incoming data/addr (range)
; hl = store iterator addr
; ix = text addr for analysis
; iy = xam iterator addr

; 0x4000 - 0x407F = buffer
; 0x4080 - 0x4081 = text addr copy

wozmon:
                  ld a, 0x1B                    ; begin with escape
.not_return:      cp 0x08                       ; is backspace?
                  jr z, .backspace
                  cp 0x1B                       ; is escape?
                  jr z, .escape
                  inc l                         ; advance text index
                  jp p, .next_char              ; next char only if no overflow

.escape:          ld a, "\\"
                  call echo                     ; print "\"

.newline:         call echo_newline             ; print newline
                  ld hl, 0x4001                 ; h = 0x40, l = offset

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

                  ld ix, 0x3FFF                 ; init text index to 0x4000
                  ld a, 0                       ; XAM mode

.set_block:       sla a
.set_store:       sla a
                  ld b, a                       ; 0 xam, 74 store, b8 blok xam

.skip_item:       inc ix                        ; advance text index
.next_item:       ld a, (ix)                    ; load character
                  cp 0x0D                       ; is return?
                  jr z, .newline
                  cp "."                        ; is dot?
                  jp m, .skip_item
                  jr z, .set_block
                  cp ":"                        ; is colon?
                  jr z, .set_store
                  cp "R"                        ; is "R"?
                  jr z, .run
                  ld de, 0                      ; data = 0
                  ld (0x4080), ix               ; store ix for later

.next_hex:        ld a, (ix)                    ; load character
                  call interpret                ; shift into reg de
                  jp m, .exec                   ; not hex, done
                  inc ix                        ; advance text index
                  jr .next_hex

.exec:            ld c, ixl
                  ld a, (0x4080)
                  cp c
                  jr z, .escape                 ; escape if no hex characters

                  bit 6, b                      ; is (block) xam?
                  jr z, .xam

                  ld (hl), e                    ; store low digit at store addr
                  inc hl                        ; increment store addr
                  jr .next_item

.run:
                  jp (iy)                       ; run xam

.xam:
                  bit 7, b                      ; is block xam?
                  jr nz, .xam_next              ; yes, skip addr print

                  push de                       ; copy addr to store addr
                  pop hl                        ; (just a tiny hack)
                  push de                       ; copy addr to xam addr
                  pop iy                        ; (just a tiny hack)

.praddr:          ld a, 0x0D
                  call echo                     ; print newline
                  ld a, iyh
                  call echo_hex_byte            ; print xam upper
                  ld a, iyl
                  call echo_hex_byte            ; print xam lower
                  ld a, ":"
                  call echo                     ; print colon

.prdata:          ld a, " "
                  call echo                     ; print space
                  ld a, (iy)                    ; load xam index
                  call echo_hex_byte
.xam_next:        ld b, 0                       ; mode = 0 (xam)
                  ld a, iyl
                  cp e
                  ld a, iyh
                  sbc d                         ; compare xam with range end
                  jr nc, .next_item             ; done? next item

                  inc iy                        ; next xam index

                  ld a, iyl
                  and 0x07                      ; is xam mod of 8?
                  jr z, .praddr                 ; yes, also print address
                  jr .prdata                    ; no, only print data
