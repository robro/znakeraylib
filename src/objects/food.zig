const std = @import("std");
const objects = @import("objects.zig");
const math = @import("../math.zig");

const Grid = objects.grid.Grid;
const Vec2 = math.Vec2;
const rng = std.crypto.random;

pub const Food = struct {
    char: u8,
    pos: Vec2,

    pub fn create(char: u8, grid: *Grid) !Food {
        return Food{ .char = char, .pos = try getRandPos(grid) };
    }

    pub fn update(self: *Food) void {
        _ = self;
    }

    pub fn draw(self: *Food, grid: *Grid) void {
        grid.array[@as(usize, @intCast(self.pos.y))][@as(usize, @intCast(self.pos.x))] = self.char;
    }

    pub fn reset(self: *Food, char: u8, grid: *Grid) !void {
        self.char = char;
        self.pos = try getRandPos(grid);
    }

    fn getRandPos(grid: *Grid) !Vec2 {
        const empty_count = grid.getEmptyCount();
        if (empty_count == 0) return error.NoFreePositions;
        return grid.empty_ps[rng.uintLessThan(usize, empty_count)];
    }
};
