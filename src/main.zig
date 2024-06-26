const std = @import("std");
const rl = @import("raylib.zig");
const Grid = @import("grid.zig");
const Snake = @import("snake.zig");
const Food = @import("food.zig");
const State = @import("state.zig");

pub fn main() !void {
    // Init -------------------------------------------------------------------
    const font_size: f32 = 64;
    const grid_width = 12; // chars
    const grid_height = 12; // chars
    const hud_height: c_int = @intFromFloat(font_size * 2);
    const win_width: c_int = (grid_width + 1) * @as(c_int, (@intFromFloat(font_size)));
    const win_height: c_int = (grid_height + 1) * @as(c_int, (@intFromFloat(font_size))) + hud_height;
    const margin: f32 = font_size / 2;

    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT | rl.FLAG_VSYNC_HINT);
    rl.InitWindow(win_width, win_height, "Znake");
    defer rl.CloseWindow();

    const font = rl.LoadFontEx("resources/fonts/consola.ttf", font_size, null, 0);
    const font_color: rl.Color = rl.WHITE;
    const bg_color: rl.Color = rl.DARKBROWN;
    const grid_color: rl.Color = rl.BROWN;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var grid = try Grid.create(' ', grid_width, grid_height, &allocator);
    defer grid.free(&allocator);

    const grid_buf = try allocator.allocSentinel(u8, (grid_width + 1) * grid_height, 0);
    defer allocator.free(grid_buf);

    const hud_buf = try allocator.allocSentinel(u8, 30, 0);
    defer allocator.free(hud_buf);

    var snake = try Snake.create('0', 4, .{ .x = 4, .y = 2 }, &allocator);
    defer snake.free();

    var food = Food.create(&grid);
    var state = try State.create(&grid, &snake, &food);

    rl.SetTargetFPS(10);

    while (!rl.WindowShouldClose()) {
        // Input --------------------------------------------------------------
        state.handleInput(rl.GetKeyPressed());

        // Update -------------------------------------------------------------
        state.update();

        // Draw ---------------------------------------------------------------
        rl.BeginDrawing();
        rl.ClearBackground(bg_color);

        try state.printHUD(&hud_buf);
        rl.DrawTextEx(font, hud_buf, .{ .x = margin, .y = margin }, font_size, 0, font_color);

        rl.DrawRectangle(0, hud_height, win_width, win_height, grid_color);

        try state.printGrid(&grid_buf);
        rl.DrawTextEx(font, grid_buf, .{ .x = margin, .y = hud_height + margin }, font_size, margin, font_color);

        rl.EndDrawing();
    }
}
