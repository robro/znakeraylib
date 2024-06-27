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
    const fg_colors = [5]rl.Color{ rl.DARKBLUE, rl.DARKBROWN, rl.DARKGRAY, rl.DARKGREEN, rl.DARKPURPLE };
    const bg_colors = [5]rl.Color{ rl.BLUE, rl.BROWN, rl.GRAY, rl.GREEN, rl.PURPLE };
    const start_fps: c_int = 8;

    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT | rl.FLAG_VSYNC_HINT);
    rl.InitWindow(win_width, win_height, "Znake");
    defer rl.CloseWindow();

    const font_color: rl.Color = rl.WHITE;
    const font = rl.LoadFontEx("resources/fonts/consola.ttf", font_size, null, 0);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var grid = try Grid.create(grid_width, grid_height, &allocator);
    grid.clear();
    defer grid.free(&allocator);

    const grid_buf = try allocator.allocSentinel(u8, (grid_width + 1) * grid_height, 0);
    defer allocator.free(grid_buf);

    const hud_buf = try allocator.allocSentinel(u8, 30, 0);
    defer allocator.free(hud_buf);

    var snake = try Snake.create('Z', 4, .{ .x = 4, .y = 2 }, &allocator);
    defer snake.free();

    var food = try Food.create(&grid);
    var state = try State.create(&grid, &snake, &food, start_fps, fg_colors.len);

    while (!rl.WindowShouldClose()) {
        // Input --------------------------------------------------------------
        state.handleInput(rl.GetKeyPressed());

        // Update -------------------------------------------------------------
        try state.update();

        // Draw ---------------------------------------------------------------
        rl.BeginDrawing();
        rl.ClearBackground(bg_colors[state.color_index]);

        try state.printHUD(&hud_buf);
        rl.DrawTextEx(font, hud_buf, .{ .x = margin, .y = margin + 8 }, font_size, 0, fg_colors[state.color_index]);
        rl.DrawRectangle(0, hud_height, win_width, win_height, fg_colors[state.color_index]);
        try state.printGrid(&grid_buf);
        rl.DrawTextEx(font, grid_buf, .{ .x = margin, .y = hud_height + margin }, font_size, margin, font_color);

        rl.EndDrawing();
    }
}
