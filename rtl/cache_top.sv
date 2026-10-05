import cache_pkg::*;

module cache_top (
    input logic clk, rst,
    input logic cpu_valid, cpu_write,
    input logic [ADDR_WIDTH-1:0] cpu_addr,
    input logic [DATA_WIDTH-1:0] cpu_wdata,
    input logic [DATA_WIDTH-1:0] mem_rdata,
    input logic mem_ready,
    output logic mem_valid, mem_write,
    output logic [ADDR_WIDTH-1:0] mem_addr,
    output logic [DATA_WIDTH-1:0] mem_wdata,
    output logic [DATA_WIDTH-1:0] cpu_rdata,
    output logic cpu_ready
);

logic [TAG_WIDTH-1:0] tag, tag_in, stored_tag;
logic [INDEX_WIDTH-1:0] index;
logic [BYTE_OFFSET_WIDTH-1:0] byte_offset;
logic [DATA_WIDTH-1:0] data_in, data_out;
logic valid_in, valid_out, dirty_in, dirty_out, tag_write_enable, data_write_enable;
logic [WORD_OFFSET_WIDTH-1:0] word_offset, word_addr;

cache_addr_decoder cad (
    .cpu_addr(cpu_addr), .tag(tag), .index(index),
    .word_offset(word_offset), .byte_offset(byte_offset)
);

cache_data_array cda (
    .clk(clk), .rst(rst), .index(index), .word_offset(word_addr),
    .write_enable(data_write_enable), .data_in(data_in), .data_out(data_out)
);

cache_tag_array cta (
    .clk(clk), .rst(rst), .index(index), .write_enable(tag_write_enable), 
    .tag_in(tag_in), .valid_in(valid_in), .dirty_in(dirty_in),
    .stored_tag(stored_tag), .valid_out(valid_out), .dirty_out(dirty_out)
);

cache_controller cc (
    .clk(clk), .rst(rst), .cpu_valid(cpu_valid), .cpu_write(cpu_write), .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata), .tag(tag), .index(index), .word_offset(word_offset), .stored_tag(stored_tag),
    .valid_out(valid_out), .dirty_out(dirty_out), .data_out(data_out), .mem_rdata(mem_rdata),
    .mem_ready(mem_ready), .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready), .tag_write_enable(tag_write_enable),
    .tag_in(tag_in), .valid_in(valid_in), .dirty_in(dirty_in), .data_write_enable(data_write_enable),
    .data_in(data_in), .mem_valid(mem_valid), .mem_write(mem_write), .mem_addr(mem_addr),
    .mem_wdata(mem_wdata), .word_addr(word_addr)
);

endmodule
