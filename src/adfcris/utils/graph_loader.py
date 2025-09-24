"""
Module for loading graph data into a graph-tool Graph object.

This module provides utilities to read graph data from files,
such as edge lists, and construct a graph-tool Graph instance
that can be used by the core ADFCRIS algorithms.
"""

from pathlib import Path
from typing import Union, Optional, Tuple, Dict

import pandas as pd
import graph_tool.all as gt
import numpy as np


def load_graph_from_edge_list(
    file_path: Union[str, Path],
    directed: bool = True,
    sep: str = r"\s+",
    comment: Optional[str] = "#",
    prop_type: str = "uniform",
    prop_value: float = 0.1,
) -> Tuple[gt.Graph, Dict[int, int]]:
    """
    Loads a graph from an edge list, removes duplicates, remaps node IDs,
    and automatically handles .gz compression.

    Args:
        file_path: Path to the edge list file.
        directed: Whether the graph is directed.
        sep: Delimiter for parsing.
        comment: Character for comments to ignore.
        prop_type: Method for assigning probabilities.
        prop_value: Value for uniform propagation probability.

    Returns:
        A tuple containing:
        - A graph-tool Graph object with compact node IDs and an edge property 'p'.
        - A dictionary mapping the new compact IDs back to the original node IDs.
    """
    print(f"Attempting to load graph from: {file_path}")
    path_obj = Path(file_path)

    if not path_obj.exists():
        raise FileNotFoundError(f"No such file or directory: '{file_path}'")

    compression = "gzip" if str(path_obj).endswith(".gz") else "infer"
    if compression == "gzip":
        print("Detected .gz file, using gzip decompression.")

    try:
        edge_df = pd.read_csv(
            path_obj,
            sep=sep,
            header=None,
            names=["source", "target"],
            comment=comment,
            engine="c",
            dtype=np.int64,
            compression=compression,
        )
    except Exception as e:
        print(f"An error occurred while reading the file with pandas: {e}")
        raise

    # --- Data Cleaning: Remove duplicate edges and self-loops ---
    print(f"Read {len(edge_df)} raw edges. Cleaning data...")
    edge_df.drop_duplicates(inplace=True)
    # Also remove self-loops (edges where source == target)
    edge_df = edge_df[edge_df["source"] != edge_df["target"]]
    print(f"Found {len(edge_df)} unique edges after cleaning.")

    # --- Node ID Remapping ---
    print("Remapping node IDs to a compact integer range...")
    unique_nodes = pd.unique(edge_df[["source", "target"]].values.ravel("K"))

    original_to_compact = {original_id: i for i, original_id in enumerate(unique_nodes)}
    compact_to_original = {i: original_id for i, original_id in enumerate(unique_nodes)}

    # === OPTIMIZED MAPPING APPLICATION ===
    compact_source = edge_df["source"].map(original_to_compact).values
    compact_target = edge_df["target"].map(original_to_compact).values
    compact_edges = np.column_stack((compact_source, compact_target))

    print(f"Remapping complete. Original unique nodes: {len(unique_nodes)}")

    # --- Graph Construction ---
    g = gt.Graph(directed=directed)
    g.add_edge_list(compact_edges, hashed=False)

    print(
        f"Graph loaded successfully: {g.num_vertices()} vertices, {g.num_edges()} edges."
    )

    p = g.new_edge_property("double")
    if prop_type == "uniform":
        p.a.fill(prop_value)
    else:
        raise NotImplementedError(f"Unsupported propagation type: {prop_type}")

    g.edge_properties["p"] = p
    print(f"Assigned uniform propagation probability of {prop_value} to all edges.")

    return g, compact_to_original
