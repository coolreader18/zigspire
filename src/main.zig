const c = @cImport({
    @cInclude("libndls.h");
});

export fn main() void {
    _ = c._show_msgbox(c"Hey!", c"Hello, world!", 0);
}
