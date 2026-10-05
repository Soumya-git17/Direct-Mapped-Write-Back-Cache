import cache_pkg::*;

module cache_tag_array (
    input logic clk, rst,
    input logic [INDEX_WIDTH-1:0] index,
    input logic write_enable, 
    input logic [TAG_WIDTH-1:0] tag_in,
    input logic valid_in, dirty_in,
    output logic [TAG_WIDTH-1:0] stored_tag,
    output logic valid_out, dirty_out
);

integer i;
logic [TAG_WIDTH-1:0] tag_array [0:NUM_LINES-1];
logic valid_array [0:NUM_LINES-1];
logic dirty_array [0:NUM_LINES-1];

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < NUM_LINES; i++) begin
            tag_array[i]   <= '0;
            valid_array[i] <= 1'b0;
            dirty_array[i] <= 1'b0;
        end
    end
    else begin
        if (write_enable) begin
            tag_array[index]   <= tag_in;
            valid_array[index] <= valid_in;
            dirty_array[index] <= dirty_in;
        end
    end
end

assign stored_tag = tag_array[index];
assign valid_out  = valid_array[index];
assign dirty_out  = dirty_array[index];

endmodule
