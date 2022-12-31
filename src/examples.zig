const std = @import("std");
const Example = @import("examples/example.zig").Example;

pub const exampleList: []const []const u8 = &.{
    "main",
};

pub const examples = std.ComptimeStringMap(Example, .{
    .{ "main", @import("examples/main/main.zig").example },
});
