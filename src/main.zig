const std = @import("std");
const rl = @import("raylib");

const tof32 = @import("util.zig").tof32;
const toi32 = @import("util.zig").toi32;


const MAX_BUILDINGS = 100;

// Exemplo de acesso em structs.
fn foo() void {
    const a: rl.Vector2 = .{.x = 0, .y = 0};
    const b = rl.Vector2.init(0, 0);
    const c = rl.Vector2{.x = 0, .y = 0};
    const d: rl.Vector2 = .init(0, 0);
    const e: rl.Vector2 = .{0, 0};
    const f: rl.Vector2 = @bitCast([_]f32{0,0});
    const g = .{.x = 0, .y = 0};

    _ = .{a, b, c, d, e, f, g}; 
}


const Player = struct {
    pos: rl.Vector2,
    vel: rl.Vector2 = rl.Vector2.init(0, 0),
    
    aceleracao: f16,
    vel_max: f16,

    sprite: rl.Texture2D
};



fn getWasd() rl.Vector2 {
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


fn mover(pos: *rl.Vector2, vel: *rl.Vector2, vel_max: f32, aceleracao: f32, direcao: rl.Vector2) void {
    var direcao_clamped = direcao.normalize();
    vel.* = vel.lerp(direcao_clamped.scale(vel_max), aceleracao * rl.getFrameTime());
    pos.* = pos.add(vel.*);
}


fn draw(sprite: rl.Texture2D, pos: rl.Vector2, vel: rl.Vector2) void {
    const rot: f32 = 
        if (vel.equals(rl.Vector2.init(0, 0)) == 0) 
            -vel.angle(rl.Vector2.init(0, -1)) * (180.0 / 3.141516) 
        else 
            0;

    const tex_offset = rl.Vector2.init(
        tof32(@divFloor(sprite.width, 2)),
        tof32(@divFloor(sprite.height, 2))
    );

    // std.debug.print("{any}\n", .{rot});
    sprite.drawPro(
        rl.Rectangle.init(
            0, 
            0, 
            tof32(sprite.width), 
            tof32(sprite.height)
        ),
        rl.Rectangle.init(
            pos.x, 
            pos.y, 
            tof32(sprite.width), 
            tof32(sprite.height)
        ),
        tex_offset,
        rot,
        rl.Color.white
    );
}


fn moveCamera(c: *rl.Camera2D, pos: rl.Vector2) void {
    // c.target = rl.Vector2.init(@trunc(pos.x), @trunc(pos.y)).scale(virtualRatio);
    // c.target = rl.Vector2.init(@trunc(pos.x), @trunc(pos.y));
    c.target = pos;
}

fn rotateCamera(c: *rl.Camera2D) void {
    if (rl.isKeyDown(.e)) {
        c.rotation -= 1;
    } else if (rl.isKeyDown(.q)) {
        c.rotation += 1;
    }
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

    // ScreenCamera
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
    const virtualRatio: f32 = tof32(screenWidth) / tof32(worldCameraWidth);
    const sourceRec = rl.Rectangle.init(
        0, 
        0,
        tof32(worldCameraWidth),
        -tof32(worldCameraHeight)
            // The target's height is flipped (in the source Rectangle), due to OpenGL reasons
    );
    var destRec = rl.Rectangle.init(
        -virtualRatio, 
        -virtualRatio,
        tof32(screenWidth) + (virtualRatio * 2),
        tof32(screenHeight) + (virtualRatio * 2)
    );


//--------------------------------------------------------------------------------------
// Entidades
//--------------------------------------------------------------------------------------

    // Player
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
    };

    
    // Buildings
    var buildings: [MAX_BUILDINGS]rl.Rectangle = undefined;
    var buildColors: [MAX_BUILDINGS]rl.Color = undefined;

    var spacing: i32 = 0;

    for (0..buildings.len) |i| {
        buildings[i].width = tof32(rl.getRandomValue(50, 200));
        buildings[i].height = tof32(rl.getRandomValue(100, 800));
        buildings[i].y = tof32(screenHeight) - 130 - buildings[i].height;
        buildings[i].x = tof32(-6000 + spacing);

        spacing += toi32(buildings[i].width);

        buildColors[i] = rl.Color.init(
            @as(u8, @intCast(rl.getRandomValue(200, 240))),
            @as(u8, @intCast(rl.getRandomValue(200, 240))),
            @as(u8, @intCast(rl.getRandomValue(200, 250))),
            255,
        );
    }

    // Imagem da pista
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
        mover(&player.pos, &player.vel, player.vel_max, player.aceleracao, getWasd());

        // WorldCamera
        moveCamera(&worldCamera, player.pos);
        zoomCamera(&worldCamera);
        rotateCamera(&worldCamera);
        if (rl.isWindowResized()) {
            destRec = rl.Rectangle.init(-virtualRatio, -virtualRatio, 
                tof32(rl.getScreenWidth()) + (virtualRatio * 2), 
                tof32(rl.getScreenHeight()) + (virtualRatio * 2));

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
            draw(player.sprite, player.pos, player.vel);

            // Crosshair.
            rl.drawLine(
                toi32(worldCamera.target.x),
                -worldCameraHeight * 10,
                toi32(worldCamera.target.x),
                worldCameraHeight * 10,
                rl.Color.green,
            );
            rl.drawLine(
                -worldCameraWidth * 10,
                toi32(worldCamera.target.y),
                worldCameraWidth * 10,
                toi32(worldCamera.target.y),
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

