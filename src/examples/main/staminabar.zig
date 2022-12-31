const std = @import("std");

const raylib = @import("../../raylib/raylib.zig");
const Vector2 = raylib.Vector2;
const Color = raylib.Color;

const Player = @import("player.zig");
const Main = @import("main.zig");

const barHeight: i32 = 50;
const barWidth: i32 = Main.screenWidth/3;
const borderThickness: i32 = 4;

pub fn drawStaminaBar() void {
    raylib.DrawRectangle((Main.screenWidth/2)-(barWidth/2), Main.screenHeight-barHeight, barWidth, barHeight, Color.lerp(raylib.WHITE, raylib.BLACK, 0.7));
    raylib.DrawRectangle((Main.screenWidth/2)-(barWidth/2)+borderThickness, Main.screenHeight-barHeight+borderThickness, @floatToInt(i32, @intToFloat(f32, barWidth-borderThickness*2)*Player.player.stamina), barHeight-borderThickness*2, Color.lerp(raylib.WHITE, raylib.BLACK, 0.2));
}