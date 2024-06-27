pub fn getChar(num: usize) u8 {
    switch (num % 3) {
        0 => return 'z',
        1 => return 'i',
        2 => return 'g',
        else => unreachable,
    }
}
