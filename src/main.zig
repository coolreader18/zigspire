const std = @import("std");
const ndless = @import("ndless.zig");

fn maybeFree(memory: var) void {
    if (memory) |m| ndless.allocator.free(m);
}

export fn main() void {
    const name = ndless.showMsgUserInput("yo", "", "what's your name kid") orelse {
        ndless.showMsgbox("hey!", "you didn't tell me your name!");
        return;
    };
    const maybe_thing = ndless.showMsgUserInput("hey", "idk", "what's your thing, {}?", name);
    defer maybeFree(maybe_thing);
    if (maybe_thing) |thing| {
        ndless.showMsgbox("Hey!", "your thing is {}", thing);
    } else {
        ndless.showMsgbox("awww", "you have no thing");
    }
}
