import cache_pkg::*;

module tb_cache;
logic clk, rst;
logic cpu_valid, cpu_write;
logic [ADDR_WIDTH-1:0] cpu_addr;
logic [DATA_WIDTH-1:0] cpu_wdata;
logic [DATA_WIDTH-1:0] mem_rdata;
logic mem_ready;
logic mem_valid, mem_write;
logic [ADDR_WIDTH-1:0] mem_addr;
logic [DATA_WIDTH-1:0] mem_wdata;
logic [DATA_WIDTH-1:0] cpu_rdata;
logic cpu_ready;

cache_top dut (
    .clk(clk), .rst(rst), .cpu_valid(cpu_valid), .cpu_write(cpu_write), .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata), .mem_rdata(mem_rdata), .mem_ready(mem_ready), .mem_valid(mem_valid),
    .mem_write(mem_write), .mem_addr(mem_addr), .mem_wdata(mem_wdata), .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready)
);

memory_model mem (
    .clk(clk), .rst(rst), .mem_valid(mem_valid), .mem_write(mem_write), .mem_addr(mem_addr),
    .mem_wdata(mem_wdata), .mem_rdata(mem_rdata), .mem_ready(mem_ready)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

int errors = 0;
int rd_count = 0;
int wr_count = 0;

always @(posedge clk) begin
    if (!rst && mem_valid && mem_ready) begin
        if (mem_write) wr_count++; else rd_count++;
    end
end

task automatic clear_cnt();
    rd_count = 0;
    wr_count = 0;
endtask

task automatic check_traffic(
    input string what,
    input int rd,
    input int wr
);
    if (rd_count != rd || wr_count != wr) begin
        $display("FAIL [%s]: mem traffic exp rd=%0d wr=%0d, got rd=%0d wr=%0d @%0t",
                 what, rd, wr, rd_count, wr_count, $time);
        errors++;
    end
endtask

task automatic check_mem(
    input int w,
    input logic [DATA_WIDTH-1:0] exp,
    input string what
);
    if (mem.memory[w] !== exp) begin
        $display("FAIL [%s]: memory[%0d] exp=%h got=%h", what, w, exp, mem.memory[w]);
        errors++;
    end
endtask

task automatic wait_mem_idle();
    int idle = 0;
    int n = 0;
    while (idle < 3) begin
        @(posedge clk);
        if (++n > 200) begin $display("FAIL: memory never idle"); errors++; return; end
        idle = mem_valid ? 0 : idle + 1;
    end
endtask

task automatic reset();
    rst = 1'b1;
    cpu_valid = 1'b0;
    cpu_write = 1'b0;
    cpu_addr  =  '0;
    cpu_wdata =  '0;
    repeat (2) @(posedge clk);
    rst = 1'b0;
endtask

task automatic cpu_read_task(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] expected
);
    int timeout = 0;
    @(posedge clk);
    cpu_valid <= 1'b1;
    cpu_write <= 1'b0;
    cpu_addr  <= addr;
    do begin
        @(posedge clk);
        timeout++;
        if (timeout > 100) begin
            $display("CPU READ TIMEOUT addr=%h", addr);
            errors++;
            cpu_valid <= 1'b0;
            return;
        end
    end while (!cpu_ready);
    if (cpu_rdata !== expected) begin
        $display("CPU READ FAILED: expected=%h got=%h", expected, cpu_rdata);
        errors++;
    end 
    cpu_valid <= 1'b0;
    @(posedge clk);
endtask

task automatic cpu_write_task(
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data
);
    int timeout = 0;
    @(posedge clk);
    cpu_valid <= 1'b1;
    cpu_write <= 1'b1;
    cpu_addr  <= addr;
    cpu_wdata <= data;
    do begin
        @(posedge clk);
        timeout++;
        if (timeout > 100) begin
            $display("CPU WRITE TIMEOUT addr=%h", addr);
            errors++;
            cpu_valid <= 1'b0;
            cpu_write <= 1'b0;
            cpu_wdata <= '0;
            return;
        end
    end while (!cpu_ready);
    cpu_valid <= 1'b0;
    cpu_write <= 1'b0;
    cpu_wdata <= '0;
    @(posedge clk);
endtask

task automatic test_dirty_evict();
    reset();
    mem.memory[0]  = 32'h11110000;
    mem.memory[1]  = 32'h11111111;
    mem.memory[2]  = 32'h12345678;
    mem.memory[3]  = 32'h11113333;
    mem.memory[64] = 32'h98765432;

    clear_cnt(); cpu_read_task (32'h8, 32'h12345678); check_traffic("read miss", 4, 0);
    clear_cnt(); cpu_write_task(32'h8, 32'hDEADBEEF); check_traffic("write hit", 0, 0);
    clear_cnt(); cpu_read_task (32'h8, 32'hDEADBEEF); check_traffic("read hit" , 0, 0);

    clear_cnt(); cpu_read_task(32'h100, 32'h98765432);   // dirty eviction
    wait_mem_idle();
    check_traffic("dirty miss", 4, 4);   // writeback + fill

    check_mem(0, 32'h11110000, "wb word0 untouched");
    check_mem(1, 32'h11111111, "wb word1 untouched");
    check_mem(2, 32'hDEADBEEF, "wb word2 dirty");
    check_mem(3, 32'h11113333, "wb word3 untouched");
endtask

task automatic test_clean_evict();
    reset();
    mem.memory[64] = 32'hCAFEF00D;
    mem.memory[128] = 32'hABCDEF01;
    cpu_read_task(32'h100, 32'hCAFEF00D);
    clear_cnt();
    cpu_read_task(32'h200, 32'hABCDEF01);
    wait_mem_idle();
    check_traffic("clean evict", 4, 0);    // fill only, zero writes
endtask

task automatic test_line_words();
    reset();
    mem.memory[0] = 32'hAAAA0000;  mem.memory[1] = 32'hBBBB1111;
    mem.memory[2] = 32'hCCCC2222;  mem.memory[3] = 32'hDDDD3333;
    clear_cnt();
    cpu_read_task(32'h0, 32'hAAAA0000);
    cpu_read_task(32'h4, 32'hBBBB1111);
    cpu_read_task(32'h8, 32'hCCCC2222);
    cpu_read_task(32'hC, 32'hDDDD3333);
    check_traffic("one fill for whole line", 4, 0);
endtask

task automatic test_write_miss_dirty();
    reset();
    mem.memory[2]  = 32'h22223333;
    mem.memory[64] = 32'hCAFE0000;
    mem.memory[65] = 32'hCAFE1111;
    cpu_read_task(32'h8, 32'h22223333);
    cpu_write_task(32'h8, 32'hDEADBEEF);  // dirty it
    clear_cnt();
    cpu_write_task(32'h100, 32'h0BADF00D);  // write MISS on a dirty line
    wait_mem_idle();
    check_traffic("write miss dirty", 4, 4);
    check_mem(2, 32'hDEADBEEF, "old dirty line written back");
    cpu_read_task(32'h100, 32'h0BADF00D);   // the written word
    cpu_read_task(32'h104, 32'hCAFE1111);   // neighbour must come from the fill
endtask

logic [DATA_WIDTH-1:0] ref_mem [256];
task automatic test_random(input int n = 500);
    int w;
    reset();
    for (int i = 0; i < 256; i++) begin
        ref_mem[i] = $urandom;
        mem.memory[i] = ref_mem[i];
    end
    repeat (n) begin
        w = $urandom_range(0, 255);
        if ($urandom_range(0,1) != 0) begin
            ref_mem[w] = $urandom;
            cpu_write_task(w*4, ref_mem[w]);
        end
        else cpu_read_task(w*4, ref_mem[w]);
    end 
endtask

initial begin
    $dumpfile("tb_cache.vcd");
    $dumpvars(0, tb_cache);
end

initial begin
    test_dirty_evict();
    test_clean_evict();
    test_line_words();
    test_write_miss_dirty();
    test_random();
    wait_mem_idle();
    if (errors == 0) $display("ALL TESTS PASSED");
    else $fatal(1, "%0d TEST(S) FAILED", errors);
    $finish;
end

initial begin #2_000_000; $fatal(1, "WATCHDOG timeout"); end

always @(posedge clk) begin
    if ($test$plusargs("DEBUG") && mem_valid) begin
        $display("MEM: write=%b addr=%h word_addr=%d rdata=%h ready=%b",
            mem_write, mem_addr, dut.word_addr, mem_rdata, mem_ready);
    end
end

endmodule
