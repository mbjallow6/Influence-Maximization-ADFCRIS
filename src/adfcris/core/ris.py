"""
Core implementation of the Reverse Influence Sampling (RIS) algorithm.

This module contains functions for generating Reverse Reachable (RR) sets,
which are the fundamental building blocks of the RIS framework for influence
maximization. This implementation leverages graph-tool's C++ backend for
maximum performance.

"""

from typing import List, Set

import graph_tool.all as gt
import numpy as np


def generate_rr_set(g: gt.Graph, p_map: gt.EdgePropertyMap) -> Set[int]:
    """
    Generates a single Random Reverse Reachable (RR) set using an optimized
    C++ based traversal.

    Args:
        g: The input graph-tool Graph object.
        p_map: An edge property map containing propagation probabilities.

    Returns:
        A set of node indices representing a single RR set.
    """
    num_vertices = g.num_vertices()
    if num_vertices == 0:
        return set()

    root_node = np.random.randint(0, num_vertices)

    edge_active = g.new_edge_property("bool")
    random_values = np.random.rand(g.num_edges())
    np.greater(p_map.a, random_values, out=edge_active.a)

    g_random_instance = gt.GraphView(g, efilt=edge_active)

    # Create a reversed view of our random graph instance
    g_reversed = gt.GraphView(g_random_instance, reversed=True)

    # Run a standard forward search on the reversed graph
    dist = gt.shortest_distance(g_reversed, source=root_node)

    reachable_nodes = np.flatnonzero(dist.a < np.iinfo(np.int32).max)
    return set(reachable_nodes)


def generate_rr_sets_collection(g: gt.Graph, num_samples: int) -> List[Set[int]]:
    """
    Generates a collection of Random Reverse Reachable (RR) sets.

    Args:
        g: The input graph-tool Graph object.
        num_samples: The total number of RR sets to generate.

    Returns:
        A list where each element is a set of node indices (an RR set).
    """
    print(f"Generating {num_samples} RR sets using optimized C++ traversal...")
    if num_samples <= 0:
        return []

    try:
        p_map = g.edge_properties["p"]
        # FIX: Accept both 'float' and 'double' as valid property types.
        if "float" not in p_map.value_type() and "double" not in p_map.value_type():
            raise TypeError(
                f"Edge property 'p' must be a float or double type, but got {p_map.value_type()}"
            )
    except KeyError:
        raise ValueError(
            "Graph must have an edge property map named 'p' for probabilities."
        )

    rr_sets = [generate_rr_set(g, p_map) for _ in range(num_samples)]

    print(f"Finished generating {len(rr_sets)} RR sets.")
    return rr_sets
