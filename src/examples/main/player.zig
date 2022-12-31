const std = @import("std");

const raylib = @import("../../raylib/raylib.zig");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;

const Wall = @import("wall.zig");
const Sound = @import("sound.zig");
const Main = @import("main.zig");
const Light = @import("light.zig");
const TextureLoader = @import("textureloader.zig");

pub const playerWidth = 20;
pub const playerSpeed: f32 = 0.38;
pub const playerSprintSpeed: f32 = 1.0;
pub const exhaustionCoolDown: i32 = 120;
pub const maxHeartBeatRate: i32 = 120;
const drag = 0.9;

const screenWidth = @import("main.zig").screenWidth;
const screenHeight = @import("main.zig").screenHeight;

pub const Player = struct {
    rect: Rectangle,
    vel: Vector2,
    dir: Vector2 = Vector2.zero(),
    stamina: f32 = 1.0,
    isSprinting: bool = false,
    exhaustedCoolDown: i32 = 0,
    heartBeatRate: i32 = maxHeartBeatRate,

    pub fn new(x: i32, y: i32) Player {
        return Player {
            .rect = Rectangle {
                .x = @intToFloat(f32, x),
                .y = @intToFloat(f32, y),
                .width = @intToFloat(f32, playerWidth),
                .height = @intToFloat(f32, playerWidth),
            },
            .vel = Vector2 {
                .x = 0,
                .y = 0
            },
        };
    }

    pub fn update(this: *Player) void {
        // play heartbeat
        if (@mod(Main.frameCount, this.heartBeatRate) == 0) {
            Sound.playHeartBeat();
        }
        // updates sprint & movement
        if (this.isSprinting and this.stamina > 0) {
            this.stamina-=0.005;
            if (this.stamina < 0.01) this.stamina = 0;
            this.exhaustedCoolDown = exhaustionCoolDown;
            this.vel = Vector2.add(this.vel, this.dir.normalize().scale(playerSprintSpeed));
            Light.intensity = raylib.Lerp(Light.intensity, 0.5, 0.025);
        } else {
            if (this.exhaustedCoolDown == 0) {
                Light.intensity = raylib.Lerp(Light.intensity, 1.0, 0.025);
                this.stamina += 0.0005;
                if (this.stamina > 1) this.stamina = 1;
            } else {
                this.exhaustedCoolDown-=1;
            }
            // std.debug.print("data:{d:.2}:{d:.2}\n", .{this.dir.normalize().scale(playerSpeed).x, this.dir.normalize().scale(playerSpeed).y});
            this.vel = Vector2.add(this.vel, this.dir.normalize().scale(playerSpeed));
        }
        // move by vel
        this.rect.x += this.vel.x;
        this.rect.y += this.vel.y;
        // check collisions with walls
        var doesCollide: bool = false;
        for (Wall.walls.items) |wall| {
            if (raylib.CheckCollisionRecs(wall.rect, this.rect)) {
                doesCollide = true;
                break;
            }
        }
        if (doesCollide) {
            this.rect.x -= this.vel.x;
            this.rect.y -= this.vel.y;
            this.vel = Vector2.zero();
        }
        this.vel = Vector2.scale(this.vel, drag);
        if (this.vel.length() < 0.3) this.vel = Vector2.zero(); 
    }

    pub fn draw(this: Player) void {
        const drawWidth = 164;
        // const scaleAmount = @intToFloat(f32, drawWidth)/32.0;
        const playerSrcRect = Rectangle {
            .x= 0,
            .y= 0,
            .width= 32,
            .height= 32,
        };
        const playerDestRect = Rectangle {
            .x= this.rect.pos().x,
            .y= this.rect.pos().y,
            .width= drawWidth,
            .height= drawWidth,
        };
        const dirToMouse: f32 = (Vector2.sub(raylib.GetMousePosition(), Vector2{.x=@intToFloat(f32, screenWidth/2), .y=@intToFloat(f32, screenHeight/2)}).angle()/raylib.PI)*180;
        raylib.DrawTexturePro(TextureLoader.playerTexture, playerSrcRect, playerDestRect, playerSrcRect.size().add(Vector2{.x=10,.y=5}), dirToMouse+90, raylib.WHITE);
    }
};

pub var player: Player = undefined; 