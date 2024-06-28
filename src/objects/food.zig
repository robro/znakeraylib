const std = @import("std");
const objects = @import("objects.zig");
const math = @import("../math.zig");
const scratch = @import("../scratch.zig");

const Board = objects.board.Board;
const Position = math.Position;
const rng = std.crypto.random;

pub const Food = struct {
    char: u8,
    pos: Position,

    pub fn draw(self: *Food, board: *Board) void {
        board.array[@as(usize, @intCast(self.pos.y)) * board.cols + @as(usize, @intCast(self.pos.x))] = self.char;
    }
};

pub fn spawnFood(char: u8, board: *Board) !Food {
    var buf = try scratch.scratchBuf(board.array.len);
    var empty_count: usize = 0;
    for (board.array, 0..) |*c, board_idx| {
        if (c.* != ' ') continue;
        buf[empty_count] = @intCast(board_idx);
        empty_count += 1;
    }
    if (empty_count == 0) return error.NoFreePositions;
    const rand_idx = buf[rng.uintLessThan(usize, empty_count)];
    return Food{
        .char = char,
        .pos = .{
            .x = @intCast(rand_idx % board.cols),
            .y = @intCast(rand_idx / board.cols),
        },
    };
}
