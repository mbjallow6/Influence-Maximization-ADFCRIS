"""
Solves the maximum coverage problem for seed selection in the RIS framework
using an optimized greedy algorithm.
"""

# src/adfcris/core/coverage.py
from typing import List, Set
from collections import defaultdict
import numpy as np


def find_seed_set(rr_sets: List[Set[int]], k: int, num_vertices: int) -> List[int]:
    """
    Finds a k-sized seed set using an optimized greedy algorithm for maximum coverage.

    This implementation avoids the naive O(n) scan in each iteration. Instead, it
    pre-calculates marginal gains and efficiently updates them, making it
    suitable for large-scale graphs.

    Args:
        rr_sets: A list of RR sets, where each set contains node indices.
        k: The desired size of the seed set (budget).
        num_vertices: The total number of vertices in the graph.

    Returns:
        A list of k node indices representing the selected seed set.
    """
    print(f"Starting OPTIMIZED greedy maximum coverage for k={k} seeds...")

    if not rr_sets or k == 0:
        return []

    # 1. Create an inverted index: map each node to the list of RR set indices it covers.
    # This is crucial for an efficient greedy implementation.
    node_to_rr_indices = defaultdict(list)
    for i, rr_set in enumerate(rr_sets):
        for node_idx in rr_set:
            if node_idx < num_vertices:  # Safety check
                node_to_rr_indices[node_idx].append(i)

    # 2. Pre-calculate initial marginal gains for all nodes.
    # The gain is simply the number of RR sets a node appears in.
    marginal_gains = np.zeros(num_vertices, dtype=np.int32)
    for i in range(num_vertices):
        marginal_gains[i] = len(node_to_rr_indices[i])

    seed_set = []
    covered_rr_mask = np.zeros(len(rr_sets), dtype=bool)

    # 3. Iteratively select k seeds
    for _ in range(k):
        # Find the node with the maximum current marginal gain.
        # np.argmax is highly optimized for this.
        best_node = np.argmax(marginal_gains)

        # If the best possible gain is 0, no more sets can be covered. Stop early.
        if marginal_gains[best_node] == 0:
            break

        # Add the best node to our seed set
        seed_set.append(best_node)

        # Mark its gain as -1 to prevent it from being selected again.
        marginal_gains[best_node] = -1

        # 4. Efficiently update marginal gains.
        # This is the key optimization. We only update nodes that are affected.
        for rr_index in node_to_rr_indices[best_node]:
            # If this RR set is already covered, skip it.
            if not covered_rr_mask[rr_index]:
                # Mark this RR set as covered.
                covered_rr_mask[rr_index] = True

                # Decrement the marginal gain of all other nodes in this newly covered RR set.
                rr_set = rr_sets[rr_index]
                for node_in_set in rr_set:
                    # Check if the node hasn't already been selected
                    if marginal_gains[node_in_set] != -1:
                        marginal_gains[node_in_set] -= 1

    print(f"Selected seed set: {seed_set}")
    return seed_set
