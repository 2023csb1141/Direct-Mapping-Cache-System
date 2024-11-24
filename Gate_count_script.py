def estimate_cache_metrics(data_width, tag_width, cache_size, mem_access_delay, single_gate_delay):
    # Constants for gate counts
    DFF_GATES = 6
    COMPARATOR_GATES_PER_BIT = 4
    MUX_GATES_PER_BIT = 6

    # Storage Elements
    data_array_gates = data_width * cache_size * DFF_GATES
    tag_array_gates = tag_width * cache_size * DFF_GATES
    valid_array_gates = cache_size * DFF_GATES

    # Comparators
    comparator_gates = tag_width * COMPARATOR_GATES_PER_BIT

    # Multiplexers
    mux_gates = data_width * MUX_GATES_PER_BIT

    # Total gate count
    total_gates = data_array_gates + tag_array_gates + valid_array_gates + comparator_gates + mux_gates

    # Delay Estimates
    comparator_delay = tag_width * single_gate_delay
    mux_delay = single_gate_delay
    read_hit_delay = comparator_delay + mux_delay
    read_miss_delay = mem_access_delay
    write_delay = 2 * DFF_GATES * single_gate_delay

    # Results
    return {
        "total_gates": total_gates,
        "read_hit_delay": read_hit_delay,
        "read_miss_delay": read_miss_delay,
        "write_delay": write_delay,
    }


# Example Parameters
params = estimate_cache_metrics(data_width=16, tag_width=16, cache_size=16, mem_access_delay=50, single_gate_delay=1)
print("Cache Metrics:")
for key, value in params.items():
    print(f"{key}: {value}")
