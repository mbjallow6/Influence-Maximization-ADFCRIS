"""
Module for performance and memory profiling utilities.

Provides decorators to easily monitor the resource consumption of key functions
within the ADFCRIS pipeline.
"""

import time
import threading
import psutil
import os
from functools import wraps
import matplotlib.pyplot as plt
import numpy as np


def profile_memory(func):
    """
    A decorator that profiles the memory usage of a function in a separate
    thread and plots the results.
    """

    @wraps(func)
    def wrapper(*args, **kwargs):
        process = psutil.Process(os.getpid())
        # FIX: Initialize as empty lists
        mem_usage_mb = []
        timestamps = []

        # Flag to signal the monitoring thread to stop
        stop_monitoring = threading.Event()

        def monitor_memory():
            """Polls memory usage at a fixed interval."""
            start_time = time.time()
            while not stop_monitoring.is_set():
                mem_info = process.memory_info()
                mem_usage_mb.append(mem_info.rss / (1024 * 1024))  # Convert bytes to MB
                timestamps.append(time.time() - start_time)
                time.sleep(0.1)  # Poll every 100ms

        monitor_thread = threading.Thread(target=monitor_memory, daemon=True)
        monitor_thread.start()

        start_func_time = time.time()
        result = func(*args, **kwargs)
        end_func_time = time.time()

        stop_monitoring.set()
        monitor_thread.join()

        func_name = func.__name__
        duration = end_func_time - start_func_time
        peak_mem = np.max(mem_usage_mb) if mem_usage_mb else 0
        avg_mem = np.mean(mem_usage_mb) if mem_usage_mb else 0

        print("\n--- 📊 Memory & Performance Profile ---")
        print(f"Function:      {func_name}")
        print(f"Execution Time: {duration:.2f} seconds")
        print(f"Peak Memory:     {peak_mem:.2f} MB")
        print(f"Average Memory:  {avg_mem:.2f} MB")
        print("------------------------------------")

        plt.figure(figsize=(10, 5))
        plt.plot(timestamps, mem_usage_mb, label=f"Memory Usage of {func_name}")
        plt.title(f"Memory Consumption Over Time for {func_name}")
        plt.xlabel("Time (seconds)")
        plt.ylabel("Memory Usage (MB)")
        plt.grid(True)
        plt.legend()
        # Use plt.savefig() instead of plt.show() on a remote server
        # to avoid GUI errors.
        plot_filename = f"{func_name}_profile.png"
        plt.savefig(plot_filename)
        print(f"📈 Profile plot saved to {plot_filename}")
        plt.close()

        return result

    return wrapper
