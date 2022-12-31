const std = @import("std");

const raylib = @import("../../raylib/raylib.zig");
const Vector2 = raylib.Vector2;
const Texture2D = raylib.Texture2D;
const Rectangle = raylib.Rectangle;
const Color = raylib.Color;

const Graphics = @import("graphics.zig");
const Player = @import("player.zig");
const Main = @import("main.zig");
const TextureLoader = @import("textureloader.zig");
const Maze = @import("maze.zig");

pub const Wall = struct {
    rect: Rectangle,
    drawRect: Rectangle,
    col: Color,
    height: i32,
    touchedByLight: bool = false,
    transparency: f32 = 1,
    mazePos: Vector2,
    sideTexture: *raylib.Texture2D,
    topTexture: *raylib.Texture2D,
    horizontalSideWalkTexture: *raylib.Texture2D,
    verticalSideWalkTexture: *raylib.Texture2D,

    const WallDistance = struct { // wall and its distance to the player in one datatype
        wall: Wall,
        dist: f32,
    };

    // create a new wall
    pub fn new(x: i32, y: i32, w: i32, h:i32, mazeX:i32, mazeY:i32, color:Color, spacing:i32, height:i32) Wall {
        var st: *Texture2D = undefined;
        if (height == 1) {
            st = &TextureLoader.smallWallTextures[@intCast(usize, raylib.GetRandomValue(0, TextureLoader.numSmallWallTextures-1))];
        } else {
            st = &TextureLoader.bigWallTextures[@intCast(usize, raylib.GetRandomValue(0, TextureLoader.numBigWallTextures-1))];
        }
        const tt: *Texture2D = &TextureLoader.topWallTextures[@intCast(usize, raylib.GetRandomValue(0, TextureLoader.numTopWallTextures-1))];
        const vst: *Texture2D = &TextureLoader.verticalSideWalkTextures[@intCast(usize, raylib.GetRandomValue(0, TextureLoader.numVerticalSideWalkTextures-1))];
        const hst: *Texture2D = &TextureLoader.horizontalSideWalkTextures[@intCast(usize, raylib.GetRandomValue(0, TextureLoader.numHorizontalSideWalkTextures-1))];
        return Wall {
            .rect = Rectangle {
                .x= @intToFloat(f32, x),
                .y= @intToFloat(f32, y),
                .width= @intToFloat(f32, w),
                .height= @intToFloat(f32, h)                
            },
            .drawRect = Rectangle {
                .x= @intToFloat(f32, x+spacing),
                .y= @intToFloat(f32, y+spacing),
                .width= @intToFloat(f32, w-spacing*2),
                .height= @intToFloat(f32, h-spacing*2)  
            },
            .col= color,
            .height= height,
            .sideTexture= st,
            .topTexture= tt,
            .horizontalSideWalkTexture= hst,
            .verticalSideWalkTexture= vst,
            .mazePos= Vector2 {
                .x= @intToFloat(f32, mazeX),
                .y= @intToFloat(f32, mazeY)
            }
        };
    }

    // compute the draw order of the specifed array of walls and return it
    // also reset whether a wall is touching light or not
    pub fn computeDrawOrder() !void {
        
        var sortedWalls:[maxWalls]WallDistance = undefined;
        var sortedWallsLength: usize = 0;
        
        for (walls.items) |wall| {
            // walls with the closest point to the player should be drawn first
            var closestDist: f32 = Vector2.distanceTo(wall.drawRect.topLeft(), Player.player.rect.center());
            var tempDist: f32 = Vector2.distanceTo(wall.drawRect.topRight(), Player.player.rect.center());
            if (tempDist < closestDist) closestDist = tempDist;
            tempDist = Vector2.distanceTo(wall.drawRect.bottomLeft(), Player.player.rect.center());
            if (tempDist < closestDist) closestDist = tempDist;
            tempDist = Vector2.distanceTo(wall.drawRect.bottomRight(), Player.player.rect.center());
            if (tempDist < closestDist) closestDist = tempDist;
            sortedWalls[sortedWallsLength] = WallDistance {
                .wall = Wall {
                    .rect= Rectangle {
                        .x= wall.rect.pos().x,
                        .y= wall.rect.pos().y,
                        .width= wall.rect.size().x,
                        .height= wall.rect.size().y,
                    },
                    .drawRect= Rectangle {
                        .x= wall.drawRect.pos().x,
                        .y= wall.drawRect.pos().y,
                        .width= wall.drawRect.size().x,
                        .height= wall.drawRect.size().y,
                    },
                    .mazePos= Vector2 {
                        .x= wall.mazePos.x,
                        .y= wall.mazePos.y,
                    },
                    .sideTexture = wall.sideTexture,
                    .topTexture = wall.topTexture,
                    .horizontalSideWalkTexture= wall.horizontalSideWalkTexture,
                    .verticalSideWalkTexture= wall.verticalSideWalkTexture,
                    .col= wall.col,
                    .height= wall.height,
                    .transparency= wall.transparency
                },
                .dist = closestDist
            };
            sortedWallsLength+=1;
        }

        std.sort.sort(WallDistance, sortedWalls[0..sortedWallsLength], {}, distSorter);

        for (walls.items) |_, i| {
            try walls.append(Wall {
                .rect= Rectangle {
                    .x=sortedWalls[i].wall.rect.x,
                    .y=sortedWalls[i].wall.rect.y,
                    .width=sortedWalls[i].wall.rect.width,
                    .height=sortedWalls[i].wall.rect.height,
                },
                .drawRect= Rectangle {
                    .x= sortedWalls[i].wall.drawRect.pos().x,
                    .y= sortedWalls[i].wall.drawRect.pos().y,
                    .width= sortedWalls[i].wall.drawRect.size().x,
                    .height= sortedWalls[i].wall.drawRect.size().y,
                },
                .mazePos= Vector2 {
                    .x= sortedWalls[i].wall.mazePos.x,
                    .y= sortedWalls[i].wall.mazePos.y,
                },
                .sideTexture = sortedWalls[i].wall.sideTexture,
                .topTexture = sortedWalls[i].wall.topTexture,
                .horizontalSideWalkTexture= sortedWalls[i].wall.horizontalSideWalkTexture,
                .verticalSideWalkTexture= sortedWalls[i].wall.verticalSideWalkTexture,
                .col= sortedWalls[i].wall.col,
                .height= sortedWalls[i].wall.height,
                .transparency= sortedWalls[i].wall.transparency
            });
            _ = walls.orderedRemove(0);
        }
    }
    fn distSorter(context: void, a: WallDistance, b: WallDistance) bool {
        _ = context;
        return a.dist > b.dist;
    }

    // draw this wall
    pub fn drawBase(this: Wall) void {
        raylib.DrawRectangleV(this.drawRect.pos().sub(Vector2.one().scale(2)), this.drawRect.size().add(Vector2.one().scale(4)), raylib.WHITE);
    }
    pub fn calcTopRect(rect: Rectangle, height: f32) Rectangle {
        var topPos: Vector2 = rect.center();
        topPos = raylib.Vector2.sub(topPos, Main.camera.target);
        topPos = topPos.scale(height);
        topPos = raylib.Vector2.add(topPos, Main.camera.target);
        const shiftAmount: f32 = (height-1)*86;
        return Rectangle {
            .x= topPos.x-rect.width/2-shiftAmount,
            .y= topPos.y-rect.height/2-shiftAmount,
            .width= rect.width+shiftAmount*2,
            .height= rect.height+shiftAmount*2,
        };
    }
    pub fn drawAlpha(this: *Wall) void {
        if (this.touchedByLight and this.transparency >= 0) {
            this.transparency/=1.3;
            if (this.transparency < 0.01) this.transparency = 0;
        } else if (!this.touchedByLight and this.transparency <= 1) {
            if (this.transparency == 0) this.transparency = 0.01;
            this.transparency+=0.1;
            if (this.transparency > 1) this.transparency = 1;
        }
        const topRect = calcTopRect(this.drawRect, @intToFloat(f32, this.height)*heightScaleAmount*heightScaleAmount);

        // draw the four sides of the wall
        raylib.DrawTriangle(this.drawRect.topLeft(), this.drawRect.bottomLeft(), topRect.topLeft(), Color.lerp((raylib.WHITE), (raylib.BLACK), this.transparency)); // left
        raylib.DrawTriangle(this.drawRect.bottomLeft(), topRect.bottomLeft(), topRect.topLeft(), Color.lerp((raylib.WHITE), (raylib.BLACK), this.transparency));
        raylib.DrawTriangle(this.drawRect.topRight(), this.drawRect.topLeft(), topRect.topRight(), Color.lerp((raylib.WHITE), (raylib.BLACK), this.transparency)); // back
        raylib.DrawTriangle(topRect.topLeft(), topRect.topRight(), this.drawRect.topLeft(), Color.lerp((raylib.WHITE), (raylib.BLACK), this.transparency));
        raylib.DrawTriangle(this.drawRect.bottomRight(), this.drawRect.topRight(), topRect.topRight(), Color.lerp((raylib.WHITE), (raylib.BLACK), this.transparency)); // right
        raylib.DrawTriangle(topRect.bottomRight(), this.drawRect.bottomRight(), topRect.topRight(), Color.lerp((raylib.WHITE), (raylib.BLACK), this.transparency));
        raylib.DrawTriangle(this.drawRect.bottomLeft(), this.drawRect.bottomRight(), topRect.bottomRight(), Color.lerp((raylib.WHITE), (raylib.BLACK), this.transparency)); // front
        raylib.DrawTriangle(topRect.bottomLeft(), this.drawRect.bottomLeft(), topRect.bottomRight(), Color.lerp((raylib.WHITE), (raylib.BLACK), this.transparency));
        // draw the top of the wall
        raylib.DrawRectangleRec(topRect, Color.lerp((raylib.WHITE), (raylib.BLACK), this.transparency));
    }
    pub fn drawTop(this: Wall) void {
        if (!this.touchedByLight) return;
        const maxTopRect: Rectangle = calcTopRect(this.drawRect, @intToFloat(f32, this.height)*heightScaleAmount*heightScaleAmount);
        var i: i32 = 0;
        while (i < this.height) : (i+=1) {
            const adjust: f32 = if (this.height == 1) 0 else if (i == 0) -0.2 else if (i == this.height-1) 0.2 else 0;
            const prevAdjust: f32 = if (this.height == 1) 0 else if (i == 1) -0.2 else 0;
            const topTopLeft = Vector2.lerp(this.drawRect.topLeft(), maxTopRect.topLeft(), (@intToFloat(f32, i+1)/@intToFloat(f32, this.height)) + adjust);
            const topBottomRight = Vector2.lerp(this.drawRect.bottomRight(), maxTopRect.bottomRight(), (@intToFloat(f32, i+1)/@intToFloat(f32, this.height)) + adjust);
            const topSize = Vector2.sub(topBottomRight, topTopLeft);
            const bottomTopLeft = Vector2.lerp(this.drawRect.topLeft(), maxTopRect.topLeft(), (@intToFloat(f32, i)/@intToFloat(f32, this.height)) + prevAdjust);
            const bottomBottomRight = Vector2.lerp(this.drawRect.bottomRight(), maxTopRect.bottomRight(), (@intToFloat(f32, i)/@intToFloat(f32, this.height)) + prevAdjust);
            const bottomSize = Vector2.sub(bottomBottomRight, bottomTopLeft);
            const bottomRect = Rectangle {
                .x= bottomTopLeft.x,
                .y= bottomTopLeft.y,
                .width= bottomSize.x,
                .height= bottomSize.y,
            };
            const topRect = Rectangle {
                .x= topTopLeft.x,
                .y= topTopLeft.y,
                .width= topSize.x,
                .height= topSize.y,
            };
            Graphics.drawTexturedRect3D(this.sideTexture, this.topTexture, bottomRect, topRect);
        }
    }
    pub fn drawSideWalk(this: Wall) void {
        const sideWalkWidth: f32 = 60;
        const sideWalkGap: f32 = 1;
        const verticalSideWalkSize: Vector2 = Vector2 {
            .x= sideWalkWidth-sideWalkGap*2,
            .y= this.rect.size().y-sideWalkGap*2,
        };
        const horizontalSideWalkSize: Vector2 = Vector2 {
            .x= this.rect.size().x-sideWalkGap*2,
            .y= sideWalkWidth-sideWalkGap*2,
        };
        // left sidewalk
        if (this.mazePos.x > 0) {
            var isDrawn = false;
            if (this.mazePos.y-1 >= 0 and this.mazePos.y+1 <= Maze.maze.maze.len-1) {
                if (Maze.maze.maze[@floatToInt(usize, this.mazePos.y-1)][@floatToInt(usize, this.mazePos.x)] != 1 and
                    Maze.maze.maze[@floatToInt(usize, this.mazePos.y)][@floatToInt(usize, this.mazePos.x-1)] != 1 and
                    Maze.maze.maze[@floatToInt(usize, this.mazePos.y+1)][@floatToInt(usize, this.mazePos.x)] != 1) {
                    isDrawn = true;
                    const sideWalkPos: Vector2 = Vector2 {.x= this.rect.pos().x-sideWalkWidth, .y= this.rect.pos().y-sideWalkWidth,};
                    const sideWalkRect: Rectangle = Rectangle {.x= sideWalkPos.x, .y= sideWalkPos.y, .width= verticalSideWalkSize.x, .height= verticalSideWalkSize.y+sideWalkWidth*2};
                    Graphics.drawTexturedRect3D(null, &TextureLoader.longVerticalSideWalkTexture, sideWalkRect, calcTopRect(sideWalkRect, 1.02));
                }
            }
            if (!isDrawn and Maze.maze.maze[@floatToInt(usize, this.mazePos.y)][@floatToInt(usize, this.mazePos.x-1)] != 1) {
                const sideWalkPos: Vector2 = Vector2 {.x= this.rect.pos().x-sideWalkWidth, .y= this.rect.pos().y,};
                    const sideWalkRect: Rectangle = Rectangle {.x= sideWalkPos.x, .y= sideWalkPos.y, .width= verticalSideWalkSize.x, .height= verticalSideWalkSize.y};
                Graphics.drawTexturedRect3D(null, this.verticalSideWalkTexture, sideWalkRect, calcTopRect(sideWalkRect, 1.02));
            }
        }
        // top sidewalk
        if (this.mazePos.x > 0) {
            var isDrawn = false;
            if (this.mazePos.y-1 >= 0 and this.mazePos.y+1 <= Maze.maze.maze.len-1) {
                if (Maze.maze.maze[@floatToInt(usize, this.mazePos.y)][@floatToInt(usize, this.mazePos.x-1)] != 1 and
                    Maze.maze.maze[@floatToInt(usize, this.mazePos.y-1)][@floatToInt(usize, this.mazePos.x)] != 1 and
                    Maze.maze.maze[@floatToInt(usize, this.mazePos.y)][@floatToInt(usize, this.mazePos.x+1)] != 1) {
                    isDrawn = true;
                    const sideWalkPos: Vector2 = Vector2 {.x= this.rect.pos().x-sideWalkWidth, .y= this.rect.pos().y-sideWalkWidth,};
                    const sideWalkRect: Rectangle = Rectangle {.x= sideWalkPos.x, .y= sideWalkPos.y, .width= horizontalSideWalkSize.x+sideWalkWidth*2, .height= horizontalSideWalkSize.y};
                    Graphics.drawTexturedRect3D(null, &TextureLoader.longHorizontalSideWalkTexture, sideWalkRect, calcTopRect(sideWalkRect, 1.02));
                }
            }
            if (!isDrawn and Maze.maze.maze[@floatToInt(usize, this.mazePos.y-1)][@floatToInt(usize, this.mazePos.x)] != 1) {
                const sideWalkPos: Vector2 = Vector2 {.x= this.rect.pos().x, .y= this.rect.pos().y-sideWalkWidth,};
                const sideWalkRect: Rectangle = Rectangle {.x= sideWalkPos.x, .y= sideWalkPos.y, .width= horizontalSideWalkSize.x, .height= horizontalSideWalkSize.y};
                Graphics.drawTexturedRect3D(null, this.horizontalSideWalkTexture, sideWalkRect, calcTopRect(sideWalkRect, 1.02));
            }
        }
        // right sidewalk
        if (this.mazePos.x < Maze.maze.maze[0].len-1) {
            var isDrawn = false;
            if (this.mazePos.y-1 >= 0 and this.mazePos.y+1 <= Maze.maze.maze.len-1) {
                if (Maze.maze.maze[@floatToInt(usize, this.mazePos.y-1)][@floatToInt(usize, this.mazePos.x)] != 1 and
                    Maze.maze.maze[@floatToInt(usize, this.mazePos.y)][@floatToInt(usize, this.mazePos.x+1)] != 1 and
                    Maze.maze.maze[@floatToInt(usize, this.mazePos.y+1)][@floatToInt(usize, this.mazePos.x)] != 1) {
                    isDrawn = true;
                    const sideWalkPos: Vector2 = Vector2 {.x= this.rect.topRight().x, .y= this.rect.pos().y-sideWalkWidth,};
                    const sideWalkRect: Rectangle = Rectangle {.x= sideWalkPos.x, .y= sideWalkPos.y, .width= verticalSideWalkSize.x, .height= verticalSideWalkSize.y+sideWalkWidth*2};
                    Graphics.drawTexturedRect3D(null, &TextureLoader.longVerticalSideWalkTexture, sideWalkRect, calcTopRect(sideWalkRect, 1.02));
                }
            }
            if (!isDrawn and Maze.maze.maze[@floatToInt(usize, this.mazePos.y)][@floatToInt(usize, this.mazePos.x+1)] != 1) {
                const sideWalkPos: Vector2 = Vector2 {.x= this.rect.topRight().x, .y= this.rect.pos().y,};
                const sideWalkRect: Rectangle = Rectangle {.x= sideWalkPos.x, .y= sideWalkPos.y, .width= verticalSideWalkSize.x, .height= verticalSideWalkSize.y};
                Graphics.drawTexturedRect3D(null, this.verticalSideWalkTexture, sideWalkRect, calcTopRect(sideWalkRect, 1.02));
            }
        }
        // bottom sidewalk
        if (this.mazePos.y < Maze.maze.maze.len-1) {
            var isDrawn = false;
            if (this.mazePos.y-1 >= 0 and this.mazePos.y+1 <= Maze.maze.maze.len-1) {
                if (Maze.maze.maze[@floatToInt(usize, this.mazePos.y)][@floatToInt(usize, this.mazePos.x-1)] != 1 and
                    Maze.maze.maze[@floatToInt(usize, this.mazePos.y+1)][@floatToInt(usize, this.mazePos.x)] != 1 and
                    Maze.maze.maze[@floatToInt(usize, this.mazePos.y)][@floatToInt(usize, this.mazePos.x+1)] != 1) {
                    isDrawn = true;
                    const sideWalkPos: Vector2 = Vector2 {.x= this.rect.bottomLeft().x-sideWalkWidth, .y= this.rect.bottomLeft().y,};
                    const sideWalkRect: Rectangle = Rectangle {.x= sideWalkPos.x, .y= sideWalkPos.y, .width= horizontalSideWalkSize.x+sideWalkWidth*2, .height= horizontalSideWalkSize.y};
                    Graphics.drawTexturedRect3D(null, &TextureLoader.longHorizontalSideWalkTexture, sideWalkRect, calcTopRect(sideWalkRect, 1.02));
                }
            }
            if (!isDrawn and Maze.maze.maze[@floatToInt(usize, this.mazePos.y+1)][@floatToInt(usize, this.mazePos.x)] != 1) {
                const sideWalkPos: Vector2 = Vector2 {.x= this.rect.bottomLeft().x, .y= this.rect.bottomLeft().y,};
                const sideWalkRect: Rectangle = Rectangle {.x= sideWalkPos.x, .y= sideWalkPos.y, .width= horizontalSideWalkSize.x, .height= horizontalSideWalkSize.y};
                Graphics.drawTexturedRect3D(null, this.horizontalSideWalkTexture, sideWalkRect, calcTopRect(sideWalkRect, 1.02));
            }
        }
    }
};

pub const maxWalls: usize = 1_000;
pub const priorityWallLength: usize = 50;
pub const heightScaleAmount: f32 = 1.15;
pub var walls: std.ArrayList(Wall) = undefined;