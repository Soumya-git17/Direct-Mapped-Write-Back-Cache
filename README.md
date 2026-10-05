# Direct-Mapped Write-Back Cache in SystemVerilog

A parameterized **32-bit direct-mapped cache** implemented in SystemVerilog with **write-back** and **write-allocate** policies. The design includes valid/dirty tracking, multi-word cache-line refill, dirty-line writeback, and a self-checking verification environment with directed and randomized testing.

## Features

* 32-bit address and data width
* Direct-mapped cache organization
* 16 cache lines
* 4 × 32-bit words per cache line
* 16-byte cache line size
* 256-byte total cache capacity
* Valid and dirty bits
* Write-back policy
* Write-allocate on write misses
* 4-word cache-line refill
* 4-word dirty-line writeback
* Parameterized cache configuration
* Word-aligned 32-bit CPU accesses

## Architecture

### Address Mapping

```text
31                         8 7       4 3     2 1     0
┌───────────────────────────┬─────────┬───────┬───────┐
│           TAG             │  INDEX  │ WORD  │ BYTE  │
│          24 bits          │ 4 bits  │2 bits │2 bits │
└───────────────────────────┴─────────┴───────┴───────┘
```

For the default configuration:

| Parameter       |     Value |
| --------------- | --------: |
| Address width   |   32 bits |
| Data width      |   32 bits |
| Number of lines |        16 |
| Words per line  |         4 |
| Bytes per word  |         4 |
| Cache line size |  16 bytes |
| Cache capacity  | 256 bytes |
| Tag width       |   24 bits |
| Index width     |    4 bits |
| Word offset     |    2 bits |
| Byte offset     |    2 bits |

### Block Diagram

```text
                       CPU
                        │
                        ▼
              ┌──────────────────┐
              │ Address Decoder  │
              │ Tag / Index /    │
              │ Word / Byte Off. │
              └────────┬─────────┘
                       │
              ┌────────┴────────┐
              │                 │
              ▼                 ▼
       ┌─────────────┐   ┌─────────────┐
       │  Tag Array  │   │  Data Array │
       │ Tag/Valid/  │   │ 16 × 4      │
       │ Dirty       │   │ words       │
       └──────┬──────┘   └──────┬──────┘
              │                 │
              └────────┬────────┘
                       ▼
              ┌──────────────────┐
              │ Cache Controller │
              └────────┬─────────┘
                       │
                       ▼
                Memory Interface
```

## Controller

The cache controller uses five states:

```text
                    ┌──────────┐
                    │   IDLE   │
                    └────┬─────┘
                         │ CPU request
                         ▼
                    ┌──────────┐
                    │  LOOKUP  │
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
             HIT     CLEAN MISS   DIRTY MISS
              │          │          │
              ▼          ▼          ▼
             IDLE      REFILL    WRITEBACK
                                      │
                                      ▼
                                   REFILL
                                      │
                                      ▼
                                  RESPOND
                                      │
                                      ▼
                                     IDLE
```

### Cache Hit

A request is a hit when:

```text
valid = 1
AND
requested tag = stored tag
```

Read hits return the cached data without accessing memory.

Write hits update the cache data and set the dirty bit.

### Clean Miss

For an invalid or clean cache line:

```text
LOOKUP → REFILL
```

The requested cache line is fetched from memory one word at a time.

### Dirty Miss

When the selected cache line is valid and dirty:

```text
LOOKUP → WRITEBACK → REFILL
```

The old cache line is written back to memory before the new line is loaded.

## RTL Structure

```text
rtl/
├── cache_pkg.sv
├── cache_addr_decoder.sv
├── cache_data_array.sv
├── cache_tag_array.sv
├── cache_controller.sv
├── cache_top.sv
└── memory_model.sv

tb/
└── tb_cache.sv
```

### Module Responsibilities

**`cache_pkg.sv`**

* Cache parameters
* Derived address-width parameters
* Controller state definitions

**`cache_addr_decoder.sv`**

* Splits CPU address into tag, index, word offset, and byte offset

**`cache_tag_array.sv`**

* Stores tag, valid, and dirty information

**`cache_data_array.sv`**

* Stores cache-line data

**`cache_controller.sv`**

* Implements hit/miss detection
* Controls refill
* Controls dirty-line writeback
* Generates CPU and memory interface control signals

**`cache_top.sv`**

* Integrates the cache datapath and controller

**`memory_model.sv`**

* Behavioral backing-memory model used during simulation

## Verification

The project includes a self-checking SystemVerilog testbench with both directed and randomized verification.

### Directed Tests

The testbench covers:

* Read miss and cache-line refill
* Read hit
* Write hit
* Dirty-line eviction
* Clean-line eviction
* Access to all four words within a cache line
* Write miss with dirty eviction
* Four-word dirty writeback
* Memory traffic verification
* Writeback data integrity

### Randomized Testing

The testbench additionally performs **500 randomized read/write transactions** against a reference memory model.

Randomized accesses verify that:

```text
CPU operation
     ↓
Cache behavior
     ↓
Reference memory
```

remain consistent across hits, misses, refills, writes, and evictions.

### Verification Infrastructure

The testbench includes:

* CPU read/write transaction tasks
* Memory traffic counters
* Reference memory
* Expected-data checking
* Memory-content checking
* Timeout/watchdog protection
* Optional debug transaction logging
* VCD waveform generation

## Running the Simulation

Build and run the testbench:

```bash
make run
```

Run with memory transaction debug output:

```bash
make debug
```

Run Verilator lint:

```bash
make lint
```

Open the generated waveform:

```bash
make wave
```

Clean generated simulation files:

```bash
make clean
```

## Verification Status

| Test                      | Status |
| ------------------------- | ------ |
| Read miss / refill        | ✅      |
| Read hit                  | ✅      |
| Write hit                 | ✅      |
| Dirty eviction            | ✅      |
| Clean eviction            | ✅      |
| Whole-line access         | ✅      |
| Write miss                | ✅      |
| Dirty writeback           | ✅      |
| Memory traffic checking   | ✅      |
| Randomized testing        | ✅      |
| VCD waveform generation   | ✅      |

## Future Work

* Add SystemVerilog Assertions (SVA)
* Add functional coverage
* Complete RTL lint cleanup
* Synthesize using Yosys
* Perform timing analysis
* Run the design through a SKY130 RTL-to-GDS flow
* Analyze area, timing, and power results
* Add byte-enable support for sub-word writes
* Explore set-associative cache extensions

## Tools

* SystemVerilog
* Verilator
* GTKWave
