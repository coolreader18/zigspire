const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
pub const allocator = std.heap.c_allocator;
pub const c = @cImport({
    @cInclude("libndls.h");
});

fn countSize(size: *usize, bytes: []const u8) (error{}!void) {
    size.* += bytes.len;
}

fn appendNull(s: []const u8) []const u8 {
    const buf = allocator.alloc(u8, s.len + 1) catch unreachable;
    mem.copy(u8, buf, s);
    buf[s.len] = '\x00';
    return buf;
}

fn formatToCstr(comptime format: []const u8, args: ...) []const u8 {
    var size: usize = 1; // for the \0 at the end
    fmt.format(&size, error{}, countSize, format, args) catch |err| switch (err) {};
    const buf = allocator.alloc(u8, size) catch unreachable;
    _ = fmt.bufPrint(buf, format, args) catch |err| switch (err) {
        error.BufferTooSmall => unreachable, // we just counted the size above
    };
    buf[size - 1] = '\x00';
    return buf;
}

pub fn showMsgbox(title: []const u8, comptime format: []const u8, args: ...) void {
    const ctitle = appendNull(title);
    defer allocator.free(ctitle);
    const msg = formatToCstr(format, args);
    defer allocator.free(msg);

    _ = c._show_msgbox(ctitle.ptr, msg.ptr, 0);
}

pub fn showMsgUserInput(
    title: []const u8,
    default: []const u8,
    comptime msg_format: []const u8,
    args: ...,
) ?[]const u8 {
    const ctitle = appendNull(title);
    defer allocator.free(ctitle);
    const cdefault = appendNull(default);
    defer allocator.free(cdefault);
    const msg = formatToCstr(msg_format, args);
    defer allocator.free(msg);

    var result = @intToPtr([*c]u8, 0);
    const len = c.show_msg_user_input(ctitle.ptr, msg.ptr, cdefault.ptr, &result);
    return if (len == -1) null else @ptrCast([*]u8, result)[0..@intCast(usize, len)];
}

pub inline fn bkpt() void {
    asm volatile (".long 0xE1212374");
}
