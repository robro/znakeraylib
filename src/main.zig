const std = @import("std");
const rl = @import("raylib.zig");
const objects = @import("objects/objects.zig");
const math = @import("math.zig");
const misc = @import("misc.zig");
const enums = @import("enums.zig");

const Grid = objects.grid.Grid;
const Snake = objects.snake.Snake;
const Food = objects.food.Food;
const State = objects.state.State;
const Direction = enums.Direction;
const Vec2 = math.Vec2;

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
    const start_len: usize = 3;
    const start_pos = Vec2{ .x = grid_width - 4, .y = 5 };
    const start_facing = Direction.LEFT;

    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT | rl.FLAG_VSYNC_HINT);
    rl.InitWindow(win_width, win_height, "Znake");
    defer rl.CloseWindow();

    const font_color: rl.Color = rl.WHITE;
    const font = rl.LoadFontEx("resources/fonts/consola.ttf", font_size, null, 0);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var grid = try Grid.create(grid_width, grid_height, &allocator);
    defer grid.free(&allocator);
    grid.clear();

    const grid_buf = try allocator.allocSentinel(u8, (grid_width + 1) * grid_height, 0);
    defer allocator.free(grid_buf);

    const hud_buf = try allocator.allocSentinel(u8, 30, 0);
    defer allocator.free(hud_buf);

    var snake = try Snake.create(start_len, start_pos, start_facing, &allocator);
    defer snake.free();
    snake.draw(&grid); // Prevent food from spawning on top of snake

    var food = try Food.create(misc.getChar(snake.len()), &grid);
    var state = try State.create(&grid, &snake, &food, start_fps, fg_colors.len, &allocator);
    defer state.free(&allocator);

    while (!rl.WindowShouldClose()) {
        // Input --------------------------------------------------------------
        state.handleInput(rl.GetKeyPressed());

        // Update -------------------------------------------------------------
        try state.update();

        // Draw ---------------------------------------------------------------
        rl.BeginDrawing();
        rl.ClearBackground(bg_colors[state.randIdx()]);

        try state.printHUD(&hud_buf);
        rl.DrawTextEx(font, hud_buf, .{ .x = margin, .y = margin + 8 }, font_size, 0, fg_colors[state.randIdx()]);
        rl.DrawRectangle(0, hud_height, win_width, win_height, fg_colors[state.randIdx()]);
        try state.printGrid(&grid_buf);
        rl.DrawTextEx(font, grid_buf, .{ .x = margin, .y = hud_height + margin }, font_size, margin, font_color);

        rl.EndDrawing();
    }
}
