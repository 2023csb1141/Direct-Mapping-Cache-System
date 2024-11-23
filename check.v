module CacheLine #(parameter BLOCK_SIZE = 16, TAG_WIDTH = 8) (
    input wire clk,
    input wire reset,
    input wire write_enable,
    input wire valid_in,
    input wire [TAG_WIDTH-1:0] tag_in,
    input wire [BLOCK_SIZE*8-1:0] data_in,
    output reg valid_out,
    output reg [TAG_WIDTH-1:0] tag_out,
    output reg [BLOCK_SIZE*8-1:0] data_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_out <= 0;
            tag_out <= 0;
            data_out <= 0;
        end else if (write_enable) begin
            valid_out <= valid_in;
            tag_out <= tag_in;
            data_out <= data_in;
        end
    end
endmodule




module DirectMappedCache #(parameter ADDR_WIDTH = 16, BLOCK_SIZE = 16, CACHE_LINES = 16) (
    input wire clk,
    input wire reset,
    input wire read_enable,
    input wire write_enable,
    input wire [ADDR_WIDTH-1:0] address,
    input wire [BLOCK_SIZE*8-1:0] write_data,
    output reg [BLOCK_SIZE*8-1:0] read_data,
    output reg hit_miss_indicator,  // 1 for hit, 0 for miss
    output reg [31:0] total_requests,
    output reg [31:0] hits,
    output reg [31:0] misses
);
    // Derived parameters
    localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE);  // Block offset bits
    localparam INDEX_WIDTH = $clog2(CACHE_LINES); // Index bits
    localparam TAG_WIDTH = ADDR_WIDTH - OFFSET_WIDTH - INDEX_WIDTH;

    // Split address into tag, index, and offset
    wire [TAG_WIDTH-1:0] tag = address[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH];
    wire [INDEX_WIDTH-1:0] index = address[OFFSET_WIDTH+INDEX_WIDTH-1:OFFSET_WIDTH];
    wire [OFFSET_WIDTH-1:0] offset = address[OFFSET_WIDTH-1:0];

    // Cache lines
    reg [BLOCK_SIZE*8-1:0] main_memory [0:(1<<ADDR_WIDTH)-1]; // Simulated main memory
    wire valid_out;
    wire [TAG_WIDTH-1:0] tag_out;
    wire [BLOCK_SIZE*8-1:0] data_out;
    reg write_enable_cache;
    reg valid_in;
    reg [TAG_WIDTH-1:0] tag_in;
    reg [BLOCK_SIZE*8-1:0] data_in;

    CacheLine #(BLOCK_SIZE, TAG_WIDTH) cache_lines[CACHE_LINES-1:0] (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable_cache),
        .valid_in(valid_in),
        .tag_in(tag_in),
        .data_in(data_in),
        .valid_out(valid_out),
        .tag_out(tag_out),
        .data_out(data_out)
    );

    // Cache operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            total_requests <= 0;
            hits <= 0;
            misses <= 0;
        end else begin
            total_requests <= total_requests + 1;
            if (read_enable || write_enable) begin
                if (valid_out && tag_out == tag) begin
                    // Cache hit
                    hit_miss_indicator <= 1;
                    hits <= hits + 1;
                    if (read_enable) begin
                        read_data <= data_out;
                    end
                    if (write_enable) begin
                        write_enable_cache <= 1;
                        valid_in <= 1;
                        tag_in <= tag;
                        data_in <= write_data;
                    end
                end else begin
                    // Cache miss
                    hit_miss_indicator <= 0;
                    misses <= misses + 1;
                    // Load from main memory
                    write_enable_cache <= 1;
                    valid_in <= 1;
                    tag_in <= tag;
                    data_in <= main_memory[{tag, index}];
                end
            end
        end
    end
endmodule



module Testbench;
    parameter ADDR_WIDTH = 16;
    parameter BLOCK_SIZE = 16;
    parameter CACHE_LINES = 16;

    reg clk, reset, read_enable, write_enable;
    reg [ADDR_WIDTH-1:0] address;
    reg [BLOCK_SIZE*8-1:0] write_data;
    wire [BLOCK_SIZE*8-1:0] read_data;
    wire hit_miss_indicator;
    wire [31:0] total_requests, hits, misses;

    DirectMappedCache #(ADDR_WIDTH, BLOCK_SIZE, CACHE_LINES) cache (
        .clk(clk),
        .reset(reset),
        .read_enable(read_enable),
        .write_enable(write_enable),
        .address(address),
        .write_data(write_data),
        .read_data(read_data),
        .hit_miss_indicator(hit_miss_indicator),
        .total_requests(total_requests),
        .hits(hits),
        .misses(misses)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        read_enable = 0;
        write_enable = 0;
        address = 0;
        write_data = 0;

        // Reset the system
        #10 reset = 0;

        // Test cases
        #10 address = 16'h0010; read_enable = 1; // Read miss
        #10 address = 16'h0020; read_enable = 1; // Read miss
        #10 address = 16'h0010; read_enable = 1; // Read hit
        #10 address = 16'h0010; write_enable = 1; write_data = 128'hDEADBEEFDEADBEEF; // Write hit

        #50 $finish;
    end
endmodule
