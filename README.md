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
Times crossed zero: XXXX
```

### Input

Commands are read from `src/commands.txt`. Each line contains a command in the format:
- `R<number>` - Move right (clockwise) by the specified number of steps
- `L<number>` - Move left (counter-clockwise) by the specified number of steps

The dial has values 0-99 and wraps around (like a clock with 100 positions).

### Output

The program outputs how many times the dial points exactly to zero after executing all commands.

## Day 2

Find invalid IDs within given ranges based on repeating digit patterns.

### How to run

```bash
> cd day2
> zig build && ./zig-out/bin/day2
Part 1: XXXX
Part 2: XXXX
```

### Input

A comma-separated list of ID ranges in the format `start-end` (e.g., `11-22,95-115,998-1012`).

### Rules

**Part 1**: An ID is invalid if the first half of its digits equals the second half.
- Examples: `11`, `1010`, `446446`, `1188511885`

**Part 2**: An ID is invalid if it consists of any repeating sequence of digits (at least 2 repetitions).
- Examples: `111` (1 repeated 3 times), `1010` (10 repeated 2 times), `565656` (56 repeated 3 times), `123123123` (123 repeated 3 times)

### Output

The program outputs the sum of all invalid IDs for each part.

## Day 3

Select batteries with maximum voltage from each row of a battery grid.

### How to run

```bash
> cd day3
> zig build && ./zig-out/bin/day3
Part 1: XXXX
Part 2: XXXX
```

### Input

Battery data is read from `src/batteries.txt`. Each line contains a sequence of digits where each digit represents the voltage of a battery.

### Rules

**Part 1**: Select 2 batteries from each row to maximize voltage.
- Choose the first battery with the maximum digit value
- Choose the second battery with the maximum digit value from positions **after** the first battery
- Concatenate the two digits as a string to form the voltage (e.g., digits 9 and 8 → voltage 98)

**Part 2**: Select 12 batteries from each row using the same greedy approach.
- At each step, pick the maximum digit that still allows enough batteries to be selected from remaining positions
- Concatenate all 12 digits to form the voltage

### Output

The program outputs the sum of all voltages for each part.
