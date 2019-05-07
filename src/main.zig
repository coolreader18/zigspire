const std = @import("std");
const c = @cImport({
    @cInclude("libndls.h");
});

export fn main() void {
    std.debug.warn("aa\n");
    std.debug.warn("Press any key to exit...\n");
    c.wait_key_pressed();
    _ = c._show_msgbox(c"Hey!", c"Hello, world!", 0);
}
