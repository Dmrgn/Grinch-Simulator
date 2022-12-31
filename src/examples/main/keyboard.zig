const raylib = @import("../../raylib/raylib.zig");

const Player = @import("player.zig");

pub fn handleKeyboard() !void {
    Player.player.dir.x = 0;
    Player.player.dir.y = 0;
    if (raylib.IsKeyDown(raylib.KeyboardKey.KEY_A))
        Player.player.dir.x = -1;
    if (raylib.IsKeyDown(raylib.KeyboardKey.KEY_W))
        Player.player.dir.y = -1;
    if (raylib.IsKeyDown(raylib.KeyboardKey.KEY_D))
        Player.player.dir.x = 1;
    if (raylib.IsKeyDown(raylib.KeyboardKey.KEY_S))
        Player.player.dir.y = 1;
    Player.player.isSprinting = false;
    if (raylib.IsKeyDown(raylib.KeyboardKey.KEY_SPACE))
        Player.player.isSprinting = true;
}