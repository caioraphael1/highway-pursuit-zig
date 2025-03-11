const Core = @import("core.zig");

const rl = Core.Raylib;
const Car = Core.Car;
const Debug = Core.Debug;

const Color = rl.Color;
const KeyboardKey = rl.KeyboardKey;
const Vector2 = rl.Vector2;
const Texture = rl.Texture2D;
const Rectangle = rl.Rectangle;

pub fn main() anyerror!void {
    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(1280, 720, "Highway Pursuit");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var debug = Debug{};

    var carrinho = try Car.init("S:/zig/highway-pursuit-zig/assets/textures/carrinho.png");
    defer carrinho.deinit();

    while (!rl.windowShouldClose()) {
        // Input
        if (rl.isKeyReleased(KeyboardKey.f1)) {
            debug.isVisible = !debug.isVisible;
        }

        // Update
        debug.height = @as(f32, @floatFromInt(rl.getScreenHeight()));

        if (debug.carShouldRotate) {
            // Anima os frames e garante que não exceda o total
            carrinho.frameIndex += 1;
            if (carrinho.frameIndex >= 48) {
                carrinho.frameIndex = 0;
            }
        }
        carrinho.scale = debug.carScale;
        carrinho.position = .{
            .x = (@as(f32, @floatFromInt(rl.getScreenWidth())) - carrinho.width()) * 0.5,
            .y = (@as(f32, @floatFromInt(rl.getScreenHeight())) - carrinho.height()) * 0.5,
        };

        // Draw
        rl.beginDrawing();

        carrinho.draw();
        debug.draw();

        rl.clearBackground(Color.ray_white);
        rl.endDrawing();
    }
}
