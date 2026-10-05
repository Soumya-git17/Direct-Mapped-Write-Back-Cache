import cache_pkg::*;

module cache_addr_decoder (
    input logic [ADDR_WIDTH-1:0] cpu_addr,
    output logic [TAG_WIDTH-1:0] tag,
    output logic [INDEX_WIDTH-1:0] index,
    output logic [WORD_OFFSET_WIDTH-1:0] word_offset,
    output logic [BYTE_OFFSET_WIDTH-1:0] byte_offset
);

assign byte_offset = cpu_addr[BYTE_OFFSET_WIDTH - 1 : 0];
assign word_offset = cpu_addr[BYTE_OFFSET_WIDTH + WORD_OFFSET_WIDTH - 1 : BYTE_OFFSET_WIDTH];
assign index = cpu_addr[BYTE_OFFSET_WIDTH + WORD_OFFSET_WIDTH + INDEX_WIDTH - 1 : BYTE_OFFSET_WIDTH + WORD_OFFSET_WIDTH];
assign tag = cpu_addr[ADDR_WIDTH - 1 : BYTE_OFFSET_WIDTH + WORD_OFFSET_WIDTH + INDEX_WIDTH];
    
endmodule
