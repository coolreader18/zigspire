const std = @import("std");
const mem = std.mem;
const alloc = std.heap.c_allocator;
const fmt = std.fmt;
const c = @cImport({
    @cInclude("libndls.h");
});

fn countSize(size: *usize, bytes: []const u8) (error{}!void) {
    size.* += bytes.len;
}

fn append_null(s: []const u8) []const u8 {
    const buf = alloc.alloc(u8, s.len + 1) catch unreachable;
    mem.copy(u8, buf, s);
    buf[s.len] = '\x00';
    return buf;
}

fn format_to_cstr(comptime format: []const u8, args: ...) []const u8 {
    var size: usize = 1; // for the \0 at the end
    fmt.format(&size, error{}, countSize, format, args) catch |err| switch (err) {};
    const buf = alloc.alloc(u8, size) catch unreachable;
    _ = fmt.bufPrint(buf, format, args) catch |err| switch (err) {
        error.BufferTooSmall => unreachable, // we just counted the size above
    };
    buf[size - 1] = '\x00';
    return buf;
}

fn show_msgbox(title: []const u8, comptime format: []const u8, args: ...) void {
    const ctitle = append_null(title);
    defer alloc.free(ctitle);
    const msg = format_to_cstr(format, args);
    defer alloc.free(msg);

    _ = c._show_msgbox(ctitle.ptr, msg.ptr, 0);
}

fn show_msg_user_input(
    title: []const u8,
    default: []const u8,
    comptime msg_format: []const u8,
    args: ...,
) ?[]const u8 {
    const ctitle = append_null(title);
    defer alloc.free(ctitle);
    const cdefault = append_null(default);
    defer alloc.free(cdefault);
    const msg = format_to_cstr(msg_format, args);
    defer alloc.free(msg);

    var result = @intToPtr([*c]u8, 0);
    const len = c.show_msg_user_input(ctitle.ptr, msg.ptr, cdefault.ptr, &result);
    return if (len == -1) null else @ptrCast([*]u8, result)[0..@intCast(usize, len)];
}

fn maybeFree(memory: var) void {
    if (memory) |m| alloc.free(m);
}

inline fn bkpt() void {
    asm volatile (".long 0xE1212374");
}

export fn main() void {
    // std.debug.warn("aa\n");
    // std.debug.warn("Press any key to exit...\n");
    // c.wait_key_pressed();
    const name = show_msg_user_input("yo", "", "what's your name kid") orelse {
        show_msgbox("hey!", "you didn't tell me your name!");
        return;
    };
    const maybeThing = show_msg_user_input("hey", "", "what's your thing, {}?", name);
    defer maybeFree(maybeThing);
    // bkpt();
    if (maybeThing) |thing| {
        show_msgbox("Hey!", "your thing is {}", thing);
    } else {
        show_msgbox("awww", "you have no thing");
    }
}
