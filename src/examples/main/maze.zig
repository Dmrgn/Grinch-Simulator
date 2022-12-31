const std = @import("std");
const raylib = @import("../../raylib/raylib.zig");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const Player = @import("player.zig");
const Main = @import("main.zig");
const Pieces = @import("pieces.zig");
const Piece = @import("piece.zig").Piece;
const TextureLoader = @import("textureloader.zig");


// utility functions to generate a random maze
pub fn Maze(comptime width: i32, comptime height: i32) type {
    return struct {
        // reference to our own type
        const Self = Maze(width, height);
        
        grid: [height][width]i32,
        upscaled: [height*3][width*3]i32,
        maze: [height*3+4][width*3*2+4]i32,

        pub fn init() !Self {
            var m: Self = undefined;
            // init grid and maze to 0s
            for (m.grid) |_, i| {
                for (m.grid[i]) |_, j| {
                    m.grid[i][j] = 0;
                }
            }
            for (m.maze) |_, i| {
                for (m.maze[i]) |_, j| {
                    m.maze[i][j] = 0;
                }
            }
            // create base maze
            var count:i32 = 1;
            while (count<10) : (count+=1) {
                const p: Piece = Piece.init();
                _ = try m.placePiece(p, count, @intCast(usize, @mod(count, height/3)));
            }
            // add center room
            const roomWidth: i32 = 2;
            const roomHeight: i32 = 3;
            for (m.grid[0..roomHeight]) |_, i| {
                for (m.grid[i][0..roomWidth]) |_, j| {
                    // set to 1
                    m.grid[m.grid.len/2-roomHeight/2+i][@intCast(usize, width)-j-1] = 1;
                }
            }
            m.upscaleGrid();
            // add center room
            for (m.upscaled[0..roomHeight*3-4]) |_, i| {
                for (m.upscaled[i][0..roomWidth*3-1]) |_, j| {
                    m.upscaled[m.upscaled.len/2-roomHeight*3/2+i+2][m.upscaled.len/2-roomWidth*3/2+j+2] = 0;
                }
            }
            // copy upscaled grid to maze
            for (m.upscaled) |_, i| {
                for (m.upscaled[i]) |_, j| {
                    m.maze[i+2][j+2] = m.upscaled[i][j];
                }
            }
            for (m.upscaled) |_, i| {
                for (m.upscaled[i]) |_, j| {
                    m.maze[i+2][@intCast(usize, width*3)+j+1] = m.upscaled[i][@intCast(usize, width*3)-j];
                }
            }
            // add border
            for (m.maze) |_, i| { // left and right
                m.maze[i][0] = 1;
                m.maze[i][width*3*2+3] = 1;
            }
            for (m.maze[0]) |_, i| { // top and bottom
                m.maze[0][i] = 1;
                m.maze[height*3+3][i] = 1;
            }
            // // add holes for moving between mazes
            // for (m.maze[0..2]) |_, i| {
            //     m.maze[@intCast(usize, (height*3+3)/2)+i+1][0] = 0;
            //     m.maze[@intCast(usize,(height*3+3)/2)+i+1][width*3*2+3] = 0;
            // }
            // print for debug
            Self.print(width*3, height*3, m.upscaled);
            Self.print(width*3*2+4, height*3+4, m.maze);
            return m;
        }
        pub fn print(comptime w: usize, comptime h: usize, arr:[h][w]i32) void {
            for (arr) |_, y| {
                for (arr[y]) |_, x| {
                    std.debug.print("{}", .{arr[y][x]});
                }
                std.debug.print("\n", .{});
            }
        }
        pub fn maskArr(comptime w: usize, comptime h: usize, arr:*[h][w]i32, mask:[h][w]i32) void {
            for (mask) |_, l| {
                for (mask[l]) |_, m| {
                    arr[l][m] *= mask[l][m];
                }
            }
        }
        // convert maze x,y to world x,y coords
        pub fn mazeToWorld(mazeCoords: Vector2) Vector2 {
            return Vector2 {
                .x=@intToFloat(f32, -mazeWidth/2)+mazeCoords.x*@intToFloat(f32, blockSize)+@intToFloat(f32, Main.screenWidth/2),
                .y=@intToFloat(f32, -mazeHeight/2)+mazeCoords.y*@intToFloat(f32, blockSize)+@intToFloat(f32, Main.screenHeight/2)
            };
        }
        // convert maze x,y to world x,y coords
        pub fn worldToMaze(worldCoords: Vector2) Vector2 {
            return Vector2 {
                .x=@floor((worldCoords.x-@intToFloat(f32, Main.screenWidth/2)-@intToFloat(f32, -mazeWidth/2))/@intToFloat(f32, blockSize)),
                .y=@floor((worldCoords.y-@intToFloat(f32, Main.screenHeight/2)-@intToFloat(f32, -mazeHeight/2))/@intToFloat(f32, blockSize))
            };
        }
        // upscale the current grid into a map
        pub fn upscaleGrid(this: *Self) void {
            for (this.grid) |_, i| { // for each row
                for (this.grid[i]) |_, j| { // for each column
                    // starting block which is unmasked
                    var block = [3][3]i32{
                        [3]i32{1, 1, 1},
                        [3]i32{1, 1, 1},
                        [3]i32{1, 1, 1},
                    };
                    // apply block masks to include paths
                    // for each possible direction
                    for (Pieces.dirs) |_, k| {
                        // check if that edge is a path
                        const otherX: i32 = @intCast(i32, j)+Pieces.dirs[k][0]; // x of the tile in the current direction
                        const otherY: i32 = @intCast(i32, i)+Pieces.dirs[k][1]; // y of ^
                        // check if the other tile exists or is a wall
                        if (otherX < 0 or otherX >= width or otherY < 0 or otherY >= height) {
                            // mask block with the current direction's specified mask
                            maskArr(3, 3, &block, Pieces.dirMasks[k]);
                            continue;
                        }
                        // if the tile exists then check if it should mask
                        // it should mask if the other tile is from a different piece
                        if (this.grid[i][j] != this.grid[@intCast(usize, otherY)][@intCast(usize, otherX)]) {
                            maskArr(3, 3, &block, Pieces.dirMasks[k]);
                        }
                    }
                    // copy block to upscaled grid
                    for (block) |_, k| { // for each row
                        for (block[k]) |_, l| { // for each column
                            this.upscaled[3*i + k][3*j + l] = block[k][l];
                        }
                    }
                }
            }
        }
        // place a tetromino on the board randomly
        // returns true if the piece was placed
        // and false otherwise (no space etc..)
        pub fn placePiece(this: *Self, piece: Piece, id: i32, y: usize) !bool {
            // start all the way on the right
            var x: i32 = @intCast(usize, width); // x needs to be i32 because it should be able to be negetive (off the board to the left)
            // move to the left until we touch the edge or an already set tile
            outer: while (true) {
                x-=1; // move the piece to the left
                // check collision with row
                for (piece.grid) |_, k| { // for each row
                    for (piece.grid[0]) |_, l| { // for each x in this row
                        const pieceTileX: i32 = @intCast(i32, l)+x; // should be able to be negetive (off the board to the left)
                        const pieceTileY: usize = k+y*3;
                        if (pieceTileX >= width) { // if this tile of this piece is still off the grid
                            break;
                        }
                        if (piece.grid[k][l] == 1) {
                            // std.debug.print("========", .{});
                            // std.debug.print("pos: x:{} y:{}\n", .{pieceTileX, pieceTileY});
                            // if this tile of this piece is off the board to the left 
                            if (pieceTileX < 0) {
                                break :outer;
                            }
                            // if touching an existing tile of a piece
                            if (this.grid[pieceTileY][@intCast(usize, pieceTileX)] != 0) {
                                // std.debug.print("hit:{}:{}\n", .{this.grid[pieceTileY][@intCast(usize, pieceTileX)], @intCast(usize, pieceTileX)});
                                break :outer;
                            }
                        }
                    }
                }
            }
            // move right 1 so we are no longer colliding
            x+=1;
            // if x == width then the tile collided
            // before entering the board and cannot
            // be placed
            if (x == width) {
                return false;
            }
            // update all the grid tiles the piece is touching
            for (piece.grid) |_, i| {
                for (piece.grid[y]) |_, j| {
                    if (piece.grid[i][j] == 1) {
                        const pieceTileX: usize = j+@intCast(usize, x); // at this point, x cannot be negative
                        const pieceTileY: usize = i+y*3;
                        this.grid[pieceTileY][pieceTileX] = id;
                    }
                }
            }
            // tile placed sucessfully
            return true;
        }
    };
}

// mazes are cool
// you might even call them aMAZEing
pub const mazeTypeWidth: usize = 5;
pub const mazeTypeHeight: usize = 9;
pub const mazeCellWidth: usize = mazeTypeWidth*3*2+4;
pub const mazeCellHeight: usize = mazeTypeHeight*3+4;
pub const MazeType: type = Maze(mazeTypeWidth, mazeTypeHeight);
pub var maze: MazeType = undefined;
pub const blockSize: i32 = 150;
pub const mazeWidth: i32 = blockSize*mazeCellWidth;
pub const mazeHeight: i32 = blockSize*mazeCellHeight;