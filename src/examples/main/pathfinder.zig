const std = @import("std");
const raylib = @import("../../raylib/raylib.zig");

const Vector2 = raylib.Vector2;

const HashSet = @import("hashset.zig").HashSet;
const Main = @import("main.zig");

const Cell = struct {
    pos: CellPos,
    previous: usize = undefined,
    index: usize = undefined,
};

// hashset shouldnt track previous cell
const CellPos = struct {
    x: usize,
    y: usize,
};

// find a path from start to end in graph map
// it is the callers responsibility to free the returned arraylist
// returns null if no path is found
pub fn pathFind(start: Vector2, end: Vector2, comptime width: usize, comptime height: usize, map: [height][width]i32) !?std.ArrayList(Vector2) {
    // list of all created cells for reference
    var referenceList: std.ArrayList(Cell) = std.ArrayList(Cell).init(Main.alloc);
    defer referenceList.deinit();
    // list of cells to visit
    var toVisit: std.ArrayList(usize) = std.ArrayList(usize).init(Main.alloc);
    defer toVisit.deinit();
    // list of visited positions 
    var visited: HashSet(CellPos) = HashSet(CellPos).init(Main.alloc);
    defer visited.deinit();

    // if we are already there, return null
    if (start.x == end.x and start.y == end.y) return null;

    // set the ending cell
    const endCell: Cell = Cell {
        .pos = CellPos {
            .x = @floatToInt(usize, end.x),
            .y = @floatToInt(usize, end.y),
        },
    };
    // set first cell
    const startCell: Cell = Cell {
        .pos = CellPos {
            .x = @floatToInt(usize, start.x),
            .y = @floatToInt(usize, start.y),
        },
        .index = 0
    };
    try referenceList.append(startCell);
    try visited.put(startCell.pos);
    try toVisit.append(0);

    var ds: usize = 0;
    // while there are cells to visit
    while (toVisit.items.len > 0 and ds < 1000) : (ds+=1) {
        // std.debug.print("=======\n", .{});
        // pop the current cell
        var current: usize = toVisit.pop();

        // draw visited to console
        var tempMap: [height][width]i32 = undefined;
        for (tempMap) |_, i| {
            for (tempMap[i]) |_, j| {
                tempMap[i][j] = 0;
            }
        }

        // var itr = visited.map.keyIterator();
        // var cur: CellPos = itr.next().?.*;
        // while (itr.len > 0) : (cur = itr.next().?.*) {
        //     tempMap[cur.y][cur.x] = 1;
        // }
        // for (tempMap) |_, i| {
        //     for (tempMap[i]) |_, j| {
        //         std.debug.print("{s}", .{if (tempMap[i][j] == 0) "0" else "1"});
        //     }
        //     std.debug.print("\n", .{});
        // }
        // std.debug.print("ds:{} num:{}\n", .{ds, toVisit.items.len});
        
        // check if this is the ending cell
        if (referenceList.items[current].pos.x == endCell.pos.x and referenceList.items[current].pos.y == endCell.pos.y) {
            // build path from previous cells
            var path: std.ArrayList(Vector2) = std.ArrayList(Vector2).init(Main.alloc);
            // the current cell to append to the path
            var currentAppend: Cell = referenceList.items[current];
            // while this is not the starting cell
            while (!(currentAppend.pos.x == startCell.pos.x and currentAppend.pos.y == startCell.pos.y)) {
                try path.append(Vector2 {
                    .x=@intToFloat(f32, currentAppend.pos.x),
                    .y=@intToFloat(f32, currentAppend.pos.y),
                });
                currentAppend = referenceList.items[currentAppend.previous];
            }

            return path;
        } 

        // append all open neighbours cells to the tovisit list
        const dirs = [4][2]i32{
            [2]i32 {-1, 0},
            [2]i32 {0, -1},
            [2]i32 {1, 0},
            [2]i32 {0, 1},
        };
        for (dirs) |_, i| {
            const neighbourX: i32 = dirs[i][0]+@intCast(i32, referenceList.items[current].pos.x);
            const neighbourY: i32 = dirs[i][1]+@intCast(i32, referenceList.items[current].pos.y);
            // if this neighbour is in the grid
            if (neighbourX > 0 and neighbourX < width and neighbourY > 0 and neighbourY < height) {
                const neighbourCell = Cell {
                    .pos = CellPos {
                        .x = @intCast(usize, neighbourX),
                        .y = @intCast(usize, neighbourY),
                    },
                    .index = referenceList.items.len-1,
                };
                // std.debug.print("candidate:{}:{}\n", .{neighbourCell.pos.x, neighbourCell.pos.y});
                // if this neighbour is an open space and hasnt been visited before
                if (map[@intCast(usize, neighbourY)][@intCast(usize, neighbourX)] == 0 and !visited.contains(neighbourCell.pos)) {
                    // std.debug.print("test:added\n",.{});
                    // append neighbour to tovisit
                    try referenceList.append(neighbourCell);
                    referenceList.items[referenceList.items.len-1].previous = current;
                    try visited.put(neighbourCell.pos);
                    try toVisit.insert(0, referenceList.items.len-1);
                }
            }
        }       
    }

    // no path was found
    return null;
}