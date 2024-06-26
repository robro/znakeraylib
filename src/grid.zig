const Grid = @This();
const std = @import("std");

const IndexError = error{OutOfBounds};

empty_char: u8,
width: usize,
height: usize,
array: [][]u8,

pub fn create(empty_char: u8, width: usize, height: usize, allocator: *const std.mem.Allocator) !Grid {
    const array = try allocator.alloc([]u8, height);
    for (array) |*row| {
        row.* = try allocator.alloc(u8, width);
    }
    return Grid{
        .empty_char = empty_char,
        .width = width,
        .height = height,
        .array = array,
    };
}

pub fn free(self: *Grid, allocator: *const std.mem.Allocator) void {
    for (self.array) |*row| {
        allocator.free(row.*);
    }
    allocator.free(self.array);
}

pub fn empty(self: *Grid) void {
    for (self.array) |*row| {
        for (row.*) |*item| {
            item.* = self.empty_char;
        }
    }
}

pub fn printToBuf(self: *Grid, buffer: *const []u8) !void {
    if (buffer.len < self.array[0].len * self.height) return IndexError.OutOfBounds;
    for (self.array, 0..) |row, i| {
        std.mem.copyForwards(u8, buffer.*[row.len * i + i ..], row);
        std.mem.copyForwards(u8, buffer.*[row.len * i + i + row.len ..], "\n");
    }
}
