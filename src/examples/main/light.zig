const std = @import("std");

const raylib = @import("../../raylib/raylib.zig");
const Vector2 = raylib.Vector2;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const Player = @import("player.zig");
const Main = @import("main.zig");
const Wall = @import("wall.zig");
const Graphics = @import("graphics.zig");

pub var intensity: f32 = 1.0;
pub const maxIntersections: usize = 1_000;

// and intersection point and its distance
const Intersection = struct {
    point: Vector2,
    dist: f32,
    angle: f32 = 0,
    didHitWall: bool = false,
    didHitScreenBorder: bool = false,
    wallIndex: usize = 0,
};

pub fn draw() !void {
    var screenCorners: [4]Vector2 = [4]Vector2{
        Vector2.zero(), // top left
        Vector2{.x=Main.screenWidth, .y=0}, // top right
        Vector2{.x=Main.screenWidth, .y=Main.screenHeight}, // bottom right
        Vector2{.x=0, .y=Main.screenHeight}, // bottom left
    };
    for (screenCorners) |_, i| {
        screenCorners[i] = Vector2.add(screenCorners[i], Vector2.sub(Main.camera.target, Main.camera.offset));
    }
    // const mousePos: Vector2 = Vector2.add(raylib.GetMousePosition(), Vector2.sub(Main.camera.target, Main.camera.offset));
    // raylib.DrawLineV(Player.player.rect.center(), mousePos, raylib.RED);
    var closestIntersections: [maxIntersections]Intersection = undefined;
    var closestIntersectionsLength: usize = 0;
    // create a ray for every corner of every wall
    const currentPriorityLength = std.math.min(Wall.walls.items.len, Wall.priorityWallLength);
    var rayIndex: usize = 0;
    while (rayIndex < currentPriorityLength):(rayIndex+=1) {
        // screen corners
        const baseWallVerticies: [4]Vector2 = [4]Vector2{
            Wall.walls.items[Wall.walls.items.len-rayIndex-1].rect.topLeft(),
            Wall.walls.items[Wall.walls.items.len-rayIndex-1].rect.topRight(),
            Wall.walls.items[Wall.walls.items.len-rayIndex-1].rect.bottomRight(),
            Wall.walls.items[Wall.walls.items.len-rayIndex-1].rect.bottomLeft(),
        };
        // add 2 rays slightly to the left and right of each base ray
        var wallVerticies: [12]Vector2 = undefined;
        for (wallVerticies) |_, i| {
            const baseIndex: usize = @divFloor(i, 3);
            wallVerticies[i] = Vector2.sub(baseWallVerticies[baseIndex], Player.player.rect.center().int().float()).scale(10).rotate(-0.01+@intToFloat(f32, @mod(i,3))*0.01).add(Player.player.rect.center().int().float());
        }
        // for each ray we need to cast
        for (wallVerticies) |wallVertex| {
            castRay(wallVertex, &closestIntersections, &closestIntersectionsLength);
            // if the ray hit a wall, then make the wall visible
            if (closestIntersections[closestIntersectionsLength-1].didHitWall) {
                Wall.walls.items[closestIntersections[closestIntersectionsLength-1].wallIndex].touchedByLight = true;
            }
        }
    }
    // draw rays to the screen borders
    var screenBorderVerticies: [4]Vector2 = undefined; 
    for (screenBorderVerticies) |_, i| {
        screenBorderVerticies[i] = screenCorners[i].sub(Player.player.rect.center().int().float()).scale(2).add(Player.player.rect.center().int().float());
    }
    for (screenBorderVerticies) |wallVertex| {
        castRay(wallVertex, &closestIntersections, &closestIntersectionsLength);
    }

    // sike apparently std sort feels like working now
    std.sort.sort(Intersection, closestIntersections[0..closestIntersectionsLength], {}, angleSorter);

    // get just the vector part of the intersections
    var polygonVertices: [maxIntersections]Vector2 = undefined;
    var polygonVerticesLength: usize = 1;
    polygonVertices[0] = Vector2 {
        .x= Main.screenWidth/2,
        .y= Main.screenHeight/2,
    };
    for (closestIntersections[0..closestIntersectionsLength]) |_, i| {
        polygonVertices[polygonVerticesLength] = Vector2 {
            .x= closestIntersections[i].point.x,
            .y= closestIntersections[i].point.y,
        };
        polygonVertices[polygonVerticesLength] = Vector2.sub(polygonVertices[polygonVerticesLength], Main.camera.target).add(Vector2 {.x= Main.screenWidth/2, .y= Main.screenHeight/2});
        polygonVerticesLength+=1;
    }
    polygonVertices[polygonVerticesLength] = Vector2 {
        .x= polygonVertices[1].x,
        .y= polygonVertices[1].y,
    };
    polygonVerticesLength+=1;

    // draw to light mask
    raylib.EndTextureMode();
    defer raylib.BeginTextureMode(Graphics.targetTexture);
    raylib.EndMode2D();
    defer raylib.BeginMode2D(Main.camera);
    
    {
        raylib.BeginTextureMode(Graphics.lightsTexture);
        defer raylib.EndTextureMode();
        // raylib.BeginMode2D(Main.camera);
        // defer raylib.EndMode2D();
        raylib.ClearBackground(raylib.BLACK);

        raylib.DrawTriangleFan(&polygonVertices, @intCast(i32, polygonVerticesLength), raylib.WHITE);
    }
}
pub fn drawRadialGradient() void {
    raylib.EndTextureMode();
    defer raylib.BeginTextureMode(Graphics.targetTexture);
    raylib.EndMode2D();
    defer raylib.BeginMode2D(Main.camera);

    {
        raylib.BeginTextureMode(Graphics.lightsTexture);
        defer raylib.EndTextureMode();

        raylib.BeginBlendMode(@enumToInt(raylib.BlendMode.BLEND_MULTIPLIED));
        raylib.DrawTextureV(Graphics.radialGradientTexture.texture, Vector2.zero(), raylib.WHITE);
        raylib.EndBlendMode();
    }
}
pub fn createRadialGradient() void {
    raylib.EndTextureMode();
    defer raylib.BeginTextureMode(Graphics.targetTexture);
    raylib.EndMode2D();
    defer raylib.BeginMode2D(Main.camera);

    raylib.BeginTextureMode(Graphics.radialGradientTexture);
    defer raylib.EndTextureMode();
    
    raylib.ClearBackground(raylib.BLACK);

    raylib.DrawCircleGradient(Main.screenWidth/2, Main.screenHeight/2, @intToFloat(f32, Main.screenHeight)*0.8*intensity, raylib.WHITE, raylib.BLACK);
}
fn angleSorter(context: void, a: Intersection, b: Intersection) bool {
    _ = context;
    return a.angle > b.angle;
}
fn castRay(ray: Vector2, closests: *[maxIntersections]Intersection, closestsLength: *usize) void {
    var screenCorners: [4]Vector2 = [4]Vector2{
        Vector2.zero(), // top left
        Vector2{.x=Main.screenWidth, .y=0}, // top right
        Vector2{.x=Main.screenWidth, .y=Main.screenHeight}, // bottom right
        Vector2{.x=0, .y=Main.screenHeight}, // bottom left
    };
    for (screenCorners) |_, i| {
        screenCorners[i] = Vector2.add(screenCorners[i], Vector2.sub(Main.camera.target, Main.camera.offset));
    }
    // screen borders
    const screenBorders: [4][2]Vector2 = [4][2]Vector2{
        [2]Vector2 {screenCorners[3], screenCorners[0]}, // left
        [2]Vector2 {screenCorners[0], screenCorners[1]}, // up
        [2]Vector2 {screenCorners[1], screenCorners[2]}, // right
        [2]Vector2 {screenCorners[2], screenCorners[3]}, // down
    };

    var closestDist: f32 = std.math.floatMax(f32);
    var closestIntersection: Intersection = undefined;
    // test collision with walls
    const currentPriorityLength = std.math.min(Wall.walls.items.len, Wall.priorityWallLength);
    for (Wall.walls.items[0..currentPriorityLength]) |_, i| {
        // check intersection with line
        var intersectionPoint: Vector2 = undefined;
        const edges: [4][2]Vector2 = [4][2]Vector2{
            [2]Vector2 {Wall.walls.items[Wall.walls.items.len-i-1].rect.bottomLeft(), Wall.walls.items[Wall.walls.items.len-i-1].rect.topLeft()},
            [2]Vector2 {Wall.walls.items[Wall.walls.items.len-i-1].rect.topLeft(), Wall.walls.items[Wall.walls.items.len-i-1].rect.topRight()},
            [2]Vector2 {Wall.walls.items[Wall.walls.items.len-i-1].rect.topRight(), Wall.walls.items[Wall.walls.items.len-i-1].rect.bottomRight()},
            [2]Vector2 {Wall.walls.items[Wall.walls.items.len-i-1].rect.bottomRight(), Wall.walls.items[Wall.walls.items.len-i-1].rect.bottomLeft()},
        };
        for (edges) |edge| {
            if (raylib.CheckCollisionLines(Player.player.rect.center(), ray, Vector2{.x=edge[0].x, .y=edge[0].y}, Vector2{.x=edge[1].x, .y=edge[1].y}, &intersectionPoint)) {
                const dist: f32 = Vector2.distanceTo(Player.player.rect.center(), intersectionPoint);
                if (dist < closestDist) {
                    closestIntersection = Intersection {
                        .point= Vector2 {.x=intersectionPoint.x, .y=intersectionPoint.y},
                        .dist= dist,
                        .didHitWall= true,
                        .wallIndex= Wall.walls.items.len-i-1
                    };
                    closestDist = dist;
                }
            }
        }
    }
    // test collision with screen borders
    for (screenBorders) |screenBorder| {
        var intersectionPoint: Vector2 = undefined;
        if (raylib.CheckCollisionLines(Player.player.rect.center(), ray, screenBorder[0], screenBorder[1], &intersectionPoint)) {
            const dist: f32 = Vector2.distanceTo(Player.player.rect.center(), intersectionPoint);
            if (dist < closestDist) {
                closestIntersection = Intersection {
                    .point= Vector2 {.x=intersectionPoint.x, .y=intersectionPoint.y},
                    .dist= dist,
                    .didHitScreenBorder= true,
                };
                closestDist = dist;
            }
        }
    }

    closests[closestsLength.*] = Intersection {
        .point= Vector2{.x=closestIntersection.point.x, .y=closestIntersection.point.y},
        .dist= closestIntersection.dist,
        .angle= Vector2.sub(closestIntersection.point, Player.player.rect.center()).angle(),
        .didHitWall= closestIntersection.didHitWall,
        .didHitScreenBorder= closestIntersection.didHitScreenBorder,
        .wallIndex= closestIntersection.wallIndex
    };
    closestsLength.*+=1;
}