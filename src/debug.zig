const Core = @import("core.zig");

const rl = Core.Raylib;
const rg = Core.Raygui;

const Vector2 = rl.Vector2;
const Rectangle = rl.Rectangle;

pub const Debug = struct {
    windowAnchor: Vector2 = .{ .x = 0.0, .y = 0.0 },

    buttonHeight: f32 = 32.0,
    titleBarHeight: f32 = 32.0,

    width: f32 = 200.0,
    height: f32 = 200.0,
    margin: f32 = 10.0,
    padding: f32 = 10.0,

    isVisible: bool = true,

    carShouldRotate: bool = false,
    carScale: f32 = 1.0,

    pub fn draw(self: *Debug) void {
        const bounds = Rectangle{
            .x = self.windowAnchor.x + self.margin,
            .y = self.windowAnchor.y + self.margin,
            .width = self.width - 2 * self.margin,
            .height = self.height - 2 * self.margin,
        };

        if (self.isVisible) {
            const isVisible = rg.guiWindowBox(bounds, "Debug Window");
            if (isVisible != 0) {
                self.isVisible = false;
            }

            const carBoxBounds = Rectangle{
                .x = bounds.x + self.padding,
                .y = bounds.y + self.padding + self.titleBarHeight,
                .width = bounds.width - 2 * self.padding,
                .height = bounds.height - 2 * self.padding - self.titleBarHeight,
            };
            _ = rg.guiGroupBox(carBoxBounds, "Car");

            const carButtonBounds = Rectangle{
                .x = carBoxBounds.x + self.padding,
                .y = carBoxBounds.y + self.padding,
                .width = carBoxBounds.width - 2 * self.padding,
                .height = self.buttonHeight,
            };
            _ = rg.guiToggle(carButtonBounds, "Toggle Animation", &self.carShouldRotate);

            const carScaleSliderBounds = Rectangle{
                .x = carButtonBounds.x + 16.0,
                .y = carButtonBounds.y + carButtonBounds.height + self.padding,
                .width = carButtonBounds.width - 32.0,
                .height = self.buttonHeight,
            };
            _ = rg.guiSlider(
                carScaleSliderBounds,
                "0.5",
                "10.0",
                &self.carScale,
                0.5,
                10.0,
            );
        }
    }
};
