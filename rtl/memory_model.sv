import cache_pkg::*;

module memory_model (
    input clk, rst, mem_valid, mem_write,
    input logic [ADDR_WIDTH-1:0] mem_addr,
    input logic [DATA_WIDTH-1:0] mem_wdata,
    output logic [DATA_WIDTH-1:0] mem_rdata,
    output logic mem_ready
);

logic [DATA_WIDTH-1:0] memory [0:1023];
logic [9:0] word_index;
integer i;

assign word_index = mem_addr[11:2];

always_comb begin
    mem_ready = mem_valid;
    if (mem_valid && !mem_write) mem_rdata = memory[word_index];
    else mem_rdata = '0;
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < 1024; i++) begin
            memory[i] <= '0;
        end
    end
    else begin
        if (mem_valid && mem_write) begin
            memory[word_index] <= mem_wdata;
        end
    end
end

endmodule
