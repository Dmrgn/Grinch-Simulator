const std = @import("std");
const raylib = @import("../../raylib/raylib.zig");
const Vector2 = raylib.Vector2;

const basePieces = @import("pieces.zig").pieces;
var pieces: [basePieces.len][4][3][3]i32 = undefined;

// utility functions for creating random mazes
pub const Piece = struct {
    grid: [3][3]i32,

    pub fn init() Piece {
        return Piece {
            .grid= pieces[@intCast(usize, raylib.GetRandomValue(0, basePieces.len-1))][@intCast(usize, raylib.GetRandomValue(0, 3))],
        };
    }
    pub fn print(self: Piece) void {
        for (self.grid) |_, y| {
            for (self.grid[y]) |_, x| {
                std.debug.print("{}", .{self.grid[y][x]});
            }
            std.debug.print("\n", .{});
        }
    }

    // mirror the base pieces to get all possible variants
    pub fn createPieceVariants() void {
        for (pieces) |_, i| {
            const flipMap: [4][2]i32 = [4][2]i32{[2]i32{0, 0}, [2]i32{2, 0}, [2]i32{0, 2}, [2]i32{2, 2}};
            for (pieces[i]) |_, l| { // for each flipped varient (no flip, y flipped, x flipped, x and y flipped)
                for (pieces[i][l]) |_, j| { // for each y in the piece
                    for (pieces[i][l][j]) |_, k| { // for each x in the piece
                        pieces[i][l][k][j] = basePieces[i][@floatToInt(usize, @fabs(@intToFloat(f32, flipMap[l][0]-@intCast(i32, k))))][@floatToInt(usize, @fabs(@intToFloat(f32, flipMap[l][1]-@intCast(i32, j))))];
                    }
                }
            }
        }
    }
};