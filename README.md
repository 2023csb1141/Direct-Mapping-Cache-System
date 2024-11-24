# CS203_Project-2024    

# Team Members

| Name           | Entry No.   |
|----------------|-------------|
| Harsh Rai      | 2023CSB1345 |
| Nitin Kumar    | 2023CSB1141 |
| Parth Kulkarni | 2023CSB1142 |
| Hardik Garg    | 2023CSB1121 |
| Aashish Singh  | 2023CSB1093 |
| Arpit Goel     | 2023CSB1099 |

## Project Overview

This project implements a Direct Mapping Cache system using Verilog to simulate cache memory behavior. The goal is to design a direct-mapped cache model that efficiently manages data storage and retrieval, with an emphasis on understanding cache memory concepts like cache hits, misses, and performance effects from cache and block sizes.

### Key Features

- **Cache Structure**: Implements direct-mapped cache organization with cache lines that include valid bits, tag bits, and data blocks.
- **Address Decoding**: Memory addresses are split into tag, index, and block offset bits to direct cache operations.
- **Cache Operations**: Supports read and write operations with tracking of cache hits and misses.
- **Statistics Tracking**: Monitors performance metrics including cache hits, misses, and hit/miss ratios.

### Design Specifications

- **Memory Address Format**: Defines bit widths for tag, index, and block offset based on a cache size of 256 bytes and a block size of 16 bytes.
- **Operations**:
  - **Read**: Checks for data in cache; on miss, loads data from main memory.
  - **Write**: Writes data to cache if present; loads from memory if not.
- **Statistics Reporting**: Displays request counts, hits, misses, and hit/miss ratios.

### Inputs, Outputs, and Constraints

- **Inputs**:
  - `Memory Address`: Configurable n-bit input address.
  - `Write Data`: Data to write to cache.
  - Control signals: `read_enable`, `write_enable`.
- **Outputs**:
  - `Read Data`: Data read from cache or memory on a miss.
  - `Hit/Miss Indicator`: Shows whether an operation was a hit or miss.
  - **Statistics**: Total requests, hits, misses, hit/miss ratios.
