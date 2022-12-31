const std = @import("std");

const raylib = @import("../../raylib/raylib.zig");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const Player = @import("player.zig");
const TextureLoader = @import("textureloader.zig");
const Graphics = @import("graphics.zig");
const Light = @import("light.zig");
const Main = @import("main.zig");
const Maze = @import("maze.zig");
const Sound = @import("sound.zig");
const PathFinder = @import("pathfinder.zig");

const drag: f32 = 0.8;
const maxLaughCoolDown = 120;

const farLockRange: f32 = 1250;     // if the player is past this number then lock onto them
const closeLockRange: f32 = 700;    // if the player is within this number then lock onto them
const jumpScareRange: f32 = 100;    // if the player is within this range then may only god help them
                                    // otherwise wander

pub const Enemy = struct {
    rect: Rectangle,
    vel: Vector2,
    framesUntilNewPath: i32 = 0,
    nextPathPosition: ?Vector2 = null,
    currentPath: ?std.ArrayList(Vector2) = null,
    chaseAmount: f32 = 0.0,
    laughCoolDown: i32 = maxLaughCoolDown,

    pub fn init() Enemy {
        const worldCoords: Vector2 = Maze.MazeType.mazeToWorld(Vector2 {.x=1.5, .y=1.5});
        return Enemy {
            .rect = Rectangle {
                .x= worldCoords.x,
                .y= worldCoords.y,
                .width= 30,
                .height= 30
            },
            .vel = Vector2.zero(),
        };
    }

    pub fn update(this: *Enemy) !void {
        // direction we need to travel
        var dir: Vector2 = undefined;
        const distanceToPlayer: f32 = Vector2.distanceTo(Player.player.rect.center(), this.rect.center());
        // update heart beat based on closeness
        Player.player.heartBeatRate = std.math.max(@floatToInt(i32, std.math.min((distanceToPlayer/farLockRange), 1.0)*@intToFloat(f32, Player.maxHeartBeatRate)), 20);
        // lerp chase sound according to distance
        if (distanceToPlayer < closeLockRange) {
            this.chaseAmount = std.math.min(1.5-(distanceToPlayer/(closeLockRange*0.7)), 1.0);
            raylib.SetMusicVolume(Sound.chaseMusic, this.chaseAmount);
            // laugh randomly when close
            if (this.laughCoolDown > 0)
                this.laughCoolDown -= 1;
            if (this.laughCoolDown == 0 and raylib.GetRandomValue(0, 60) == 0) {
                raylib.PlaySound(Sound.laughs[@intCast(usize, raylib.GetRandomValue(0, Sound.laughs.len-1))]);
                this.laughCoolDown = maxLaughCoolDown;
            }
        } else {
            this.chaseAmount = raylib.Lerp(this.chaseAmount, 0.0, 0.1);
            raylib.SetMusicVolume(Sound.chaseMusic, this.chaseAmount);
        }
        // if we are close enough, overwrite the path and move towards player
        if (distanceToPlayer < jumpScareRange) {
            Light.intensity = raylib.Lerp(Light.intensity, 0.0, 0.05);
            dir = Vector2.sub(Player.player.rect.center(), this.rect.center()).normalize();
            if (distanceToPlayer < jumpScareRange/2) {
                Main.startJumpScare(); // oh god no
            }
        } else {
            // update pathing type
            if (this.framesUntilNewPath == 0 or this.currentPath == null) {
                var endPos: Vector2 = undefined;
                if (distanceToPlayer > farLockRange or distanceToPlayer < closeLockRange) {
                    // lock to player
                    endPos = Maze.MazeType.worldToMaze(Player.player.rect.center());
                    this.framesUntilNewPath = 60;
                } else {
                    // wander
                    endPos = Vector2 {.x=@intToFloat(f32, raylib.GetRandomValue(0, Maze.mazeCellWidth-1)), .y=@intToFloat(f32, raylib.GetRandomValue(0, Maze.mazeCellHeight-1))};
                    while (Maze.maze.maze[@floatToInt(usize, endPos.y)][@floatToInt(usize, endPos.x)] != 0) {
                        endPos = Vector2 {.x=@intToFloat(f32, raylib.GetRandomValue(0, Maze.mazeCellWidth-1)), .y=@intToFloat(f32, raylib.GetRandomValue(0, Maze.mazeCellHeight-1))};
                    }
                    this.framesUntilNewPath = 180;
                }
                const enemyMazePos: Vector2 = Maze.MazeType.worldToMaze(this.rect.center());
                this.currentPath = try PathFinder.pathFind(enemyMazePos, endPos, Maze.mazeCellWidth, Maze.mazeCellHeight, Maze.maze.maze);
                if (this.currentPath == null) {
                    std.debug.print("path not found hmmm...\n", .{});
                }
            }
            // select new tile to path to if we need to
            if (this.nextPathPosition == null) {
                this.nextPathPosition = this.currentPath.?.pop();
                // if there are no items left then set it to null
                // so that we know to recalculate next frame
                if (this.currentPath.?.items.len == 0) {
                    this.currentPath.?.deinit();
                    this.currentPath = null;
                }
            }
            // calculate direction to next tile in path
            const worldNextPathPosition: Vector2 = Maze.MazeType.mazeToWorld(this.nextPathPosition.?.add(Vector2 {.x= 0.5, .y=0.5}));
            dir = Vector2.sub(worldNextPathPosition, this.rect.center()).normalize();
            // if we are close enough to the current tile in our path
            // then move onto the next one
            if (Vector2.distanceTo(this.rect.center(), worldNextPathPosition) < 20) {
                // mark null so we know to get a new one next frame
                this.nextPathPosition = null;
            }
        }

        this.vel = Vector2.add(this.vel, dir.scale(enemySpeed));
        this.vel = Vector2.scale(this.vel, drag);
        if (this.vel.length() < 0.5) this.vel = Vector2.zero(); 

        this.rect.x += this.vel.x;
        this.rect.y += this.vel.y;


        // update frames until we recalculate the path
        this.framesUntilNewPath-=1;
    }
    pub fn draw(this: Enemy) void {
        const drawWidth = 200;
        // const scaleAmount = @intToFloat(f32, drawWidth)/32.0;
        const enemySrcRect = Rectangle {
            .x= 0,
            .y= 0,
            .width= 32,
            .height= 32,
        };
        const enemyDestRect = Rectangle {
            .x= this.rect.pos().x,
            .y= this.rect.pos().y,
            .width= drawWidth,
            .height= drawWidth,
        };
        const dirToPlayer: f32 = (Vector2.sub(Player.player.rect.center(), this.rect.center()).angle()/raylib.PI)*180;
        raylib.DrawTexturePro(TextureLoader.enemyTexture, enemySrcRect, enemyDestRect, enemySrcRect.size(), dirToPlayer-90, raylib.WHITE);
    }
};

pub var enemy: Enemy = undefined;
pub const enemySpeed: f32 = 1.5;