const std = @import("std");

pub const json_test = struct {
    name: []u8,
    initial: state,
    final: state,
    cycles: [][]u16,
};

pub const state = struct {
    pc: u16,
    s: u8,
    a: u8,
    x: u8,
    y: u8,
    p: u8,
    ram: [][]u16,
};
