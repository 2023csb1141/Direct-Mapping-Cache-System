module main(
    input clk,
    input reset,
    input read,
    input write,
    input [ADDR_WIDTH-1:0] address,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg cache_hit,
    output reg cache_miss,
    output reg [31:0] hit_counter,
    output reg [31:0] miss_counter
);
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 16;
    parameter TAG_WIDTH = 8;
    parameter CACHE_SIZE = 16;
    
    localparam INDEX_WIDTH = $clog2(CACHE_SIZE);

    wire [TAG_WIDTH-1:0] tag = address[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH];
    wire [INDEX_WIDTH-1:0] index = address[INDEX_WIDTH-1:0];

    reg [DATA_WIDTH-1:0] data_array [CACHE_SIZE-1:0];
    reg [TAG_WIDTH-1:0] tag_array [CACHE_SIZE-1:0];
    reg valid_array [CACHE_SIZE-1:0];

    reg [DATA_WIDTH-1:0] main_memory [0:1023];  // Simulate main memory

    // Declare loop variable outside the procedural block
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize cache and counters
            for (i = 0; i < CACHE_SIZE; i = i + 1) begin
                valid_array[i] <= 0;
                tag_array[i] <= 0;
                data_array[i] <= 0;
            end
            hit_counter <= 0;
            miss_counter <= 0;
        end else if (read) begin
            if (valid_array[index] && tag_array[index] == tag) begin
                // Cache hit
                cache_hit <= 1;
                cache_miss <= 0;
                hit_counter <= hit_counter + 1;
                data_out <= data_array[index];
            end else begin
                // Cache miss
                cache_hit <= 0;
                cache_miss <= 1;
                miss_counter <= miss_counter + 1;
                
                // Fetch data from main memory
                data_array[index] <= main_memory[{tag, index}];  // Simulate fetching by combining tag and index
                tag_array[index] <= tag;
                valid_array[index] <= 1;
                
                // Output fetched data
                data_out <= main_memory[{tag, index}];
            end
        end else if (write) begin
            // Handle write operation (if necessary, write-through logic can be added)
            data_array[index] <= data_in;
            tag_array[index] <= tag;
            valid_array[index] <= 1;
        end
    end
endmodule
`timescale 1ns / 1ps

module main_tb;
    // Parameters
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 16;
    parameter TAG_WIDTH = 8;
    parameter CACHE_SIZE = 16;

    // Clock and reset
    reg clk;
    reg reset;

    // Inputs
    reg read;
    reg write;
    reg [ADDR_WIDTH-1:0] address;
    reg [DATA_WIDTH-1:0] data_in;

    // Outputs
    wire [DATA_WIDTH-1:0] data_out;
    wire cache_hit;
    wire cache_miss;
    wire [31:0] hit_counter;
    wire [31:0] miss_counter;

    // Instantiate the DUT (Device Under Test)
    main #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .TAG_WIDTH(TAG_WIDTH),
        .CACHE_SIZE(CACHE_SIZE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .read(read),
        .write(write),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .cache_hit(cache_hit),
        .cache_miss(cache_miss),
        .hit_counter(hit_counter),
        .miss_counter(miss_counter)
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
        address = 0;
        data_in = 0;

        // Apply reset
        #10 reset = 0;

        // Initialize main memory (simulate preloading some data)
        dut.main_memory[16'h0010] = 16'hAAAA;  // Example address/data
        dut.main_memory[16'h0020] = 16'hBBBB;

        // Perform a read (cache miss expected)
        #10 address = 16'h0010;
        read = 1;
        #10 read = 0;

        // Perform another read to the same address (cache hit expected)
        #10 address = 16'h0010;
        read = 1;
        #10 read = 0;

        // Perform a read to a different address (cache miss expected)
        #10 address = 16'h0020;
        read = 1;
        #10 read = 0;

        // Perform a write
        #10 address = 16'h0030;
        data_in = 16'hCCCC;
        write = 1;
        #10 write = 0;

        // Read back the written data (cache hit expected)
        #10 address = 16'h0030;
        read = 1;
        #10 read = 0;

        // Display final hit/miss counters
        #10;
        $display("Hit Counter: %d", hit_counter);
        $display("Miss Counter: %d", miss_counter);

        // Finish simulation
        #10 $finish;
    end
endmodule
