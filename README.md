
# ZOS

A Z80-family (almost) time-sharing operating system.

This operating system is created in 839 bytes of EEPROM space. A modified version of
[ZMon](https://github.com/QSmally/ZMon) (Wozmon for the Z80 and Z80-family of peripherals) is
included in the shell built-ins. Additionally, `memcpy` and `loader` are provided to copy blocks of
memory and to load files from the terminal, respectively.

ZOS runs on the system described in my [blog](https://blog.qsmally.org/posts/z80).

## Memory map

| start    | end      | type         | purpose                                     |
|----------|----------|--------------|---------------------------------------------|
| `0x0000` | `0x3FFF` | EEPROM (16k) | read-only kernel text space                 |
| `0x4000` | `0x4FFF` | SRAM (4k)    | global variables for kernel and application |
| `0x5000` | `0x6FFF` | SRAM (8k)    | application loaded from `loader`            |
| `0x7000` | `0xEFFF` | SRAM (32k)   | allocatable space                           |
| `0xF000` | `0xFFFF` | SRAM (4k)    | kernel stack, process stacks                |

## I/O map

| address | type      | purpose                               |
|---------|-----------|---------------------------------------|
| `0xE0`  | CTC (0-3) | pre-emptive timer, baudrate generator |
| `0xC0`  | SIO (A-B) | terminal                              |
| `0xA0`  | PIO (A-B) |                                       |
| `0x80`  | DMA       | general purpose, SIO `loader`         |
| `0x60`  | DMA 2     | general purpose                       |
| `0x40`  | I2C       | inter-computer network                |

## Contributing

I use [Vasm](http://www.compilers.de/vasm.html) oldstyle to assemble this project.

```bash
$ vasmZ80_oldstyle -Fbin -dotdir -esc zos.s
```

I use [Minipro](https://davidgriffith.gitlab.io/minipro/) for writing `a.out` to an EEPROM.

```bash
$ minipro -p W27C020 -s -w a.out
```
