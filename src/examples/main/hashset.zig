const std = @import("std");

const Main = @import("main.zig");

pub fn HashSet(comptime T: type) type {
    return struct {
        map: std.AutoHashMap(T, bool),

        pub fn init(alloc: std.mem.Allocator) HashSet(T) {
            return HashSet(T) {
                .map= std.AutoHashMap(T, bool).init(alloc),
            };
        }
        pub fn deinit(this: *HashSet(T)) void {
            this.map.deinit();
        }
        pub fn put(this: *HashSet(T), key: T) !void {
            try this.map.putNoClobber(key, true);
        }
        pub fn remove(this: *HashSet(T), key: T) void {
            _ = this.map.remove(key);
        }
        pub fn contains(this: *HashSet(T), key: T) bool {
            return this.map.contains(key);
        }
        pub fn len(this: *HashSet(T)) usize {
            return this.map.count();
        }
    };
}