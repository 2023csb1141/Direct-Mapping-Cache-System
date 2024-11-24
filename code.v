module main(
    input clk,
    input reset,
    input read,
    input write,
    input [TAG_WIDTH-1:0] tag,
    input [OFFSET_WIDTH-1:0] offset,  // Added offset input
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg cache_hit,
    output reg cache_miss,
    output reg [31:0] hit_counter,
    output reg [31:0] miss_counter,
    output reg [31:0] total_requests
);

    parameter DATA_WIDTH = 16;
    parameter TAG_WIDTH = 16;
    parameter CACHE_SIZE = 16;
    parameter BLOCK_SIZE = 4;       // Number of words per block
    parameter OFFSET_WIDTH = 2;     // log2(BLOCK_SIZE)

    localparam INDEX_WIDTH = $clog2(CACHE_SIZE);

    wire [INDEX_WIDTH-1:0] index = tag[INDEX_WIDTH-1:0];

    // Cache storage
    reg [DATA_WIDTH-1:0] data_array [CACHE_SIZE-1:0][BLOCK_SIZE-1:0]; // Cache stores blocks
    reg [TAG_WIDTH-1:0] tag_array [CACHE_SIZE-1:0];
    reg valid_array [CACHE_SIZE-1:0];

    // Main memory simulation
    reg [DATA_WIDTH-1:0] main_memory [0:(1 << TAG_WIDTH)-1][BLOCK_SIZE-1:0]; // Main memory stores blocks

    integer i, j;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize cache and counters
            for (i = 0; i < CACHE_SIZE; i = i + 1) begin
                valid_array[i] <= 0;
                tag_array[i] <= 0;
                for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                    data_array[i][j] <= 0;
                end
            end
            hit_counter <= 0;
            miss_counter <= 0;
            total_requests <= 0;
        end else if (read) begin
            if (valid_array[index] && tag_array[index] == tag) begin
                // Cache hit
                cache_hit <= 1;
                cache_miss <= 0;
                hit_counter <= hit_counter + 1;
                total_requests <= total_requests + 1;
                data_out <= data_array[index][offset]; // Fetch data using offset
            end else begin
                // Cache miss
                cache_hit <= 0;
                cache_miss <= 1;
                miss_counter <= miss_counter + 1;
                total_requests <= total_requests + 1;

                // Fetch block from main memory
                for (j = 0; j < BLOCK_SIZE; j = j + 1) begin
                    data_array[index][j] <= main_memory[tag][j];
                end
                tag_array[index] <= tag;
                valid_array[index] <= 1;

                // Output fetched data
                data_out <= main_memory[tag][offset]; // Use offset to select word from fetched block
            end
        end else if (write) begin
            // Write to specific word in block
            data_array[index][offset] <= data_in;
            tag_array[index] <= tag;
            valid_array[index] <= 1;
            total_requests <= total_requests + 1;
        end
    end
endmodule
`timescale 1ns / 1ps

module main_tb;
    // Parameters
    parameter DATA_WIDTH = 16;
    parameter TAG_WIDTH = 16;
    parameter CACHE_SIZE = 16;
    parameter BLOCK_SIZE = 4;
    parameter OFFSET_WIDTH = 2;

    // Clock and reset
    reg clk;
    reg reset;

    // Inputs
    reg read;
    reg write;
    reg [TAG_WIDTH-1:0] tag;
    reg [OFFSET_WIDTH-1:0] offset; // Offset for block
    reg [DATA_WIDTH-1:0] data_in;

    // Outputs
    wire [DATA_WIDTH-1:0] data_out;
    wire cache_hit;
    wire cache_miss;
    wire [31:0] hit_counter;
    wire [31:0] miss_counter;
    wire [31:0] total_requests;

    // Instantiate the DUT (Device Under Test)
    main #(
        .TAG_WIDTH(TAG_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(CACHE_SIZE),
        .BLOCK_SIZE(BLOCK_SIZE),
        .OFFSET_WIDTH(OFFSET_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .read(read),
        .write(write),
        .tag(tag),
        .offset(offset), // Pass offset
        .data_in(data_in),
        .data_out(data_out),
        .cache_hit(cache_hit),
        .cache_miss(cache_miss),
        .hit_counter(hit_counter),
        .miss_counter(miss_counter),
        .total_requests(total_requests)
    );

    // Clock generation
    always #5 clk = ~clk;  // 10ns clock period

    // Testbench logic
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        read = 0;
        write = 0;
        tag = 16'h0000;
        offset = 2'b00;
        data_in = 16'h0000;

        // Apply reset
        #10 reset = 0;

        // Initialize main memory (preload blocks)
        for (integer i = 0; i < (1 << TAG_WIDTH); i = i + 1) begin
            for (integer j = 0; j < BLOCK_SIZE; j = j + 1) begin
                dut.main_memory[i][j] = i * BLOCK_SIZE + j; // Dummy data
            end
        end

        // Perform a read with offset
        #10 tag = 16'h0010; offset = 2'b01; read = 1; #10 read = 0;
        $display("Time: %0t | Tag: 0x%h | Data Out: 0x%h | Cache Hit: %d | Cache Miss: %d | Hit Counter: %d | Miss Counter: %d | Total Requests: %d", 
         $time, tag, data_out, cache_hit, cache_miss, hit_counter, miss_counter, total_requests);

        // Perform another read to check cache hit
        #10 tag = 16'h0010; offset = 2'b10; read = 1; #10 read = 0;
        $display("Time: %0t | Tag: 0x%h | Data Out: 0x%h | Cache Hit: %d | Cache Miss: %d | Hit Counter: %d | Miss Counter: %d | Total Requests: %d", 
         $time, tag, data_out, cache_hit, cache_miss, hit_counter, miss_counter, total_requests);
        // Perform a read with a different tag
        #10 tag = 16'h0011; offset = 2'b00; read = 1; #10 read = 0;
        $display("Time: %0t | Tag: 0x%h | Data Out: 0x%h | Cache Hit: %d | Cache Miss: %d | Hit Counter: %d | Miss Counter: %d | Total Requests: %d", 
         $time, tag, data_out, cache_hit, cache_miss, hit_counter, miss_counter, total_requests);
        // Perform a write operation
        #10 tag = 16'h0030; offset = 2'b11; data_in = 16'hCCCC; write = 1; #10 write = 0;
        $display("Time: %0t | Tag: 0x%h | Data Out: 0x%h | Cache Hit: %d | Cache Miss: %d | Hit Counter: %d | Miss Counter: %d | Total Requests: %d", 
         $time, tag, data_out, cache_hit, cache_miss, hit_counter, miss_counter, total_requests);
        // Read back the written data
        #10 tag = 16'h0030; offset = 2'b11; read = 1; #10 read = 0;
        $display("Time: %0t | Tag: 0x%h | Data Out: 0x%h | Cache Hit: %d | Cache Miss: %d | Hit Counter: %d | Miss Counter: %d | Total Requests: %d", 
         $time, tag, data_out, cache_hit, cache_miss, hit_counter, miss_counter, total_requests);
        // Display final hit/miss counters
       

        // Finish simulation
        #10 $finish;
    end
endmodule
