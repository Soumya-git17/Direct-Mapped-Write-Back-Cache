TOP = tb_cache

RTL = \
	rtl/cache_pkg.sv \
	rtl/cache_addr_decoder.sv \
	rtl/cache_data_array.sv \
	rtl/cache_tag_array.sv \
	rtl/cache_controller.sv \
	rtl/memory_model.sv \
	rtl/cache_top.sv

TB = tb/tb_cache.sv

all: 
	verilator --binary --timing --trace --sv \
	--timescale 1ns/1ps \
	--top-module $(TOP) \
	$(RTL) $(TB)

run: all
	./obj_dir/V$(TOP)

debug: all
	./obj_dir/V$(TOP) +DEBUG

lint:
	mkdir -p lint
	verilator --lint-only -Wall --Wno-IMPORTSTAR --Wno-SYNCASYNCNET --sv \
	--top-module $(TOP) \
	$(RTL) $(TB) 2>&1 | tee lint/lint.log

clean:
	rm -rf obj_dir lint *.vcd

wave:
	gtkwave tb_cache.vcd