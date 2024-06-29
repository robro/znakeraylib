const std = @import("std");
const rl = @import("raylib.zig");
const objects = @import("objects/objects.zig");
const math = @import("math.zig");
const misc = @import("misc.zig");
const enums = @import("enums.zig");

const Board = objects.board.Board;
const Snake = objects.snake.Snake;
const Food = objects.food.Food;
const State = objects.state.State;
const Direction = enums.Direction;
const Position = math.Position;

const grid_cols = 12;
const grid_rows = 12;
const hud_height: c_int = @intFromFloat(font_size * 2);
const win_width: c_int = (grid_cols + 1) * @as(c_int, (@intFromFloat(font_size)));
const win_height: c_int = (grid_rows + 1) * @as(c_int, (@intFromFloat(font_size))) + hud_height;
const margin: f32 = font_size / 2;
const fg_colors = [5]rl.Color{ rl.DARKBLUE, rl.DARKBROWN, rl.DARKGRAY, rl.DARKGREEN, rl.DARKPURPLE };
const bg_colors = [5]rl.Color{ rl.BLUE, rl.BROWN, rl.GRAY, rl.GREEN, rl.PURPLE };
const font_color: rl.Color = rl.WHITE;
const font_size: f32 = 64;
const font_path = "resources/fonts/consola.ttf";
const snake_len: usize = 3;
const snake_pos = Position{ .x = grid_cols - 4, .y = 5 };
const snake_facing = Direction.LEFT;
const start_fps: c_int = 8;
var font: ?rl.Font = null;

pub fn main() !void {
    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT | rl.FLAG_VSYNC_HINT);
    rl.InitWindow(win_width, win_height, "Znake");
    defer rl.CloseWindow();

    font = rl.LoadFontEx(font_path, font_size, null, 0);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var board = try objects.board.spawnBoard(grid_cols, grid_rows, &allocator);
    defer board.free(&allocator);

    var snake = try objects.snake.spawnSnake(snake_len, snake_pos, snake_facing, &allocator);
    defer snake.free();
    snake.draw(&board); // Prevent food from spawning on top of snake

    var state = try objects.state.spawnState(&board, &snake, start_fps, fg_colors.len, &allocator);
    defer state.free(&allocator);

    while (!rl.WindowShouldClose()) {
        handleInput(&state);
        try update(&state);
        try draw(&state);
    }
}

fn handleInput(state: *State) void {
    state.handleInput(rl.GetKeyPressed());
}

fn update(state: *State) !void {
    try state.update();
}

fn draw(state: *State) !void {
    rl.BeginDrawing();
    defer rl.EndDrawing();
    rl.ClearBackground(bg_colors[state.randIdx()]);
    rl.DrawTextEx(
        if (font == null) rl.GetFontDefault() else font.?,
        try state.scoreString(),
        .{ .x = margin, .y = margin + 8 },
        font_size,
        0,
        fg_colors[state.randIdx()],
    );
    rl.DrawRectangle(
        0,
        hud_height,
        win_width,
        win_height,
        fg_colors[state.randIdx()],
    );
    rl.DrawTextEx(
        if (font == null) rl.GetFontDefault() else font.?,
        try state.boardString(),
        .{ .x = margin, .y = hud_height + margin },
        font_size,
        margin,
        font_color,
    );
}
