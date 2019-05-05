# Zigspire

Programming with Zig on the TI-Nspire

## Setup

You need both [Zig](https://ziglang.org) installed somewhere and the
[Ndless SDK](https://github.com/ndless-nspire/Ndless/wiki/Ndless-SDK:-C-and-assembly-development-introduction).
Be aware that if you don't have the Ndless SDK built, it will take a very long
time to do so.

## Building

Run `zig build`. That's it! If you have
[Firebird](https://github.com/nspire-emus/firebird) installed, you can run
`zig build send` and it will send the built program to `/programs` or whatever
directory you define with `-Dsend-dir=/...` in your emulator's file system.

## License

This project is licensed under the MIT license. See the [LICENSE](LICENSE) file
for more details.
