const std = @import("std");
const raylib = @import("../../raylib/raylib.zig");

const Vector2 = raylib.Vector2;

const Main = @import("main.zig");

pub const numSmallWallTextures = 1;
pub const numBigWallTextures = 3;
pub const numTopWallTextures = 2;
pub const numHorizontalSideWalkTextures = 1;
pub const numVerticalSideWalkTextures = 1;
pub var smallWallTextures: [numSmallWallTextures]raylib.Texture2D = undefined;
pub var bigWallTextures: [numBigWallTextures]raylib.Texture2D = undefined;
pub var topWallTextures: [numTopWallTextures]raylib.Texture2D = undefined;
pub var horizontalSideWalkTextures: [numHorizontalSideWalkTextures]raylib.Texture2D = undefined;
pub var verticalSideWalkTextures: [numVerticalSideWalkTextures]raylib.Texture2D = undefined;
pub var longHorizontalSideWalkTexture: raylib.Texture2D = undefined;
pub var longVerticalSideWalkTexture: raylib.Texture2D = undefined;
pub var presentSideTexture: raylib.Texture2D = undefined;
pub var presentTopTexture: raylib.Texture2D = undefined;
pub var uiPresentTexture: raylib.Texture2D = undefined;
pub var playerTexture: raylib.Texture2D = undefined;
pub var enemyTexture: raylib.Texture2D = undefined;
pub var jumpScareTexture: raylib.Texture2D = undefined;

pub var baseTextCoords = [5]Vector2 {
    Vector2 {.x=0.0, .y=0.0},
    Vector2 {.x=1.0, .y=0.0},
    Vector2 {.x=1.0, .y=1.0},
    Vector2 {.x=0.0, .y=1.0},
    Vector2 {.x=0.0, .y=0.0},
};

pub fn loadTextures() !void {
    // load textures
    // Player.texPlayer = raylib.LoadTexture("assets/player.png");
    // load all wall textures
    comptime var i = 1;
    inline while (i <= numSmallWallTextures) : (i+=1) {
        smallWallTextures[i-1] = raylib.LoadTexture("assets/small-side-"++([1]u8 {std.fmt.digitToChar(i, std.fmt.Case.upper)})++".png");
    }
    i = 1;
    inline while (i <= numBigWallTextures) : (i+=1) {
        bigWallTextures[i-1] = raylib.LoadTexture("assets/tall-side-"++([1]u8 {std.fmt.digitToChar(i, std.fmt.Case.upper)})++".png");
    }
    i = 1;
    inline while (i <= numTopWallTextures) : (i+=1) {
        topWallTextures[i-1] = raylib.LoadTexture("assets/top-"++([1]u8 {std.fmt.digitToChar(i, std.fmt.Case.upper)})++".png");
    }
    // load sidewalk textures
    i = 1;
    inline while (i <= numHorizontalSideWalkTextures) : (i+=1) {
        horizontalSideWalkTextures[i-1] = raylib.LoadTexture("assets/sidewalk-horizontal-"++([1]u8 {std.fmt.digitToChar(i, std.fmt.Case.upper)})++".png");
    }
    i = 1;
    inline while (i <= numVerticalSideWalkTextures) : (i+=1) {
        verticalSideWalkTextures[i-1] = raylib.LoadTexture("assets/sidewalk-vertical-"++([1]u8 {std.fmt.digitToChar(i, std.fmt.Case.upper)})++".png");
    }
    longHorizontalSideWalkTexture = raylib.LoadTexture("assets/sidewalk-long-horizontal-1.png");
    longVerticalSideWalkTexture = raylib.LoadTexture("assets/sidewalk-long-vertical-1.png");
    // load present textures
    presentSideTexture = raylib.LoadTexture("assets/present-side-1.png");
    presentTopTexture = raylib.LoadTexture("assets/present-top-1.png");
    // load ui textures
    uiPresentTexture = raylib.LoadTexture("assets/presents-1.png");
    // load player and enemy textures
    playerTexture = raylib.LoadTexture("assets/player.png");
    enemyTexture = raylib.LoadTexture("assets/enemy.png");
    // load jumpscare texture
    jumpScareTexture = raylib.LoadTexture("assets/jumpscare.png");
}
