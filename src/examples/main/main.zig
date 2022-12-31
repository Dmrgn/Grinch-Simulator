const std = @import("std");
const Example = @import("../example.zig").Example;
const raylib = @import("../../raylib/raylib.zig");

const Graphics = @import("graphics.zig");
const TextureLoader = @import("textureloader.zig");
const PathFinder = @import("pathfinder.zig");
const Keyboard = @import("keyboard.zig");
const Enemy = @import("enemy.zig");
const Player = @import("player.zig");
const Wall = @import("wall.zig");
const Present = @import("present.zig");
const Light = @import("light.zig");
const Maze = @import("maze.zig");
const Piece = @import("piece.zig");
const Sound = @import("sound.zig");

pub const example = Example{
    .initFn = init,
    .updateFn = update,
};
pub const screenWidth: i32 = 1600;
pub const screenHeight: i32 = 800;

pub var camera: raylib.Camera2D = undefined;
pub var alloc: std.mem.Allocator = undefined;

pub var frameCount: i64 = 0;
pub var score: i32 = 0;
pub var prevScore: ?i32 = null;
pub var gameState: GameState = GameState.Menu;
pub var menuTransitionAmount: f32 = 0;
pub var jumpScareTransitionAmount: f32 = 0;

pub const GameState = enum {
    Menu,
    Game,
    JumpScare,
};

pub fn startMenu() void {
    gameState = GameState.Menu;
    menuTransitionAmount = 0;
    std.debug.print("here2\n", .{});
}

pub fn startGame() !void {
    // set gamestate
    gameState = GameState.Game;

    // init and create enemy
    Enemy.enemy = Enemy.Enemy.init();
    // init and create the player
    Player.player = Player.Player.new(screenWidth/2-Player.playerWidth/2, screenHeight/2-Player.playerWidth/2);
    // create a maze
    Maze.maze = try Maze.MazeType.init();
    // reset score
    score = 0;

    // init the camera
    camera.target = Player.player.rect.pos();
    camera.offset = raylib.Vector2 { .x= @intToFloat(f32, screenWidth)/2.0, .y= @intToFloat(f32, screenHeight)/2.0 };
    camera.rotation = 0.0;
    camera.zoom = 1.0;

    // add walls from maze
    Wall.walls = std.ArrayList(Wall.Wall).init(alloc);
    const wallSpacing: i32 = 5;
    for (Maze.maze.maze) |_, i| {
        for (Maze.maze.maze[i]) |_, j| {
            if (Maze.maze.maze[i][j] == 1) {
                const worldCoords = Maze.MazeType.mazeToWorld(raylib.Vector2 {.x=@intToFloat(f32, j), .y=@intToFloat(f32, i)});
                try Wall.walls.append(Wall.Wall.new(
                    @floatToInt(i32, worldCoords.x),
                    @floatToInt(i32, worldCoords.y),
                    Maze.blockSize,
                    Maze.blockSize,
                    @intCast(i32, j),
                    @intCast(i32, i),
                    raylib.GRAY,
                    wallSpacing,
                    raylib.GetRandomValue(1, 3),
                ));
            }
        }
    }
    // init & create presents
    Present.presents = std.ArrayList(Present.Present).init(alloc);
    try Present.Present.createPresents();
    // start music
    raylib.PlayMusicStream(Sound.music);
    raylib.PlayMusicStream(Sound.chaseMusic);
}

pub fn startJumpScare() void {
    jumpScareTransitionAmount = 0.05;
    gameState = GameState.JumpScare;
    raylib.PlaySound(Sound.near);
}

pub fn endGame() void {
    // free walls and presents
    Wall.walls.deinit();
    Present.presents.deinit();
    // free enemy path if it exists
    if (Enemy.enemy.currentPath != null) {
        Enemy.enemy.currentPath.?.deinit();
    }
    // end music streams
    raylib.StopMusicStream(Sound.music);
    raylib.StopMusicStream(Sound.chaseMusic);
    // swap scores
    prevScore = score;
    // restart the game
    startMenu();
}

fn init(allocator: std.mem.Allocator) !void {
    raylib.InitWindow(screenWidth, screenHeight, "Game");
    raylib.SetTargetFPS(60);

    // load textures
    try TextureLoader.loadTextures();
    // load sounds
    Sound.loadSounds();
    // init graphics
    Graphics.init();
    // create variations of board pieces
    Piece.Piece.createPieceVariants();
    // create radial gradient
    Light.createRadialGradient();

    // assign the allocator
    alloc = allocator;

    startMenu();
}

fn update(_: f32) !void {
    frameCount+=1;

    switch (gameState) {
        GameState.Menu => {
            try Graphics.drawMenu();
        },
        GameState.JumpScare => {

        },
        GameState.Game => {
            // loop music on completion
            Sound.loopMusic();
            // update enemy
            try Enemy.enemy.update();
            // update player
            Player.player.update();
            // update camera position
            if (frameCount > 1) {
                const diff: raylib.Vector2 = raylib.Vector2.sub(Player.player.rect.center(), camera.target);
                camera.target = raylib.Vector2.add(camera.target, raylib.Vector2.scale(diff, 0.1));
            } else {
                camera.target = Player.player.rect.center();
            }
            // update draw order
            if (@mod(frameCount, 20) == 0) {
                try Wall.Wall.computeDrawOrder();
            }

            Graphics.renderLight();

            Graphics.drawObjects();

            Graphics.drawLightMask();

            try Keyboard.handleKeyboard();
        }
    }
    {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();
        Graphics.drawTarget();

        // hard code drawing ui on top
        if (gameState == GameState.Game) {
            try Graphics.drawUI();
        }
        // and the jumpscare (i love hard coding)
        if (gameState == GameState.JumpScare) {
            Graphics.drawJumpScare();
        }
    }
}
