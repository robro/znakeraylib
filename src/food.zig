const Food = @This();
const Grid = @import("grid.zig");
const rng = @import("std").crypto.random;
const Position = @import("utils.zig").Position;
const SizeError = @import("utils.zig").SizeError;

char: u8,
pos: Position,

pub fn create(char: u8, grid: *Grid) !Food {
    return Food{ .char = char, .pos = try Food.getRandPos(grid) };
}

pub fn update(self: *Food) void {
    _ = self;
}

pub fn draw(self: *Food, grid: *Grid) void {
    grid.array[@as(usize, @intCast(self.pos.y))][@as(usize, @intCast(self.pos.x))] = self.char;
}

pub fn reset(self: *Food, char: u8, grid: *Grid) !void {
    self.char = char;
    self.pos = try Food.getRandPos(grid);
}

fn getRandPos(grid: *Grid) !Position {
    const empty_count = grid.getEmptyCount();
    if (empty_count == 0) return SizeError.NoFreePositions;
    return grid.empty_ps[rng.uintLessThan(usize, empty_count)];
}
