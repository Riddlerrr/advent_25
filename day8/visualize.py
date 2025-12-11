import argparse
import os

import matplotlib.animation as animation
import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d import Axes3D


class DSU:
    def __init__(self, n):
        self.parent = list(range(n))
        self.num_components = n

    def find(self, i):
        if self.parent[i] != i:
            self.parent[i] = self.find(self.parent[i])
        return self.parent[i]

    def union(self, i, j):
        root_i = self.find(i)
        root_j = self.find(j)
        if root_i != root_j:
            self.parent[root_i] = root_j
            self.num_components -= 1
            return True
        return False


def read_boxes(filename):
    points = []
    with open(filename, "r") as f:
        for line in f:
            if line.strip():
                parts = line.strip().split(",")
                points.append(tuple(map(int, parts)))
    return points


def get_sorted_edges(points):
    n = len(points)
    edges = []
    # Calculate all pairwise distances
    for i in range(n):
        for j in range(i + 1, n):
            p1 = points[i]
            p2 = points[j]
            dist_sq = (p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2 + (p1[2] - p2[2]) ** 2
            edges.append((dist_sq, i, j))
    edges.sort(key=lambda x: x[0])
    return edges


def prepare_part1(points):
    edges = get_sorted_edges(points)
    # Part 1: Connect the 1000 closest pairs
    limit = min(1000, len(edges))
    subset = edges[:limit]

    steps = []
    # Larger batch size for Part 1 to make it faster
    batch_size = 25
    current_batch = []

    for _, u, v in subset:
        current_batch.append((u, v, "blue"))
        if len(current_batch) >= batch_size:
            steps.append(current_batch)
            current_batch = []

    if current_batch:
        steps.append(current_batch)

    return steps


def prepare_part2(points):
    edges = get_sorted_edges(points)
    n = len(points)
    dsu = DSU(n)
    steps = []

    # Part 2: Connect until all in one circuit (MST)
    batch_size = 20
    current_batch = []

    for _, u, v in edges:
        if dsu.union(u, v):
            current_batch.append((u, v, "red"))
            if len(current_batch) >= batch_size:
                steps.append(current_batch)
                current_batch = []

        if dsu.num_components == 1:
            break

    if current_batch:
        steps.append(current_batch)

    return steps


class Animator:
    def __init__(self, ax, points, batches, frames_per_batch=5):
        self.ax = ax
        self.points = points
        self.batches = batches
        self.frames_per_batch = frames_per_batch
        self.current_lines = []  # List of (Line3D, u, v) tuples
        self.batch_idx = -1
        self.total_frames = len(batches) * frames_per_batch

    def update(self, frame):
        # Rotate camera
        self.ax.view_init(elev=30, azim=frame * 0.5)

        # Calculate which batch we are in
        batch_idx = frame // self.frames_per_batch

        # Calculate progress within the batch (0.0 to 1.0)
        # frame % frames_per_batch goes from 0 to frames_per_batch-1
        progress = (frame % self.frames_per_batch + 1) / self.frames_per_batch

        # If we moved to a new batch, finalize the previous one and start the new one
        if batch_idx != self.batch_idx:
            # Finalize previous lines (ensure they are fully drawn)
            if self.current_lines:
                for line, u, v in self.current_lines:
                    p1 = self.points[u]
                    p2 = self.points[v]
                    line.set_data([p1[0], p2[0]], [p1[1], p2[1]])
                    line.set_3d_properties([p1[2], p2[2]])
                self.current_lines = []

            self.batch_idx = batch_idx

            # Initialize new lines for the current batch
            if batch_idx < len(self.batches):
                for u, v, color in self.batches[batch_idx]:
                    p1 = self.points[u]
                    # Start with a point at p1
                    line = self.ax.plot(
                        [p1[0], p1[0]],
                        [p1[1], p1[1]],
                        [p1[2], p1[2]],
                        color=color,
                        linewidth=1.5,
                        alpha=0.8,
                    )[0]
                    self.current_lines.append((line, u, v))

        # Animate the "flying" effect for current lines
        if self.current_lines:
            for line, u, v in self.current_lines:
                p1 = self.points[u]
                p2 = self.points[v]

                # Interpolate end point
                cur_x = p1[0] + (p2[0] - p1[0]) * progress
                cur_y = p1[1] + (p2[1] - p1[1]) * progress
                cur_z = p1[2] + (p2[2] - p1[2]) * progress

                line.set_data([p1[0], cur_x], [p1[1], cur_y])
                line.set_3d_properties([p1[2], cur_z])

        return []


def main():
    parser = argparse.ArgumentParser(description="Visualize Day 8 solutions")
    parser.add_argument(
        "part", choices=["part1", "part2"], help="Which part to visualize"
    )
    parser.add_argument("--save", action="store_true", help="Save animation as GIF")
    args = parser.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    boxes_path = os.path.join(script_dir, "boxes.txt")

    if not os.path.exists(boxes_path):
        print(f"Error: {boxes_path} not found.")
        return

    print("Reading data...")
    points = read_boxes(boxes_path)
    points_np = np.array(points)

    print(f"Calculating edges and preparing animation for {args.part}...")

    if args.part == "part1":
        steps = prepare_part1(points)
        title_base = "Part 1: 1000 Closest Connections"
        line_color = "blue"
    else:
        steps = prepare_part2(points)
        title_base = "Part 2: Connecting All Boxes (MST)"
        line_color = "red"

    print(f"Prepared {len(steps)} batches of connections.")

    fig = plt.figure(figsize=(12, 10))
    ax = fig.add_subplot(111, projection="3d")

    # Plot points - Larger size (s=40)
    ax.scatter(
        points_np[:, 0],
        points_np[:, 1],
        points_np[:, 2],
        c="black",
        s=40,
        alpha=0.5,
        edgecolors="white",
    )

    ax.set_axis_off()
    part_num = "1" if args.part == "part1" else "2"
    ax.set_title(
        f"Day 8 Part {part_num}",
        fontsize=48,
        color="#c0392b",
        fontfamily="monospace",
        fontweight="bold",
    )

    # Animation setup
    frames_per_batch = 2  # Fast animation
    animator = Animator(ax, points, steps, frames_per_batch=frames_per_batch)

    ani = animation.FuncAnimation(
        fig,
        animator.update,
        frames=animator.total_frames + 1,  # +1 to ensure final state is drawn
        interval=20,  # 20ms per frame for speed
        blit=False,
        repeat=False,
    )

    if args.save:
        output_file = f"{args.part}.gif"
        print(f"Saving animation to {output_file}...")
        ani.save(output_file, writer="pillow", fps=30)
        print("Done!")
    else:
        print("Starting animation window...")
        plt.show()


if __name__ == "__main__":
    main()
