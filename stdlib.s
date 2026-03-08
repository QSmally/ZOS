
; This file is part of ZOS. © Joey Smalen

; returns nz if found, z if not found. hl is restored. ix points to addr.
;
; ix = address to map format:
;     .asciiz "anything"
;     .word addr
;     .asciiz "goes"
;     .word addr
;     .byte 0 (end of map)
; hl = string to compare with
;
; clobbers a, flags, ix

_map_find_entry:  ld a, (ix)
                  inc ix                        ; no flags changed
                  or 0                          ; is zero?
                  jr nz, _map_find_entry        ; no, continue walk to end
                  inc ix
                  inc ix                        ; ix points to the next entry
                  pop hl                        ; peek original hl
map_find:         push hl                       ; save hl
                  ld a, (ix)
                  or 0                          ; is map string zero?
                  jr z, .not_found              ; yes, end of map; not found
                  call streq                    ; are the two strings equal?
                  jr nz, _map_find_entry        ; next if not equal
                  inc ix                        ; ix points to addr
                  or 1                          ; set nz because found
.not_found:       pop hl
                  ret                           ; z if not found, nz if found

; string equals. returns z if equal, nz if not equal.
;
; ix = string 1
; hl = string 2
;
; clobbers a, flags, ix, hl

streq:
                  ld a, (hl)                    ; a = char 1
                  cp (ix)                       ; compare with char 2
                  ret nz                        ; return (nz) if not equal
                  or 0
                  ret z                         ; return (z) if both were zero
                  inc hl
                  inc ix
                  jr streq                      ; loop
