# Advent of code 2025 solved using Zig

## Requirements

- Zig 0.15.x

## Day 1

A circular dial puzzle where we track how many times the dial points to zero after executing movement commands.

### How to run

```bash
> cd day1
> zig build && ./zig-out/bin/day1
Times at zero: XXXX
```

### Input

Commands are read from `src/commands.txt`. Each line contains a command in the format:
- `R<number>` - Move right (clockwise) by the specified number of steps
- `L<number>` - Move left (counter-clockwise) by the specified number of steps

The dial has values 0-99 and wraps around (like a clock with 100 positions).

### Output

The program outputs how many times the dial points exactly to zero after executing all commands.
