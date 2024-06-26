const std = @import("std");
const Grid = @This();

const IndexError = error{OutOfBounds};

width: usize,
height: usize,
array: [][]u8,

pub fn create(width: usize, height: usize, allocator: std.mem.Allocator) !Grid {
    const array = try allocator.alloc([]u8, height);
    for (array) |*row| {
        row.* = try allocator.alloc(u8, width);
    }
    return Grid{ .width = width, .height = height, .array = array };
}

pub fn free(self: *Grid, allocator: std.mem.Allocator) void {
    for (self.array) |*row| {
        allocator.free(row.*);
    }
    allocator.free(self.array);
}

pub fn fill(self: *Grid, char: u8) void {
    for (self.array) |*row| {
        for (row.*) |*item| {
            item.* = char;
        }
    }
}

pub fn toString(self: *Grid, buffer: *const []u8) !void {
    if (buffer.len < self.array[0].len * self.height) return IndexError.OutOfBounds;
    for (self.array, 0..) |row, i| {
        std.mem.copyForwards(u8, buffer.*[row.len * i + i ..], row);
        std.mem.copyForwards(u8, buffer.*[row.len * i + i + row.len ..], "\n");
    }
}
