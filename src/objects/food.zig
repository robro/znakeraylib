const std = @import("std");
const objects = @import("objects.zig");
const math = @import("../math.zig");

const Grid = objects.grid.Grid;
const Position = math.Position;
const rng = std.crypto.random;

pub const Food = struct {
    char: u8,
    pos: Position,

    pub fn draw(self: *Food, grid: *Grid) void {
        grid.array[@as(usize, @intCast(self.pos.y))][@as(usize, @intCast(self.pos.x))] = self.char;
    }
};

pub fn spawnFood(char: u8, grid: *Grid) !Food {
    var empty_count: usize = 0;
    for (grid.array, 0..) |*row, y| {
        for (row.*, 0..) |c, x| {
            if (c != ' ') continue;
            grid.empty_ps[empty_count] = .{ .x = @intCast(x), .y = @intCast(y) };
            empty_count += 1;
        }
    }
    if (empty_count == 0) return error.NoFreePositions;
    return Food{
        .char = char,
        .pos = grid.empty_ps[rng.uintLessThan(usize, empty_count)],
    };
}
