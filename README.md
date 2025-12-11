# Advent of code 2025 solved using Zig

## Requirements

- Zig 0.15.x

## How to run

```bash
> cd day<N>
> zig build run
```

## Day 1

A circular dial puzzle where we track how many times the dial points to zero after executing movement commands.

### Input

Commands are read from `src/commands.txt`. Each line contains a command in the format:
- `R<number>` - Move right (clockwise) by the specified number of steps
- `L<number>` - Move left (counter-clockwise) by the specified number of steps

The dial has values 0-99 and wraps around (like a clock with 100 positions).

### Output

The program outputs how many times the dial points exactly to zero after executing all commands.

## Day 2

Find invalid IDs within given ranges based on repeating digit patterns.

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

## Day 4

Remove lonely rolls from a map iteratively.

### Input

A map is read from `src/map.txt`. The map contains `@` characters representing rolls and other characters representing empty space.

### Rules

**Part 1**: Count rolls that have 3 or fewer neighboring rolls (in all 8 directions).

**Part 2**: Iteratively remove all rolls with 3 or fewer neighbors until no more can be removed.
- In each iteration, find all "lonely" rolls (≤3 neighbors)
- Remove them all simultaneously
- Repeat until no lonely rolls remain
- Count total removed rolls across all iterations

### Output

- Part 1: Number of lonely rolls in the initial map
- Part 2: Total number of rolls removed across all iterations

## Day 5

Determine fresh ingredients based on ID ranges.

### Input

Data is read from `db.txt`. The file contains two sections separated by a blank line:
1. Fresh ID ranges in format `start-end` (inclusive)
2. Ingredient IDs to check

### Rules

**Part 1**: Count how many of the listed ingredient IDs fall within any fresh range.
- An ID is fresh if it falls into at least one range
- Ranges can overlap

**Part 2**: Count the total number of unique fresh IDs across all ranges.
- Merge overlapping/adjacent ranges to avoid double-counting
- Example: ranges `3-5` and `4-7` together cover IDs 3,4,5,6,7 = 5 unique IDs

### Output

- Part 1: Number of fresh ingredients from the ID list
- Part 2: Total count of unique fresh IDs across all ranges

## Day 8

Connect junction boxes with wires to form circuits based on proximity.

### Input

Coordinates of boxes are read from `boxes.txt`. Each line contains `X,Y,Z` coordinates.

### Rules

**Part 1**: Connect the 1000 closest pairs of boxes.
- Calculate Euclidean distance between all pairs.
- Sort connections by distance.
- Connect the top 1000 pairs.
- Calculate the product of the sizes of the three largest resulting circuits.

**Part 2**: Connect boxes until they form a single circuit (Minimum Spanning Tree).
- Continue connecting closest pairs until all boxes are in the same component.
- Multiply the X coordinates of the two boxes connected by the final wire that merges everything into one circuit.

### Visualization

A Python script `visualize.py` is provided to visualize the connection process in 3D.

Requirements: `python3`, `matplotlib`, `numpy`.

```bash
# Visualize Part 1 (1000 closest connections)
python3 visualize.py part1

# Visualize Part 2 (Building the MST)
python3 visualize.py part2

# Save as GIF
python3 visualize.py part1 --save
```
