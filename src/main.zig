const std = @import("std");
const rl = @import("raylib.zig");
const Grid = @import("grid.zig").Grid;
const Snake = @import("snake.zig").Snake;
const Food = @import("food.zig").Food;

pub fn main() !void {
    // Init -------------------------------------------------------------------
    const win_width = 800; // pixels
    const win_height = 800; // pixels
    const grid_width = 20; // chars
    const grid_height = 20; // chars

    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT | rl.FLAG_VSYNC_HINT);
    rl.InitWindow(win_width, win_height, "Znake");
    defer rl.CloseWindow();

    const font = rl.LoadFont("resources/fonts/consola.ttf");
    const font_color: rl.Color = rl.WHITE;
    const bg_color: rl.Color = rl.DARKBROWN;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var grid = try Grid.create(grid_width, grid_height, allocator);
    defer grid.free(allocator);

    const grid_buf = try allocator.allocSentinel(u8, (grid_width + 1) * grid_height, 0);
    defer allocator.free(grid_buf);
    const grid_char: u8 = '.';

    var snake = try Snake.create(10, .{ .x = 10, .y = 10 }, allocator);
    defer snake.free();

    const rng = std.crypto.random;
    var food = Food.create(rng, grid);

    rl.SetTargetFPS(10);

    while (!rl.WindowShouldClose()) {
        // Input --------------------------------------------------------------
        snake.handleInput(rl.GetKeyPressed());

        // Update -------------------------------------------------------------
        snake.update();
        if (std.meta.eql(snake.head, food.pos)) {
            snake.grow();
            food.reset(rng, grid);
        }

        // Draw ---------------------------------------------------------------
        rl.BeginDrawing();

        rl.ClearBackground(bg_color);
        grid.fill(grid_char);
        snake.printToGrid(&grid);
        food.printToGrid(&grid);
        try grid.toString(&grid_buf);
        rl.DrawTextEx(font, grid_buf, .{ .x = 78, .y = 64 }, 32, 16, font_color);

        rl.EndDrawing();
    }
}
