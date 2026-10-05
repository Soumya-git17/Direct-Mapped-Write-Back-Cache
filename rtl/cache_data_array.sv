import cache_pkg::*;

module cache_data_array (
    input  logic clk, rst,
    input  logic [INDEX_WIDTH-1:0] index,
    input  logic [WORD_OFFSET_WIDTH-1:0] word_offset,
    input  logic write_enable,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out
);

integer i, j;
logic [DATA_WIDTH-1:0] data_array[0:NUM_LINES-1][0:WORDS_PER_LINE-1];

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < NUM_LINES; i++) begin
            for (j = 0; j < WORDS_PER_LINE; j++) begin                
                data_array[i][j] <= '0;
            end
        end
    end
    else begin
        if (write_enable) begin
            data_array[index][word_offset] <= data_in;
        end
    end
end

assign data_out = data_array[index][word_offset];

endmodule
