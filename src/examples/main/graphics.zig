const std = @import("std");

const raylib = @import("../../raylib/raylib.zig");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const Main = @import("main.zig");
const TextureLoader = @import("textureloader.zig");
const StaminaBar = @import("staminabar.zig");
const Enemy = @import("enemy.zig");
const Player = @import("player.zig");
const Wall = @import("wall.zig");
const Present = @import("present.zig");
const Light = @import("light.zig");
const Maze = @import("maze.zig");
const Sound = @import("sound.zig");

// render lights to the lights texture
pub fn renderLight() void {
    // update radial gradient
    Light.createRadialGradient();
    // draw light to lights texture
    try Light.draw();
    {
        raylib.BeginTextureMode(lightsTexture);
        defer raylib.EndTextureMode(); 
        raylib.BeginMode2D(Main.camera);
        defer raylib.EndMode2D();

        // draw walls
        for (Wall.walls.items) |_, i| {
            Wall.walls.items[i].drawAlpha();
        }
    }
    Light.drawRadialGradient();
}

// draw game objects to the target texture
pub fn drawObjects() !void {
    raylib.BeginTextureMode(targetTexture);
    defer raylib.EndTextureMode();
    raylib.BeginMode2D(Main.camera);
    defer raylib.EndMode2D();
    raylib.ClearBackground(raylib.Color.lerp(raylib.BLACK, raylib.WHITE, 0.2));

    // draw sidewalks
    for (Wall.walls.items) |x| {
        x.drawSideWalk();
    }
    // draw the player
    Player.player.draw();
    // draw presents
    for (Present.presents.items) |_, i| {
        try Present.presents.items[i].update(i);
        Present.presents.items[i].draw();
    }
    // draw the enemy
    Enemy.enemy.draw();
    // draw walls
    for (Wall.walls.items) |_, i| {
        Wall.walls.items[i].drawTop();
    }
}

// draw the light mask to the target texture
pub fn drawLightMask() void {
    raylib.BeginTextureMode(targetTexture);
    defer raylib.EndTextureMode();
    raylib.BeginBlendMode(@enumToInt(raylib.BlendMode.BLEND_MULTIPLIED));
    defer raylib.EndBlendMode();

    const lightSrcRect: raylib.Rectangle = raylib.Rectangle {
        .x= 0,
        .y= 0,
        .width= Main.screenWidth,
        .height= -Main.screenHeight
    };
    // const diff: raylib.Vector2 = raylib.Vector2.sub(Player.player.rect.center().int().float(), Main.camera.target);
    // const trans: raylib.Vector2 = raylib.Vector2.sub(Main.camera.target, raylib.Vector2 {.x= Main.screenWidth/2, .y=Main.screenHeight/2});
    const lightDestRect: raylib.Rectangle = raylib.Rectangle {
        .x= 0,
        .y= 0,
        .width= Main.screenWidth,
        .height= Main.screenHeight
    };
    raylib.DrawTexturePro(lightsTexture.texture, lightSrcRect, lightDestRect, raylib.Vector2.zero(), 0, raylib.WHITE);
}

// draw the target texture to the screen
pub fn drawTarget() void {
    raylib.ClearBackground(raylib.BLACK);
    raylib.DrawTexturePro(targetTexture.texture, sourceRec, destRec, origin, 0.0, raylib.WHITE);
}

pub fn drawJumpScare() void {
    raylib.BeginTextureMode(targetTexture);
    defer raylib.EndTextureMode();
    if (Main.jumpScareTransitionAmount  < 1.0) {
        Main.jumpScareTransitionAmount *= 1.5;
        if (Main.jumpScareTransitionAmount >= 1.0) raylib.PlaySound(Sound.scream);
        raylib.DrawCircleGradient(Main.screenWidth/2, Main.screenHeight/2, raylib.Lerp(0, Main.screenHeight, Main.jumpScareTransitionAmount), raylib.BLACK, raylib.BLANK);
    } else if (Main.jumpScareTransitionAmount < 10.0) {
        Main.jumpScareTransitionAmount *= 1.03;
        raylib.ClearBackground(raylib.BLACK);
        const jumpScarePos: Vector2 = Vector2 {
            .x = Main.screenWidth/2,
            .y = (@intToFloat(f32, Main.screenHeight)*1.5)-(@intToFloat(f32, Main.screenHeight)*(std.math.min(Main.jumpScareTransitionAmount-0.8, 1.0))),
        };
        const jumpScareSize: Vector2 = Vector2 {
            .x = @intToFloat(f32, Main.screenHeight)*1.5,
            .y = @intToFloat(f32, Main.screenHeight)*1.5,
        };
        const jumpScareSrc = Rectangle {
            .x = 0,
            .y = 0,
            .width = 64,
            .height = 64,
        };
        const jumpScareDest = Rectangle {
            .x=jumpScarePos.x,
            .y=jumpScarePos.y,
            .width=jumpScareSize.x,
            .height=jumpScareSize.y,
        };
        const jumpScareOrigin = Vector2 {
            .x=jumpScareSize.x/2,
            .y=jumpScareSize.y/2,
        };
        raylib.DrawTexturePro(TextureLoader.jumpScareTexture, jumpScareSrc, jumpScareDest, jumpScareOrigin, std.math.sin(Main.jumpScareTransitionAmount*4)*25, raylib.WHITE);
    } else {
        raylib.PlaySound(Sound.laughs[@intCast(usize, raylib.GetRandomValue(0, Sound.laughs.len-1))]);
        Main.endGame();
    }
}

// draw the menu
pub fn drawMenu() !void {
    raylib.BeginTextureMode(targetTexture);
    defer raylib.EndTextureMode();
    raylib.ClearBackground(raylib.BLACK);
    // check for click
    if (raylib.IsMouseButtonPressed(raylib.MouseButton.MOUSE_BUTTON_LEFT) and Main.menuTransitionAmount == 0) {
        Main.menuTransitionAmount = 0.1;
    }
    // update transition amount
    if (Main.menuTransitionAmount > 0) {
        Main.menuTransitionAmount *= 1.03;
    }
    if (Main.menuTransitionAmount > 0.98) {
        try Main.startGame();
    }
    // draw prompt
    raylib.DrawText("click to enter the city", Main.screenWidth/2-200, Main.screenHeight/2-20, 32, Color.lerp(raylib.WHITE, raylib.BLACK, Main.menuTransitionAmount));
    // draw previous score
    if (Main.prevScore != null) {
        var buf: [64]u8 = undefined;
        raylib.DrawText(try std.fmt.bufPrintZ(&buf, "Score: {d}", .{Main.prevScore.?}), Main.screenWidth/20, Main.screenWidth/20, 32, raylib.WHITE);
    }
}

// draw the ui to the screen
pub fn drawUI() !void {
    StaminaBar.drawStaminaBar();

    const uiSrcRect = Rectangle {
        .x= 0,
        .y= 0,
        .width= 64,
        .height= 64,
    };
    const uiDestRect = Rectangle {
        .x= Main.screenWidth/20,
        .y= Main.screenHeight/40+20,
        .width= 164,
        .height= 164,
    };
    raylib.DrawTexturePro(TextureLoader.uiPresentTexture, uiSrcRect, uiDestRect, Vector2.zero(), 0, raylib.WHITE);

    var buf: [64]u8 = undefined;
    raylib.DrawText(try std.fmt.bufPrintZ(&buf, "{d}", .{Main.score}), Main.screenWidth/20+150, Main.screenHeight/40+80, 32, raylib.WHITE);

    // raylib.DrawText(try std.fmt.bufPrintZ(&buf, "Enemy Pos: {d:.2}, {d:.2}", .{Enemy.enemy.rect.x, Enemy.enemy.rect.y}), Main.screenWidth/20, Main.screenHeight/10+8, 30, raylib.WHITE);

    // raylib.DrawText(try std.fmt.bufPrintZ(&buf, "Distance: {d:.2}", .{Vector2.distanceTo(Enemy.enemy.rect.center(), Player.player.rect.center())}), Main.screenWidth/20, Main.screenHeight/5+8, 30, raylib.WHITE);
}

pub fn init() void {
    targetTexture = raylib.LoadRenderTexture(virtualScreenWidth, virtualScreenHeight);
    lightsTexture = raylib.LoadRenderTexture(virtualScreenWidth, virtualScreenHeight);
    radialGradientTexture = raylib.LoadRenderTexture(virtualScreenWidth, virtualScreenHeight);
    sourceRec = .{
        .x = 0,
        .y = 0,
        .width = @intToFloat(f32, targetTexture.texture.width),
        .height = @intToFloat(f32, -targetTexture.texture.height),
    };
}

// draw a 3d rect
pub fn drawRect3D(rect: Rectangle, rectHeight: f32) void {
    var topPos: Vector2 = rect.center();
    topPos = raylib.Vector2.sub(topPos, Main.camera.target);
    topPos = topPos.scale(rectHeight);
    topPos = raylib.Vector2.add(topPos, Main.camera.target);
    const shiftAmount: f32 = (rectHeight-1)*70;
    var topRect: Rectangle = Rectangle {
        .x= topPos.x-rect.width/2-shiftAmount,
        .y= topPos.y-rect.height/2-shiftAmount,
        .width= rect.width+shiftAmount*2,
        .height= rect.height+shiftAmount*2,
    };
    // draw the four sides of the wall
    raylib.DrawTriangle(rect.topLeft(), rect.bottomLeft(), topRect.topLeft(), Color.lerp(raylib.GRAY, raylib.BLACK, 0.2)); // left
    raylib.DrawTriangle(rect.bottomLeft(), topRect.bottomLeft(), topRect.topLeft(), Color.lerp(raylib.GRAY, raylib.BLACK, 0.2));
    raylib.DrawTriangle(rect.topRight(), rect.topLeft(), topRect.topRight(), Color.lerp(raylib.GRAY, raylib.BLACK, 0.3)); // back
    raylib.DrawTriangle(topRect.topLeft(), topRect.topRight(), rect.topLeft(), Color.lerp(raylib.GRAY, raylib.BLACK, 0.3));
    raylib.DrawTriangle(rect.bottomRight(), rect.topRight(), topRect.topRight(), Color.lerp(raylib.GRAY, raylib.BLACK, 0.6)); // right
    raylib.DrawTriangle(topRect.bottomRight(), rect.bottomRight(), topRect.topRight(), Color.lerp(raylib.GRAY, raylib.BLACK, 0.6));
    raylib.DrawTriangle(rect.bottomLeft(), rect.bottomRight(), topRect.bottomRight(), Color.lerp(raylib.GRAY, raylib.BLACK, 0.5)); // front
    raylib.DrawTriangle(topRect.bottomLeft(), rect.bottomLeft(), topRect.bottomRight(), Color.lerp(raylib.GRAY, raylib.BLACK, 0.5));
    // draw the top of the wall
    raylib.DrawRectangleRec(topRect, raylib.GRAY);
}
pub fn calculatepolyPoints(polyCenter: *Vector2, polyPoints: *[5]Vector2) void {
    for (polyPoints.*[0..polyPoints.*.len-1]) |_, i|
        polyCenter.* = polyCenter.*.add(polyPoints.*[i]);
    polyCenter.* = polyCenter.*.scale(1.0/@intToFloat(f32, polyPoints.*.len-1));
    for (polyPoints.*) |_, i| {
        polyPoints.*[i] = polyPoints.*[i].sub(polyCenter.*);
    }
}

// draw a textured 3d rect
pub fn drawTexturedRect3D(sideTexture: ?*raylib.Texture2D, topTexture: ?*raylib.Texture2D, rect: Rectangle, topRect: Rectangle) void {
    drawTexturedRect3DTint(sideTexture, topTexture, rect, topRect, raylib.WHITE);
}
pub fn drawTexturedRect3DTint(sideTexture: ?*raylib.Texture2D, topTexture: ?*raylib.Texture2D, rect: Rectangle, topRect: Rectangle, tint: Color) void {
    if (sideTexture != null) {
        // left
        var polyCenter: Vector2 = Vector2.zero(); 
        var polyPoints = [5]Vector2 {topRect.bottomLeft(),topRect.topLeft(),rect.topLeft(),rect.bottomLeft(),topRect.bottomLeft(),};
        calculatepolyPoints(&polyCenter, &polyPoints);
        raylib.DrawTexturePoly(sideTexture.?.*, polyCenter, @ptrCast([*]Vector2, polyPoints[0..polyPoints.len-1]), @ptrCast([*]Vector2, TextureLoader.baseTextCoords[0..TextureLoader.baseTextCoords.len]), 5, Color.lerp(tint, raylib.BLACK, 0.2));
        // up
        polyCenter = Vector2.zero();
        polyPoints = [5]Vector2 {topRect.topLeft(), topRect.topRight(), rect.topRight(), rect.topLeft(), topRect.topLeft()};
        calculatepolyPoints(&polyCenter, &polyPoints);
        raylib.DrawTexturePoly(sideTexture.?.*, polyCenter, @ptrCast([*]Vector2, polyPoints[0..polyPoints.len-1]), @ptrCast([*]Vector2, TextureLoader.baseTextCoords[0..TextureLoader.baseTextCoords.len]), 5, Color.lerp(tint, raylib.BLACK, 0.3));
        // right
        polyCenter = Vector2.zero();
        polyPoints = [5]Vector2 {topRect.topRight(), topRect.bottomRight(), rect.bottomRight(), rect.topRight(), topRect.topRight()};
        calculatepolyPoints(&polyCenter, &polyPoints);
        raylib.DrawTexturePoly(sideTexture.?.*, polyCenter, @ptrCast([*]Vector2, polyPoints[0..polyPoints.len-1]), @ptrCast([*]Vector2, TextureLoader.baseTextCoords[0..TextureLoader.baseTextCoords.len]), 5, Color.lerp(tint, raylib.BLACK, 0.6));
        // down
        polyCenter = Vector2.zero();
        polyPoints = [5]Vector2 {topRect.bottomRight(), topRect.bottomLeft(), rect.bottomLeft(), rect.bottomRight(), topRect.bottomRight()};
        calculatepolyPoints(&polyCenter, &polyPoints);
        raylib.DrawTexturePoly(sideTexture.?.*, polyCenter, @ptrCast([*]Vector2, polyPoints[0..polyPoints.len-1]), @ptrCast([*]Vector2, TextureLoader.baseTextCoords[0..TextureLoader.baseTextCoords.len]), 5, Color.lerp(tint, raylib.BLACK, 0.5));
    } else {
        // otherwise draw the sides out of triangles
        raylib.DrawTriangle(rect.topLeft(), rect.bottomLeft(), topRect.topLeft(), Color.lerp(tint, raylib.BLACK, 0.2)); // left
        raylib.DrawTriangle(rect.bottomLeft(), topRect.bottomLeft(), topRect.topLeft(), Color.lerp(tint, raylib.BLACK, 0.2));
        raylib.DrawTriangle(rect.topRight(), rect.topLeft(), topRect.topRight(), Color.lerp(tint, raylib.BLACK, 0.3)); // back
        raylib.DrawTriangle(topRect.topLeft(), topRect.topRight(), rect.topLeft(), Color.lerp(tint, raylib.BLACK, 0.3));
        raylib.DrawTriangle(rect.bottomRight(), rect.topRight(), topRect.topRight(), Color.lerp(tint, raylib.BLACK, 0.6)); // right
        raylib.DrawTriangle(topRect.bottomRight(), rect.bottomRight(), topRect.topRight(), Color.lerp(tint, raylib.BLACK, 0.6));
        raylib.DrawTriangle(rect.bottomLeft(), rect.bottomRight(), topRect.bottomRight(), Color.lerp(tint, raylib.BLACK, 0.5)); // front
        raylib.DrawTriangle(topRect.bottomLeft(), rect.bottomLeft(), topRect.bottomRight(), Color.lerp(tint, raylib.BLACK, 0.5));
    }
    if (topTexture != null) {
        // draw the top of the wall
        var polyCenter = Vector2.zero();
        var polyPoints = [5]Vector2 {topRect.bottomLeft(), topRect.bottomRight(), topRect.topRight(), topRect.topLeft(), topRect.bottomLeft()};
        calculatepolyPoints(&polyCenter, &polyPoints);
        raylib.DrawTexturePoly(topTexture.?.*, polyCenter, @ptrCast([*]Vector2, polyPoints[0..polyPoints.len-1]), @ptrCast([*]Vector2, TextureLoader.baseTextCoords[0..TextureLoader.baseTextCoords.len]), 5, tint);
    } else {
        raylib.DrawRectangleRec(topRect, tint);
    }
}

const virtualScreenWidth: i32 = 1600;
const virtualScreenHeight: i32 = 800;
const virtualRatio = @intToFloat(f32, Main.screenWidth) / @intToFloat(f32, virtualScreenWidth);
pub var origin = raylib.Vector2{ .x = 0, .y = 0 };
pub var targetTexture: raylib.RenderTexture2D = undefined;
pub var lightsTexture: raylib.RenderTexture2D = undefined;
pub var radialGradientTexture: raylib.RenderTexture2D = undefined;
pub var sourceRec: raylib.Rectangle = undefined;
pub var destRec = raylib.Rectangle{
    .x = -virtualRatio,
    .y = -virtualRatio,
    .width = @intToFloat(f32, Main.screenWidth) + (virtualRatio * 2),
    .height = @intToFloat(f32, Main.screenHeight) + (virtualRatio * 2),
};