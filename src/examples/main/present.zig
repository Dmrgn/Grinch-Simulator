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

    pub fn createPresents() !void {
        for (Maze.maze.maze[0..Maze.maze.maze.len-2]) |_, i| {
            for (Maze.maze.maze[i][0..Maze.maze.maze[i].len-2]) |_, j| {
                // if this is a valid square
                if (Maze.maze.maze[i][j] == 0 and
                    Maze.maze.maze[i+1][j] == 0 and
                    Maze.maze.maze[i][j+1] == 0 and
                    Maze.maze.maze[i+1][j+1] == 0 and
                    raylib.GetRandomValue(0, 10) == 0)
                {
                    const worldCoords = Maze.MazeType.mazeToWorld(Vector2 {.x=@intToFloat(f32, j)+1, .y=@intToFloat(f32, i)+1});
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
    }

    pub fn update(this: *Present, index: usize) void {
        if (this.isCollected) {
            this.fade+=0.1;
            if (this.fade > 1.0) {
                _ = presents.swapRemove(index);
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