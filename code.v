module main(
    input clk,
    input reset,
    input read,
    input write,
    input [TAG_WIDTH-1:0] tag,
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
    
    localparam INDEX_WIDTH = $clog2(CACHE_SIZE);
    
     

    wire [INDEX_WIDTH-1:0] index = tag[INDEX_WIDTH-1:0];
   
    reg [DATA_WIDTH-1:0] data_array [CACHE_SIZE-1:0];
    reg [TAG_WIDTH-1:0] tag_array [CACHE_SIZE-1:0];
    reg valid_array [CACHE_SIZE-1:0];

    reg [DATA_WIDTH-1:0] main_memory [0:(1 << TAG_WIDTH)-1];

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < CACHE_SIZE; i = i + 1) begin
                valid_array[i] <= 0;
                tag_array[i] <= 0;
                data_array[i] <= 0;
            end
            hit_counter <= 0;
            miss_counter <= 0;
            total_requests <= 0;
        end else if (read) begin
            if (valid_array[index] && tag_array[index] == tag) begin
                cache_hit <= 1;
                cache_miss <= 0;
                hit_counter <= hit_counter + 1;
                total_requests <= total_requests + 1;
                data_out <= data_array[index];
            end else begin
                cache_hit <= 0;
                cache_miss <= 1;
                miss_counter <= miss_counter + 1;
                total_requests <= total_requests + 1;
                
                data_array[index] <= main_memory[tag];
                tag_array[index] <= tag;
                valid_array[index] <= 1;
                
                data_out <= main_memory[tag];
            end
        end else if (write) begin
            data_array[index] <= data_in;
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

    // Clock and reset
    reg clk;
    reg reset;

    // Inputs
    reg read;
    reg write;
    reg [TAG_WIDTH-1:0] tag;
    reg [DATA_WIDTH-1:0] data_in;

    // Outputs
    wire [DATA_WIDTH-1:0] data_out;
    wire cache_hit;
    wire cache_miss;
    wire [31:0] hit_counter;
    wire [31:0] miss_counter;
    wire [31:0] total_requests;
    
    integer start_time;
    integer end_time;
    real delay_time;

    main #(
        .TAG_WIDTH(TAG_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(CACHE_SIZE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .read(read),
        .write(write),
        .tag(tag),
        .data_in(data_in),
        .data_out(data_out),
        .cache_hit(cache_hit),
        .cache_miss(cache_miss),
        .hit_counter(hit_counter),
        .miss_counter(miss_counter),
        .total_requests(total_requests)
    );

    always #5 clk = ~clk;  // 10ns clock period

    initial begin
        
        clk = 0;
        reset = 1;
        read = 0;
        write = 0;
        tag = 16'h0000;
        data_in = 16'h0000;

        #10 reset = 0;

        dut.main_memory[16'h0010] = 16'hAAAA;
        dut.main_memory[16'h2300] = 16'hBBBB;
        
        start_time = $time;

        #10 tag = 16'h0010;
        read = 1;
        #10 read = 0;
        $display("Tag: 0x%h | Data Out: 0x%h | Cache Hit: %d | Cache Miss: %d | Hit Counter: %d | Miss Counter: %d | Total Requests: %d", 
         tag, data_out, cache_hit, cache_miss, hit_counter, miss_counter, total_requests);
        
        #10 tag = 16'h2300;
        read = 1;
        #10 read = 0;
        $display("Tag: 0x%h | Data Out: 0x%h| Cache Hit: %d | Cache Miss: %d | Hit Counter: %d | Miss Counter: %d | Total Requests: %d", 
         tag, data_out, cache_hit, cache_miss, hit_counter, miss_counter, total_requests);

        end_time = $time;
        
        delay_time = (end_time - start_time) * 1.0;
        
        #10;
        $display("Delay Time: %0.2f", delay_time);

        #10 $finish;
    end
endmodule
