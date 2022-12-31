const std = @import("std");

const raylib = @import("../../raylib/raylib.zig");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const Graphics = @import("graphics.zig");
const TextureLoader = @import("textureloader.zig");
const Player = @import("player.zig");
const Main = @import("main.zig");
const Maze = @import("maze.zig");
const Wall = @import("wall.zig");

pub const Present = struct {
    rect: Rectangle,
    col: Color,
    isCollected: bool = false,
    fade: f32 = 0.0,

    pub fn spawnPresent() !void {
        var wasPlaced: bool = false;
        while (!wasPlaced) {
            const genX = raylib.GetRandomValue(0, Maze.maze.maze[0].len-2);
            const genY = raylib.GetRandomValue(0, Maze.maze.maze[0].len-2);
            const worldCoords = Maze.MazeType.mazeToWorld(Vector2 {.x=@intToFloat(f32, genX)+1, .y=@intToFloat(f32, genY)+1});
            // if this is a valid square
            if (Maze.maze.maze[@intCast(usize, genY)][@intCast(usize, genX)] == 0 and
                Maze.maze.maze[@intCast(usize, genY+1)][@intCast(usize, genX)] == 0 and
                Maze.maze.maze[@intCast(usize, genY)][@intCast(usize, genX+1)] == 0 and
                Maze.maze.maze[@intCast(usize, genY+1)][@intCast(usize, genX+1)] == 0 and
                Vector2.distanceTo(Player.player.rect.center(), worldCoords) > 700)
            {
                var isValid: bool = true;
                for (presents.items) |_, i| {
                    const presPos = Maze.MazeType.worldToMaze(presents.items[i].rect.pos());
                    if (@floatToInt(i32, presPos.x) == genX and @floatToInt(i32, presPos.y) == genY) {
                        isValid = false;
                        break;
                    }
                }
                if (!isValid) continue;
                wasPlaced = true;
                try presents.append(Present {
                    .rect = Rectangle {
                        .x= worldCoords.x-presentWidth/2,
                        .y= worldCoords.y-presentWidth/2,
                        .width= presentWidth,
                        .height= presentWidth,
                    },
                    .col = raylib.RED,
                });
            }

        }
    }

    pub fn createPresents() !void {
        var i: usize = 0;
        while (i < 40) : (i+=1) {
            try spawnPresent();
        }
    }

    pub fn update(this: *Present, index: usize) !void {
        if (this.isCollected) {
            this.fade+=0.1;
            if (this.fade > 1.0) {
                _ = presents.swapRemove(index);
                try spawnPresent();
            }
        } else {
            // check collision with player
            if (raylib.CheckCollisionRecs(this.rect, Player.player.rect)) {
                Main.score+=1;
                this.isCollected = true;
            }
        }
    }
    pub fn draw(this: Present) void {
        Graphics.drawTexturedRect3DTint(&TextureLoader.presentSideTexture, &TextureLoader.presentTopTexture, this.rect, Wall.Wall.calcTopRect(this.rect, 1.15), Color.lerp(raylib.WHITE, raylib.BLACK, this.fade));
    }
};

pub const presentWidth: f32 = 40;
pub var presents: std.ArrayList(Present) = undefined;