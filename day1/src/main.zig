const std = @import("std");
const day1 = @import("day1");
const utils = @import("utils");

const CommandDirection = enum {
    Right,
    Left,
};

const Command = struct {
    direction: CommandDirection,
    steps: u16,

    pub fn init(direction: CommandDirection, steps: u16) Command {
        return Command{
            .direction = direction,
            .steps = steps,
        };
    }

    pub fn initFromCommandStr(command_str: []const u8) Command {
        const direction_char = command_str[0];
        const steps_str = command_str[1..];
        const steps = std.fmt.parseInt(u16, steps_str, 10) catch unreachable;

        const direction = switch (direction_char) {
            'R' => CommandDirection.Right,
            'L' => CommandDirection.Left,
            else => unreachable,
        };

        return Command.init(direction, steps);
    }
};

const CommandList = struct {
    allocator: std.mem.Allocator,
    commands: std.ArrayList(Command),
    current_index: usize,

    pub fn init(allocator: std.mem.Allocator) CommandList {
        return CommandList{
            .allocator = allocator,
            .commands = .empty,
            .current_index = 0,
        };
    }

    pub fn append(self: *CommandList, command: Command) !void {
        try self.commands.append(self.allocator, command);
    }

    pub fn items(self: *CommandList) []const Command {
        return self.commands.items;
    }

    pub fn nextCommand(self: *CommandList) ?Command {
        if (self.current_index >= self.commands.items.len) {
            return null;
        }
        const command = self.commands.items[self.current_index];
        self.current_index += 1;
        return command;
    }

    pub fn deinit(self: *CommandList) void {
        self.commands.deinit(self.allocator);
    }
};

const CommandExecutor = struct {
    deal: *Deal,
    zero_count: usize,
    zero_cross_count: usize,

    pub fn init(deal: *Deal) CommandExecutor {
        return CommandExecutor{
            .deal = deal,
            .zero_count = 0,
            .zero_cross_count = 0,
        };
    }

    pub fn executeAll(self: *CommandExecutor, command_list: *CommandList) void {
        while (command_list.nextCommand()) |command| {
            self.executeCommand(command);
        }
    }

    fn executeCommand(self: *CommandExecutor, command: Command) void {
        const steps: i32 = command.steps;
        const old_value: i32 = self.deal.current_value;

        switch (command.direction) {
            .Right => {
                // Moving right increases the value
                const new_value = @mod(old_value + steps, 100);
                self.deal.current_value = @intCast(new_value);

                // Count how many times dial points at zero during movement
                // From old_value, moving right by steps:
                // - First zero hit at (100 - old_value) steps if old_value > 0, or 0 steps if old_value == 0
                // - Then every 100 steps after that
                // Formula: how many multiples of 100 are in range (old_value, old_value + steps]
                // Which is: floor((old_value + steps) / 100) - floor(old_value / 100)
                // But since old_value is 0-99, floor(old_value / 100) = 0
                // So it's: floor((old_value + steps) / 100)
                const times_at_zero: i32 = @divFloor(old_value + steps, 100);
                self.zero_cross_count += @intCast(times_at_zero);
            },
            .Left => {
                // Moving left decreases the value (wraps from 0 to 99)
                const new_value = @mod(old_value - steps, 100);
                self.deal.current_value = @intCast(new_value);

                // Count how many times dial points at zero during movement
                // From old_value, moving left by steps:
                // - First zero hit at old_value steps (if steps >= old_value and old_value > 0)
                //   or at 0 steps if old_value == 0
                // - Then every 100 steps after that
                // We need to count how many times we land on 0
                // Going from old_value left by steps means values: old_value-1, old_value-2, ..., old_value-steps (mod 100)
                // Zero is hit when (old_value - k) mod 100 == 0, i.e., k = old_value, old_value+100, old_value+200, ...
                // For k in [1, steps]: count = floor((steps - old_value) / 100) + 1 if old_value <= steps, else 0
                // But we need to handle old_value == 0 specially: first hit is at step 100, not step 0
                if (old_value == 0) {
                    // Starting at 0, going left: we hit 0 again at step 100, 200, etc.
                    const times_at_zero: i32 = @divFloor(steps, 100);
                    self.zero_cross_count += @intCast(times_at_zero);
                } else if (steps >= old_value) {
                    // We hit 0 at step = old_value, then again at old_value + 100, etc.
                    const times_at_zero: i32 = @divFloor(steps - old_value, 100) + 1;
                    self.zero_cross_count += @intCast(times_at_zero);
                }
                // If steps < old_value, we never reach 0
            },
        }

        // Count only when deal points exactly to zero after the command
        if (self.deal.current_value == 0) {
            self.zero_count += 1;
        }
    }

    pub fn getZeroCount(self: *const CommandExecutor) usize {
        return self.zero_count;
    }

    pub fn getZeroCrossCount(self: *const CommandExecutor) usize {
        return self.zero_cross_count;
    }
};

const Deal = struct {
    const INIITIAL_VALUE: u8 = 50;

    current_value: u8,

    pub fn init() Deal {
        return Deal{ .current_value = INIITIAL_VALUE };
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file_content = try utils.file.readFileAlloc(allocator, "src/commands.txt");
    defer allocator.free(file_content);

    var commands = CommandList.init(allocator);
    defer commands.deinit();

    var lines = utils.file.lines(file_content);
    while (lines.next()) |line| {
        const command = Command.initFromCommandStr(line);
        try commands.append(command);
    }

    var deal = Deal.init();
    var executor = CommandExecutor.init(&deal);
    executor.executeAll(&commands);

    // try utils.io.println("List of commands: {any}", .{commands.items()});
    // try utils.io.println("Final deal value: {d}", .{deal.current_value});
    try utils.io.println("Times at zero: {d}", .{executor.getZeroCount()});
    try utils.io.println("Times crossed zero: {d}", .{executor.getZeroCrossCount()});
}
