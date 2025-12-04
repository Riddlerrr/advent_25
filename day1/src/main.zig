const std = @import("std");
const day1 = @import("day1");

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

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

    pub fn init(deal: *Deal) CommandExecutor {
        return CommandExecutor{
            .deal = deal,
            .zero_count = 0,
        };
    }

    pub fn executeAll(self: *CommandExecutor, command_list: *CommandList) void {
        while (command_list.nextCommand()) |command| {
            self.executeCommand(command);
        }
    }

    fn executeCommand(self: *CommandExecutor, command: Command) void {
        const steps: i32 = command.steps;
        switch (command.direction) {
            .Right => {
                // Moving right increases the value
                const current: i32 = self.deal.current_value;
                const new_value = @mod(current + steps, 100);
                self.deal.current_value = @intCast(new_value);
            },
            .Left => {
                // Moving left decreases the value (wraps from 0 to 99)
                const current: i32 = self.deal.current_value;
                const new_value = @mod(current - steps, 100);
                self.deal.current_value = @intCast(new_value);
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

    // Read commands from file
    const file = try std.fs.cwd().openFile("src/commands.txt", .{});
    defer file.close();

    const file_content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(file_content);

    var commands = CommandList.init(allocator);
    defer commands.deinit();

    var lines = std.mem.splitAny(u8, file_content, "\n\r");
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len == 0) continue;

        const command = Command.initFromCommandStr(trimmed);
        try commands.append(command);
    }

    var deal = Deal.init();
    var executor = CommandExecutor.init(&deal);
    executor.executeAll(&commands);

    // try stdout.print("List of commands: {any}\n", .{commands.items()});
    // try stdout.print("Final deal value: {d}\n", .{deal.current_value});
    try stdout.print("Times at zero: {d}\n", .{executor.getZeroCount()});
    try stdout.flush();
}
