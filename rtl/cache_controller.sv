import cache_pkg::*;

module cache_controller (
    input  logic clk, rst, cpu_valid, cpu_write,
    input  logic [ADDR_WIDTH-1:0] cpu_addr,
    input  logic [DATA_WIDTH-1:0] cpu_wdata,
    input  logic [TAG_WIDTH-1:0] tag,
    input  logic [INDEX_WIDTH-1:0] index,
    input  logic [WORD_OFFSET_WIDTH-1:0] word_offset,
    input  logic [TAG_WIDTH-1:0] stored_tag,
    input  logic valid_out, dirty_out,
    input  logic [DATA_WIDTH-1:0] data_out,
    input  logic [DATA_WIDTH-1:0] mem_rdata,
    input  logic mem_ready,
    output logic [DATA_WIDTH-1:0] cpu_rdata,
    output logic cpu_ready,
    output logic tag_write_enable,
    output logic [TAG_WIDTH-1:0] tag_in,
    output logic valid_in, dirty_in,
    output logic data_write_enable,
    output logic [DATA_WIDTH-1:0] data_in,
    output logic mem_valid, mem_write, 
    output logic [ADDR_WIDTH-1:0] mem_addr,
    output logic [DATA_WIDTH-1:0] mem_wdata,
    output logic [WORD_OFFSET_WIDTH-1:0] word_addr
);

state_t current_state, next_state;
logic [WORD_OFFSET_WIDTH-1:0] count;
logic reset_count;

always_ff @(posedge clk or posedge rst) begin
    if (rst) count <= '0;
    else if (reset_count) count <= '0;
    else if ((current_state == WRITEBACK || current_state == REFILL) && mem_ready) count <= count + 1'b1;
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) current_state <= IDLE;
    else current_state <= next_state;
end

always_comb begin
    next_state = current_state;
    case (current_state)
        IDLE      : if (cpu_valid) next_state = LOOKUP;
        LOOKUP    : begin
            if (valid_out && (tag == stored_tag)) next_state = IDLE;
            else if (!dirty_out) next_state = REFILL;
            else next_state = WRITEBACK;
        end
        WRITEBACK : if (mem_ready && (count == 3)) next_state = REFILL;
        REFILL    : if (mem_ready && (count == 3)) next_state = RESPOND;
        RESPOND   : next_state = IDLE;
        default   : next_state = IDLE;
    endcase
end

always_comb begin
    cpu_rdata = '0;
    cpu_ready = 1'b0;
    tag_write_enable = 1'b0;
    tag_in = '0;
    valid_in = 1'b0;
    dirty_in = 1'b0;
    data_write_enable = 1'b0;
    data_in = '0;
    mem_valid = 1'b0;
    mem_write = 1'b0;
    mem_addr = '0;
    mem_wdata = '0;
    reset_count = 1'b0;
    if ((current_state == WRITEBACK) || (current_state == REFILL)) word_addr = count;
    else word_addr = word_offset;
    case (current_state)
        IDLE:;
        LOOKUP: begin
            if (valid_out && (tag == stored_tag)) begin
                if (!cpu_write) cpu_rdata = data_out;
                else begin
                    data_write_enable = 1'b1;
                    data_in = cpu_wdata;
                    tag_write_enable = 1'b1;
                    tag_in = tag;
                    valid_in = 1'b1;
                    dirty_in = 1'b1;
                end
                cpu_ready = 1'b1;
            end
            // else reset_count = 1'b1;
        end
        WRITEBACK: begin
            mem_valid = 1'b1;
            mem_write = 1'b1;
            mem_addr = {stored_tag, index, count, 2'b00};
            // word_addr = count;
            mem_wdata = data_out;
            if (mem_ready && (count == 3)) reset_count = 1'b1;
        end
        REFILL: begin
            mem_valid = 1'b1;
            mem_addr = {tag, index, count, 2'b00};
            // word_addr = count;
            if (mem_ready) begin
                data_write_enable = 1'b1;
                data_in = mem_rdata;
                if (count == 3) begin
                    tag_write_enable = 1'b1;
                    tag_in = tag;
                    valid_in = 1'b1;
                    dirty_in = 1'b0;
                end
            end
        end
        RESPOND: begin
            if (!cpu_write) begin
                cpu_rdata = data_out;
            end
            else begin
                data_write_enable = 1'b1;
                data_in = cpu_wdata;
                tag_write_enable = 1'b1;
                tag_in = tag;
                valid_in = 1'b1;
                dirty_in = 1'b1;               
            end
            cpu_ready = 1'b1;
        end
        default:;
    endcase
end

endmodule
