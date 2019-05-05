const std = @import("std");
const Builder = std.build.Builder;
const os = std.os;
const builtin = @import("builtin");

const CACHE_DIR = "./zig-cache/";

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    const main = b.addObject("zigspire", "src/main.zig");
    main.setBuildMode(mode);
    main.setTarget(
        builtin.Arch{
            .arm = builtin.Arch.Arm32.v5,
        },
        builtin.Os.freestanding,
        builtin.Abi.gnueabi,
    );

    const dirname = os.path.dirname;
    const ndless_dir = dirname(dirname(try b.exec([][]const u8{
        "which", "nspire-gcc",
    })) orelse unreachable) orelse unreachable;
    main.addIncludeDir(try os.path.join(b.allocator, [][]const u8{
        ndless_dir,
        "toolchain/install/bin/lib/gcc/arm-none-eabi/8.2.0/include",
    }));
    main.addIncludeDir(try os.path.join(b.allocator, [][]const u8{
        ndless_dir,
        "toolchain/install/lib/gcc/arm-none-eabi/8.2.0/include-fixed",
    }));
    main.addIncludeDir(try os.path.join(b.allocator, [][]const u8{
        ndless_dir,
        "toolchain/install/arm-none-eabi/sys-include",
    }));
    main.addIncludeDir(try os.path.join(b.allocator, [][]const u8{
        ndless_dir,
        "toolchain/install/arm-none-eabi/include",
    }));
    main.addIncludeDir(try os.path.join(b.allocator, [][]const u8{
        ndless_dir,
        "include",
    }));

    const link_main_step = b.addSystemCommand([][]const u8{
        "nspire-ld", "-o", CACHE_DIR ++ "main", "-Wl,--gc-sections",
    });
    link_main_step.addArtifactArg(main);
    link_main_step.step.dependOn(&main.step);

    const genzehn_step = b.addSystemCommand([][]const u8{"genzehn"});
    genzehn_step.addArgs([][]const u8{
        "--input",           CACHE_DIR ++ "main",
        "--output",          CACHE_DIR ++ "zigspire.tns",
        "--240x320-support", "true",
        "--uses-lcd-blit",   "true",
    });
    genzehn_step.step.dependOn(&link_main_step.step);

    const make_prg_step = b.addSystemCommand([][]const u8{
        "make-prg", CACHE_DIR ++ "zigspire.tns", CACHE_DIR ++ "zigspire.prg.tns",
    });
    make_prg_step.step.dependOn(&genzehn_step.step);

    const prg_step = b.step("prg", "Build a genzehn program");
    prg_step.dependOn(&make_prg_step.step);

    const firebird_send_step = b.addSystemCommand([][]const u8{
        "firebird-send", CACHE_DIR ++ "zigspire.prg.tns", "/programs",
    });
    firebird_send_step.step.dependOn(&make_prg_step.step);

    const send_step = b.step("send", "Send to firebird emu");
    send_step.dependOn(&firebird_send_step.step);

    b.default_step.dependOn(prg_step);
}
