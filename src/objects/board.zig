const std = @import("std");
const math = @import("../math.zig");
const scratch = @import("../scratch.zig");

const Allocator = std.mem.Allocator;
const Position = math.Position;

pub const Board = struct {
    cols: usize,
    rows: usize,
    array: []u8,

    pub fn clear(self: *Board) void {
        fill(' ', self.array);
    }

    pub fn free(self: *Board, allocator: *const Allocator) void {
        allocator.free(self.array);
    }
};

pub fn spawnBoard(cols: usize, rows: usize, allocator: *const Allocator) !Board {
    const array = try allocator.alloc(u8, rows * cols);
    fill(' ', array);
    return Board{
        .cols = cols,
        .rows = rows,
        .array = array,
    };
}

fn fill(char: u8, array: []u8) void {
    for (array) |*c| c.* = char;
}
