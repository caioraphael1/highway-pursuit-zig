const Core = @import("Core.zig");

const rl = Core.Raylib;

const Vector2 = rl.Vector2;
const Texture = rl.Texture;
const Color = rl.Color;

pub const Car = struct {
    position: Vector2 = .{ .x = 0.0, .y = 0.0 },
    scale: f32 = 1.0,
    rotation: f32 = 0.0,
    frameIndex: i32 = 0.0,
    texture: Texture,

    pub fn init(textureFileName: [:0]const u8) anyerror!Car {
        return Car{
            .texture = try rl.loadTexture(textureFileName),
        };
    }

    pub fn deinit(self: Car) void {
        self.texture.unload();
    }

    pub fn draw(self: Car) void {
        const frameX = @as(f32, @floatFromInt(@divTrunc(self.frameIndex, 7)));
        const frameY = @as(f32, @floatFromInt(@mod(self.frameIndex, 7)));

        self.texture.drawPro(
            .{
                .x = frameY * 100.0,
                .y = frameX * 100.0,
                .width = 100.0,
                .height = 100.0,
            },
            .{
                .x = self.position.x,
                .y = self.position.y,
                .width = self.scale * 100.0,
                .height = self.scale * 100.0,
            },
            .{ .x = 0.0, .y = 0.0 },
            self.rotation,
            Color.white,
        );
    }

    pub fn width(self: Car) f32 {
        return 100.0 * self.scale;
    }

    pub fn height(self: Car) f32 {
        return 100.0 * self.scale;
    }
};
