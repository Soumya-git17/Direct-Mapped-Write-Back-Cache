package cache_pkg;
    parameter int unsigned ADDR_WIDTH = 32;
    parameter int unsigned DATA_WIDTH = 32;
    parameter int unsigned NUM_LINES  = 16;
    parameter int unsigned WORDS_PER_LINE = 4;

    parameter int unsigned BYTES_PER_WORD = DATA_WIDTH / 8;
    parameter int unsigned BYTE_OFFSET_WIDTH = $clog2(BYTES_PER_WORD);
    parameter int unsigned WORD_OFFSET_WIDTH = $clog2(WORDS_PER_LINE);
    parameter int unsigned INDEX_WIDTH = $clog2(NUM_LINES);

    parameter int unsigned TAG_WIDTH = ADDR_WIDTH - BYTE_OFFSET_WIDTH - WORD_OFFSET_WIDTH - INDEX_WIDTH;

    typedef enum logic [2:0] {
        IDLE      = 3'b000,
        LOOKUP    = 3'b001,
        WRITEBACK = 3'b010,
        REFILL    = 3'b011,
        RESPOND   = 3'b110
    } state_t;

endpackage
