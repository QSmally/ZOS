
# ZOS

A Z80-family operating system.

Wozmon (written by Steve Wozniak in 1976) for the Z80 and Z80-family of peripherals is used as
entrypoint to the operating system. It is a modified version of [ZMon](https://github.com/QSmally/ZMon).

## Contributing

I use [Vasm](http://www.compilers.de/vasm.html) oldstyle to assemble this project.

```bash
$ vasmZ80_oldstyle -Fbin -dotdir zos.s
```

I use [Minipro](https://davidgriffith.gitlab.io/minipro/) for writing `a.out` to an EEPROM.

```bash
$ minipro -p W27C020 -s -w a.out
```
