const std = @import("std");
const Builder = std.build.Builder;
const os = std.os;
const path = os.path;
const builtin = @import("builtin");

const CACHE_DIR = "./zig-cache/";

const MAIN_PROGRAM = "src/main.zig";

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    const main = b.addObject(
        "zigspire",
        b.option(
            []const u8,
            "exe",
            "The program to build. Default " ++ MAIN_PROGRAM,
        ) orelse MAIN_PROGRAM,
    );
    main.setBuildMode(mode);
    main.setTarget(
        builtin.Arch{
            .arm = builtin.Arch.Arm32.v4t,
        },
        builtin.Os.nspire,
        builtin.Abi.gnueabi,
    );
    main.linkSystemLibrary("c");
    main.single_threaded = true;

    const ndless_dir = path.dirname(path.dirname(try path.real(try b.exec([][]const u8{
        "which", "nspire-gcc",
    }))) orelse unreachable) orelse unreachable;
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

    const nspireio = if (b.option(
        bool,
        "nspireio",
        "Whether to build with nspireio or not",
    ) orelse false) "-Wl,--nspireio" else "-U________";
    const link_main_step = b.addSystemCommand([][]const u8{
        "nspire-ld", "-o", CACHE_DIR ++ "main", "-Wl,--gc-sections", nspireio,
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
        "firebird-send", CACHE_DIR ++ "zigspire.prg.tns", b.option(
            []const u8,
            "send-dir",
            "The directory in Firebird to send the program to. Default /programs",
        ) orelse "/programs",
    });
    firebird_send_step.step.dependOn(&make_prg_step.step);

    const send_step = b.step("send", "Send to firebird emu");
    send_step.dependOn(&firebird_send_step.step);

    b.default_step.dependOn(prg_step);
}
