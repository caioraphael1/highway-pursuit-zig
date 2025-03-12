const std = @import("std");

const rl = @import("raylib");

pub fn main() anyerror!void {
    const print = std.debug.print;
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 320;
    const screenHeight = 180;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setWindowState(.{ 
        .window_resizable = true, 
        // .window_transparent = true, 
        // .window_undecorated = true 
        });

    rl.maximizeWindow();

    rl.setTargetFPS(60);

    //--------------------------------------------------------------------------------------
    const imagem = rl.Texture2D.init("C:/Users/caior/Desktop/highway-pursuit-zig/assets/pista.png") catch {
        print("oops", .{});
        rl.waitTime(50);
        return;
    };
    defer imagem.unload();

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.drawTextureRec(imagem, rl.Rectangle.init(50, 40, 320, 180), rl.Vector2.init(40, 40), rl.Color.init(120, 255, 255, 255));

        rl.clearBackground(rl.Color.white);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, rl.Color.light_gray);
        //----------------------------------------------------------------------------------
    }
}
