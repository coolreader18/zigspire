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

fn show_msgbox(title: []const u8, comptime format: []const u8, args: ...) void {
    var size: usize = 1; // for the \0 at the end
    fmt.format(&size, error{}, countSize, format, args) catch |err| switch (err) {};
    const buf = alloc.alloc(u8, size) catch unreachable;
    defer alloc.free(buf);
    _ = fmt.bufPrint(buf, format, args) catch |err| switch (err) {
        error.BufferTooSmall => unreachable, // we just counted the size above
    };
    buf[size - 1] = '\x00';
    _ = c._show_msgbox(title.ptr, buf.ptr, 0);
}

fn append_null(s: []const u8) []const u8 {
    return mem.join(alloc, "", [][]const u8{ s, "\x00" }) catch unreachable;
}

fn show_msg_user_input(title: []const u8, msg: []const u8, default: []const u8) ?[]const u8 {
    const ctitle = append_null(title);
    defer alloc.free(ctitle);
    const cmsg = append_null(msg);
    defer alloc.free(cmsg);
    const cdefault = append_null(default);
    defer alloc.free(cdefault);

    var result = @intToPtr([*c]u8, 0);
    const len = c.show_msg_user_input(ctitle.ptr, cmsg.ptr, cdefault.ptr, &result);
    return if (len == -1) null else @ptrCast([*]u8, result)[0..@intCast(usize, len)];
}

fn maybeFree(memory: var) void {
    if (memory) |m| alloc.free(m);
}

export fn main() void {
    // std.debug.warn("aa\n");
    // std.debug.warn("Press any key to exit...\n");
    // c.wait_key_pressed();
    const maybeThing = show_msg_user_input("hey", "what's your thing", "");
    defer maybeFree(maybeThing);

    if (maybeThing) |thing| show_msgbox("Hey!", "your thing is {}", thing)
    else show_msgbox("awww", "you have no thing");
}
