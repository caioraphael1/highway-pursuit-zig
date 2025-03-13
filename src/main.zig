const std = @import("std");
const rl = @import("raylib");

const i2f32 = @import("util.zig").i2f32;
const f2i32 = @import("util.zig").f2i32;


const MAX_BUILDINGS = 100;


fn getWASD() rl.Vector2 {
    var vel = rl.Vector2.init(0, 0);
    if (rl.isKeyDown(.d)) {
        vel.x = 1;
    } else if (rl.isKeyDown(.a)) {
        vel.x = -1;
    }
    if (rl.isKeyDown(.s)) {
        vel.y = 1;
    } else if (rl.isKeyDown(.w)) {
        vel.y = -1;
    }
    return vel;
}


const Player = struct {
    pos: rl.Vector2,
    vel: rl.Vector2 = rl.Vector2.init(0, 0),

    aceleracao: f16,
    vel_max: f16,

    sprite: rl.Texture2D,

    fn mover(self: *Player, direcao: rl.Vector2) void {
        var direcao_clamped = direcao.normalize();
        self.vel = self.vel.lerp(direcao_clamped.scale(self.vel_max), self.aceleracao * rl.getFrameTime());
        self.pos = self.pos.add(self.vel);
    }

    fn draw(self: *Player) void {
        const rot: f32 = if (self.vel.equals(rl.Vector2.init(0, 0)) == 0) -self.vel.angle(rl.Vector2.init(0, -1))*(180.0/3.141516) else 0;

        const tex_offset = rl.Vector2.init(
            i2f32(@divFloor(self.sprite.width, 2)),
            i2f32(@divFloor(self.sprite.height, 2))
        );

        const pos = self.pos.subtract(tex_offset);

        std.debug.print("{any}\n", .{rot});
        self.sprite.drawPro(
            rl.Rectangle.init(
                0, 
                0, 
                i2f32(self.sprite.width), 
                i2f32(self.sprite.height)
            ),
            rl.Rectangle.init(
                pos.x + tex_offset.x, 
                pos.y + tex_offset.y, 
                i2f32(self.sprite.width), 
                i2f32(self.sprite.height)
            ),
            tex_offset,
            rot,
            rl.Color.white
        );
    }
};




fn moveCamera(c: *rl.Camera2D, player: Player) void {
    const target = rl.Vector2.init(player.pos.x, player.pos.y);
    // c.target = rl.Vector2.init(@trunc(target.x), @trunc(target.y)).scale(virtualRatio);
    c.target = rl.Vector2.init(@trunc(target.x), @trunc(target.y));
}

fn rotateCamera(c: *rl.Camera2D) void {
    // Camera rotation controls
    if (rl.isKeyDown(.e)) {
        c.rotation -= 1;
    } else if (rl.isKeyDown(.q)) {
        c.rotation += 1;
    }
    // Limit c rotation to 80 degrees (-40 to 40)
    c.rotation = rl.math.clamp(c.rotation, -40, 40);
}

fn zoomCamera(c: *rl.Camera2D) void {
    // Camera zoom controls
    c.zoom += rl.getMouseWheelMove() * 0.05;
    c.zoom = rl.math.clamp(c.zoom, 0.1, 3.0);

    // Camera reset (zoom and rotation)
    if (rl.isKeyPressed(.r)) {
        c.zoom = 1.0;
        // c.rotation = 0.0;
    }
}

fn canvasDraw(w: i32, h: i32) void {
    rl.drawText("SCREEN AREA", @divFloor(w, 2) - @as(i32, 80), 10, 20, rl.Color.red);

    rl.drawRectangle(0,     0,      w,      5,      rl.Color.red);
    rl.drawRectangle(0,     5,      5,      h - 10, rl.Color.red);
    rl.drawRectangle(w - 5, 5,      5,      h - 10, rl.Color.red);
    rl.drawRectangle(0,     h - 5,  w,      5,      rl.Color.red);

    rl.drawRectangle(10, 10, 250, 113, rl.Color.sky_blue.fade(0.5));
    rl.drawRectangleLines(10, 10, 250, 113, rl.Color.blue);

    rl.drawText("Controls:", 20, 20, 10, rl.Color.black);
    rl.drawText("- WASD to move player", 40, 40, 10, rl.Color.dark_gray);
    rl.drawText("- Mouse Wheel to Zoom in-out", 40, 60, 10, rl.Color.dark_gray);
    rl.drawText("- R to reset Zoom and Rotation", 40, 100, 10, rl.Color.dark_gray);
    rl.drawText("- Q / E to rotate camera", 40, 80, 10, rl.Color.dark_gray);
}


pub fn main() anyerror!void {
//--------------------------------------------------------------------------------------
// Initialization
//--------------------------------------------------------------------------------------
    const print = std.debug.print;
    const cwd = rl.getWorkingDirectory();

    const allocator = std.heap.page_allocator;


    const screenWidth: i32 = 1280;
    const screenHeight: i32 = 720;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - 2d screenCamera");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60);

    rl.setWindowState(.{ 
        .window_resizable = true, 
        // .window_transparent = true, 
        // .window_undecorated = true 
        });

    var screenCamera = rl.Camera2D{
        .target = rl.Vector2.init(0, 0),
        .offset = rl.Vector2.init(0, 0),
        .rotation = 0,
        .zoom = 1,
    };

    // WorldCamera
    const worldCameraWidth = 480;
    const worldCameraHeight = 270;
    var worldCamera = rl.Camera2D{
        .target = rl.Vector2.init(0, 0),
        .offset = rl.Vector2.init(worldCameraWidth / 2, worldCameraHeight / 2),
        .rotation = 0,
        .zoom = 1
    };

    // RenderTex
    const renderTex = try rl.loadRenderTexture(worldCameraWidth, worldCameraHeight);
    const virtualRatio: f32 = i2f32(screenWidth) / i2f32(worldCameraWidth);
    const sourceRec = rl.Rectangle.init(
        0, 
        0,
        i2f32(worldCameraWidth),
        -i2f32(worldCameraHeight)
            // The target's height is flipped (in the source Rectangle), due to OpenGL reasons
    );
    var destRec = rl.Rectangle.init(
        -virtualRatio, 
        -virtualRatio,
        i2f32(screenWidth) + (virtualRatio * 2),
        i2f32(screenHeight) + (virtualRatio * 2)
    );


//--------------------------------------------------------------------------------------
// Entidades
//--------------------------------------------------------------------------------------

    const tex_name: [:0]const u8 = try std.fmt.allocPrintZ(allocator, "{s}{s}", .{cwd, "/assets/race-car.png"});
    defer allocator.free(tex_name);
    const player_sprite = rl.Texture2D.init(tex_name) catch {
        print("Tex não encontrada.\n", .{});
        rl.waitTime(50);
        return;
    };
    defer player_sprite.unload();

    var player: Player = .{
        .pos = rl.Vector2.init(0, 0),

        .aceleracao = 2,
        .vel_max = 10,

        .sprite = player_sprite,

        // .cam = worldCamera,
    };

    var buildings: [MAX_BUILDINGS]rl.Rectangle = undefined;
    var buildColors: [MAX_BUILDINGS]rl.Color = undefined;

    var spacing: i32 = 0;

    for (0..buildings.len) |i| {
        buildings[i].width = i2f32(rl.getRandomValue(50, 200));
        buildings[i].height = i2f32(rl.getRandomValue(100, 800));
        buildings[i].y = i2f32(screenHeight) - 130 - buildings[i].height;
        buildings[i].x = i2f32(-6000 + spacing);

        spacing += f2i32(buildings[i].width);

        buildColors[i] = rl.Color.init(
            @as(u8, @intCast(rl.getRandomValue(200, 240))),
            @as(u8, @intCast(rl.getRandomValue(200, 240))),
            @as(u8, @intCast(rl.getRandomValue(200, 250))),
            255,
        );
    }

    // Imagem
    const str: [:0]const u8 = try std.fmt.allocPrintZ(allocator, "{s}{s}", .{cwd, "/assets/pista.png"});
    defer allocator.free(str);
    const imagem = rl.Texture2D.init(str) catch {
        print("oops\n", .{});
        rl.waitTime(50);
        return;
    };
    defer imagem.unload();

//--------------------------------------------------------------------------------------
// GameLoop
//--------------------------------------------------------------------------------------
    while (!rl.windowShouldClose()) {
    //----------------------------------------------------------------------------------
    // Update
    //----------------------------------------------------------------------------------

        // Player
        const direcao_mov = getWASD();
        player.mover(direcao_mov);

        // WorldCamera
        moveCamera(&worldCamera, player);
        zoomCamera(&worldCamera);
        rotateCamera(&worldCamera);

        if (rl.isWindowResized()) {
            destRec   = rl.Rectangle.init(-virtualRatio, -virtualRatio, 
                i2f32(rl.getScreenWidth()) + (virtualRatio * 2), 
                i2f32(rl.getScreenHeight()) + (virtualRatio * 2));

        }

    //----------------------------------------------------------------------------------
    // Draw
    //----------------------------------------------------------------------------------

        // RenderTexture
        {
            rl.beginTextureMode(renderTex);
            defer rl.endTextureMode();

            rl.clearBackground(rl.Color.ray_white);

            worldCamera.begin();
            defer worldCamera.end();

            // Construções.
            for (buildings, 0..) |building, i| {
                rl.drawRectangleRec(building, buildColors[i]);
            }

            rl.drawRectangle(-6000, 320, 13000, 8000, rl.Color.dark_gray);
            rl.drawTextureRec(imagem, rl.Rectangle.init(50, 40, 320, 180), rl.Vector2.init(40, 40), rl.Color.init(120, 255, 255, 255));

            // Player.
            player.draw();

            // Crosshair.
            rl.drawLine(
                f2i32(worldCamera.target.x),
                -worldCameraHeight * 10,
                f2i32(worldCamera.target.x),
                worldCameraHeight * 10,
                rl.Color.green,
            );
            rl.drawLine(
                -worldCameraWidth * 10,
                f2i32(worldCamera.target.y),
                worldCameraWidth * 10,
                f2i32(worldCamera.target.y),
                rl.Color.green,
            );

        }
        
        {
            rl.beginDrawing();
            defer rl.endDrawing();

            {
                screenCamera.begin();
                defer screenCamera.end();

                rl.clearBackground(rl.Color.white);

                rl.drawTexturePro(renderTex.texture, sourceRec, destRec, screenCamera.target, screenCamera.rotation, rl.Color.white);
            }

            canvasDraw(rl.getScreenWidth(), rl.getScreenHeight());

        }
    }
}

