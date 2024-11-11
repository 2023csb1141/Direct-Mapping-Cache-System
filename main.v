module CacheLine #(parameter DATA_WIDTH = 32, TAG_WIDTH = 8) (
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [TAG_WIDTH-1:0] tag_in,
    input wire valid_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [TAG_WIDTH-1:0] tag_out,
    output reg valid_out
);
    reg [DATA_WIDTH-1:0] data;
    reg [TAG_WIDTH-1:0] tag;
    reg valid;

    always @(data_in, tag_in, valid_in) begin
        data = data_in;
        tag = tag_in;
        valid = valid_in;
        data_out = data;
        tag_out = tag;
        valid_out = valid;
    end
endmodule



parameter CACHE_SIZE = 16;       // Number of cache lines
parameter DATA_WIDTH = 32;       // Data width in bits
parameter TAG_WIDTH = 8;         // Tag width in bits

reg [DATA_WIDTH-1:0] data_array[CACHE_SIZE-1:0];
reg [TAG_WIDTH-1:0] tag_array[CACHE_SIZE-1:0];
reg valid_array[CACHE_SIZE-1:0];



parameter ADDR_WIDTH = 16;
parameter INDEX_WIDTH = 4;  // Log2(CACHE_SIZE) if CACHE_SIZE = 16

input [ADDR_WIDTH-1:0] address;

wire [TAG_WIDTH-1:0] tag = address[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH];
wire [INDEX_WIDTH-1:0] index = address[INDEX_WIDTH-1:0];



input [ADDR_WIDTH-1:0] address;
output reg [DATA_WIDTH-1:0] data_out;
output reg cache_hit;

always @(address) begin
    if (valid_array[index] && (tag_array[index] == tag)) begin
        data_out = data_array[index];
        cache_hit = 1;
    end else begin
        // Cache miss logic here, fetch from main memory
        cache_hit = 0;
    end
end



input wire write_enable;
input [DATA_WIDTH-1:0] data_in;

always @(posedge clk) begin
    if (write_enable) begin
        // Cache write
        data_array[index] = data_in;
        tag_array[index] = tag;
        valid_array[index] = 1;

        // Write-through to main memory (not shown here, would need an external signal)
    end
end



always @(posedge clk) begin
    if (!cache_hit) begin
        // Simulate fetching data from main memory
        data_array[index] = main_memory_data;
        tag_array[index] = tag;
        valid_array[index] = 1;
    end
end



module CacheController(
    input clk,
    input reset,
    input read,
    input write,
    input [ADDR_WIDTH-1:0] address,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg cache_hit
);
    // Instantiate Cache Array and other components here
    
    always @(posedge clk) begin
        if (reset) begin
            // Reset cache contents
        end else if (read) begin
            // Handle read operation
        end else if (write) begin
            // Handle write operation
        end
    end
endmodule
