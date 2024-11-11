module CacheTestbench;

    // Parameters for the cache
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter CACHE_SIZE = 16;
    
    // Testbench Signals
    reg clk;
    reg reset;
    reg read;
    reg write;
    reg [ADDR_WIDTH-1:0] address;
    reg [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;
    wire cache_hit;

    // Simulated main memory array (16 blocks of 32-bit data)
    reg [DATA_WIDTH-1:0] main_memory [0:CACHE_SIZE-1];

    // Instantiate the Cache Controller module
    CacheController #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .CACHE_SIZE(CACHE_SIZE)
    ) cache (
        .clk(clk),
        .reset(reset),
        .read(read),
        .write(write),
        .address(address),
        .data_in(data_in),
        .data_out(data_out),
        .cache_hit(cache_hit)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Initialize main memory with some test data
    initial begin
        integer i;
        for (i = 0; i < CACHE_SIZE; i = i + 1) begin
            main_memory[i] = i * 100;  // Arbitrary values for testing
        end
    end

    // Simulation Tasks
    task perform_read(input [ADDR_WIDTH-1:0] addr);
        begin
            read = 1;
            write = 0;
            address = addr;
            #10;
            if (cache_hit) begin
                $display("Cache Hit: Address %h -> Data %h", addr, data_out);
            end else begin
                // Simulate main memory fetch on cache miss
                $display("Cache Miss: Fetching from Main Memory for Address %h", addr);
                cache.data_array[addr[CACHE_SIZE-1:0]] = main_memory[addr[CACHE_SIZE-1:0]];
                cache.tag_array[addr[CACHE_SIZE-1:0]] = addr[ADDR_WIDTH-1:ADDR_WIDTH-CACHE_SIZE];
                cache.valid_array[addr[CACHE_SIZE-1:0]] = 1;
            end
            #10;
            read = 0;
        end
    endtask

    task perform_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            read = 0;
            write = 1;
            address = addr;
            data_in = data;
            #10;
            $display("Write: Address %h -> Data %h", addr, data_in);
            write = 0;
        end
    endtask

    // Test Sequence
    initial begin
        // Reset the cache system
        reset = 1;
        #10 reset = 0;

        // Perform cache operations
        // First, try reading from an empty cache to trigger misses
        $display("Testing Cache Misses:");
        perform_read(16'h0001);  // Should miss, fetching from main memory
        perform_read(16'h0002);  // Should miss, fetching from main memory

        // Now, these addresses should be cached, so they should hit
        $display("\nTesting Cache Hits:");
        perform_read(16'h0001);  // Should hit
        perform_read(16'h0002);  // Should hit

        // Write data to the cache and then read back to verify
        $display("\nTesting Writes:");
        perform_write(16'h0003, 32'hDEADBEEF);
        perform_read(16'h0003);  // Should hit with written data

        // Additional read to an address that’s not cached to trigger another miss
        $display("\nTesting Additional Cache Miss:");
        perform_read(16'h0004);  // Should miss, fetching from main memory

        $display("\nCache Test Completed.");
        $stop;
    end
endmodule
