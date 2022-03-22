# export RISCV_PPU_DIR=/path/to/RISCV-PPU

all: \
	ppu_P8E0 \
	ppu_P8E1 \
	ppu_P16E0 \
	ppu_P16E1 \
	ppu_P16E2 \
	div-against-pacogen_P8E0 \
	div-against-pacogen_P16E1 \
	div-against-pacogen_P32E2 \


.PHONY : all modelsim


QUARTUS_DIR := $(RISCV_PPU_DIR)/ppu/fpga/quartus
VIVADO_DIR := $(RISCV_PPU_DIR)/ppu/fpga/vivado

SCRIPTS_DIR := $(RISCV_PPU_DIR)/ppu/scripts
SRC_DIR := $(RISCV_PPU_DIR)/ppu/src
SIM_DIR := $(RISCV_PPU_DIR)/ppu/sim
WAVEFORMS_DIR := $(SIM_DIR)/waveforms
PACOGEN_DIR := $(RISCV_PPU_DIR)/PaCoGen

BUILD_DIR := $(RISCV_PPU_DIR)/ppu/build



GREEN='\033[0;32m'
NC='\033[0m' # No Color


ifeq ($(ES),0)
ES_FIELD_PRESENCE_FLAG := -DNO_ES_FIELD
endif

ifeq ($(DIV_WITH_LUT),1)
DIV_WITH_LUT_FLAG := -DDIV_WITH_LUT -DLUT_SIZE_IN=$(LUT_SIZE_IN) -DLUT_SIZE_OUT=$(LUT_SIZE_OUT)
else
LUT_SIZE_IN := 8
LUT_SIZE_OUT := 9
endif

ifeq ($(F),0)
else
FLOAT_TO_POSIT_FLAG := -DFLOAT_TO_POSIT -DF=$(F)
SRC_CONVERSIONS_PPU := \
	$(SRC_DIR)/conversions/defines.vh \
	$(SRC_DIR)/conversions/float_decoder.sv

endif


NR_STAGES := $(ES) 	# newton-raphson stages. actually it's 0 for N in (0..=8), 1 for N in (9..=16), 2 for N in (17..=32)

NUM_TESTS_PPU := 100

SRC_PPU_CORE_OPS := \
	$(SRC_DIR)/utils.sv \
	$(SRC_DIR)/constants.vh \
	$(SRC_DIR)/common.sv \
	$(SRC_DIR)/ppu_core_ops.sv \
	$(SRC_DIR)/posit_to_fir.sv \
	$(SRC_DIR)/demux1_to_2.sv \
	$(SRC_DIR)/fir_to_posit.sv \
	$(SRC_DIR)/conversions/float_encoder.sv \
	$(SRC_DIR)/conversions/sign_extend.sv \
	$(SRC_DIR)/conversions/float_to_fir.sv \
	$(SRC_DIR)/conversions/fir_to_float.sv \
	$(SRC_DIR)/input_conditioning.sv \
	$(SRC_DIR)/handle_special_or_trivial.sv \
	$(SRC_DIR)/total_exponent.sv \
	$(SRC_DIR)/ops.sv \
	$(SRC_DIR)/core_op.sv \
	$(SRC_DIR)/core_add_sub.sv \
	$(SRC_DIR)/core_add.sv \
	$(SRC_DIR)/core_sub.sv \
	$(SRC_DIR)/core_mul.sv \
	$(SRC_DIR)/core_div.sv \
	$(SRC_DIR)/fast_reciprocal.sv \
	$(SRC_DIR)/lut.sv \
	$(SRC_DIR)/reciprocal_approx.sv \
	$(SRC_DIR)/newton_raphson.sv \
	$(SRC_DIR)/pack_fields.sv \
	$(SRC_DIR)/unpack_exponent.sv \
	$(SRC_DIR)/compute_rounding.sv \
	$(SRC_DIR)/posit_unpack.sv \
	$(SRC_DIR)/posit_decoder.sv \
	$(SRC_DIR)/posit_encoder.sv \
	$(SRC_DIR)/lzc.sv \
	$(SRC_DIR)/round_posit.sv \
	$(SRC_DIR)/sign_decisor.sv \
	$(SRC_DIR)/set_sign.sv \
	$(SRC_DIR)/highest_set.sv \
	$(SRC_CONVERSIONS_PPU)

SRC_DIV_AGAINST_PACOGEN := \
	$(SRC_PPU_CORE_OPS) \
	$(PACOGEN_DIR)/common.v \
	$(PACOGEN_DIR)/div/posit_div.v \
	$(SRC_DIR)/comparison_against_pacogen.sv 

SRC_FLOAT_TO_POSIT := \
	$(SRC_DIR)/utils.sv \
	$(SRC_DIR)/common.sv \
	$(SRC_DIR)/conversions/defines.vh \
	$(SRC_DIR)/conversions/float_to_posit.sv \
	$(SRC_DIR)/conversions/float_to_fir.sv \
	$(SRC_DIR)/conversions/float_decoder.sv \
	$(SRC_DIR)/fir_to_posit.sv \
	$(SRC_DIR)/posit_encoder.sv \
	$(SRC_DIR)/round_posit.sv \
	$(SRC_DIR)/pack_fields.sv \
	$(SRC_DIR)/compute_rounding.sv \
	$(SRC_DIR)/unpack_exponent.sv \
	$(SRC_DIR)/set_sign.sv
	
SRC_POSIT_TO_FLOAT := \
	$(SRC_DIR)/utils.sv \
	$(SRC_DIR)/common.sv \
	$(SRC_DIR)/conversions/defines.vh \
	$(SRC_DIR)/conversions/posit_to_float.sv \
	$(SRC_DIR)/conversions/fir_to_float.sv \
	$(SRC_DIR)/conversions/float_encoder.sv \
	$(SRC_DIR)/conversions/sign_extend.sv \
	$(SRC_DIR)/posit_to_fir.sv \
	$(SRC_DIR)/posit_decoder.sv \
	$(SRC_DIR)/posit_unpack.sv \
	$(SRC_DIR)/total_exponent.sv \
	$(SRC_DIR)/lzc.sv \
	$(SRC_DIR)/highest_set.sv


gen-test-vectors:
	cd $(SCRIPTS_DIR) && \
	python tb_gen.py --num-tests $(NUM_TESTS_PPU) --operation ppu -n $(N) -es $(ES) --shuffle-random \
	# python tb_gen.py --num-tests $(NUM_TESTS_PPU) --operation ppu -n 5  -es 1 && \
	# python tb_gen.py --num-tests $(NUM_TESTS_PPU) --operation ppu -n 8  -es 0 && \
	# python tb_gen.py --num-tests $(NUM_TESTS_PPU) --operation ppu -n 8  -es 4 && \
	# python tb_gen.py --num-tests $(NUM_TESTS_PPU) --operation ppu -n 16 -es 1 && \
	# python tb_gen.py --num-tests $(NUM_TESTS_PPU) --operation ppu -n 32 -es 2 

gen-lut-reciprocate-mant:
	python $(SCRIPTS_DIR)/mant_recip_LUT_gen.py -i $(LUT_SIZE_IN) -o $(LUT_SIZE_OUT) > $(SRC_DIR)/lut.sv 

ppu-core_ops:
	cd $(SCRIPTS_DIR) && python tb_gen.py --num-tests $(NUM_TESTS_PPU) --operation ppu -n $(N) -es $(ES) --no-shuffle-random
	cd $(WAVEFORMS_DIR) && \
	iverilog -g2012 -DTEST_BENCH_PPU_CORE_OPS \
	$(ES_FIELD_PRESENCE_FLAG) $(FLOAT_TO_POSIT_FLAG) \
	-DN=$(N) -DES=$(ES) \
	-o ppu_core_ops_P$(N)E$(ES).out \
	$(SRC_PPU_CORE_OPS) && \
	sleep 1 && \
	./ppu_core_ops_P$(N)E$(ES).out


ppu: gen-lut-reciprocate-mant verilog-quartus
	cd $(SCRIPTS_DIR) && python tb_gen.py --num-tests $(NUM_TESTS_PPU) --operation ppu -n $(N) -es $(ES) --shuffle-random
	cd $(WAVEFORMS_DIR) && \
	iverilog -g2012 -DTEST_BENCH_PPU \
	$(ES_FIELD_PRESENCE_FLAG) \
	$(DIV_WITH_LUT_FLAG) \
	-DWORD=$(WORD) -DN=$(N) -DES=$(ES) $(FLOAT_TO_POSIT_FLAG) -DF=$(F) \
	-o ppu_P$(N)E$(ES).out \
	$(SRC_DIR)/ppu.sv \
	$(SRC_PPU_CORE_OPS) && \
	sleep 1 && \
	./ppu_P$(N)E$(ES).out
	make lint

tb_pipelined:
	cd $(WAVEFORMS_DIR) && \
	iverilog -g2012 \
	$(ES_FIELD_PRESENCE_FLAG) \
	$(DIV_WITH_LUT_FLAG) \
	-DWORD=$(WORD) -DN=$(N) -DES=$(ES) $(FLOAT_TO_POSIT_FLAG) -DF=$(F) \
	-o tb_pipelined_P$(N)E$(ES).out \
	$(SRC_DIR)/tb_pipelined.sv \
	$(SRC_DIR)/ppu_top.sv \
	$(SRC_DIR)/ppu.sv \
	$(SRC_PPU_CORE_OPS) && \
	sleep 1 && \
	./tb_pipelined_P$(N)E$(ES).out


ppu_P8E0:
	make ppu N=8 ES=0 F=32 WORD=32 DIV_WITH_LUT=0

ppu_P8E1:
	make ppu N=8 ES=1 F=32 WORD=32 DIV_WITH_LUT=0

ppu_P16E0:
	make ppu N=16 ES=0 F=32 WORD=32 DIV_WITH_LUT=0

ppu_P16E1:
	make ppu N=16 ES=1 F=32 WORD=32 DIV_WITH_LUT=0

ppu_P16E2:
	make ppu N=16 ES=2 F=32 WORD=32 DIV_WITH_LUT=0

ppu_P32E2:
	make ppu N=32 ES=2 F=32 WORD=32 DIV_WITH_LUT=0


float_to_posit:
	cd $(SCRIPTS_DIR) && python tb_gen_float_2_posit.py -n $(N) -es $(ES) -f $(F) --no-shuffle-random --num-tests 100 > $(SIM_DIR)/test_vectors/tv_float_to_posit_P$(N)E$(ES)_F$(F).sv
	cd $(WAVEFORMS_DIR) && \
	iverilog -g2012 \
	-DN=$(N) $(ES_FIELD_PRESENCE_FLAG) -DES=$(ES) $(FLOAT_TO_POSIT_FLAG) -DF=$(F) \
	-DTB_FLOAT_TO_POSIT \
	-o float_to_posit.out \
	$(SRC_FLOAT_TO_POSIT) && \
	./float_to_posit.out
	gtkwave $(WAVEFORMS_DIR)/tb_float_F$(F)_to_posit_P$(N)E$(ES).vcd &
	

posit_to_float:
	cd $(SCRIPTS_DIR) && python tb_gen_posit_2_float.py -n $(N) -es $(ES) -f $(F) --no-shuffle-random --num-tests 100 > $(SIM_DIR)/test_vectors/tv_posit_to_float_P$(N)E$(ES)_F$(F).sv
	cd $(WAVEFORMS_DIR) && \
	iverilog -g2012 \
	-DN=$(N) $(ES_FIELD_PRESENCE_FLAG) -DES=$(ES) $(FLOAT_TO_POSIT_FLAG) -DF=$(F) \
	-DTB_POSIT_TO_FLOAT \
	-o posit_to_float.out \
	$(SRC_POSIT_TO_FLOAT) && \
	./posit_to_float.out
	gtkwave $(WAVEFORMS_DIR)/tb_posit_P$(N)E$(ES)_to_float_F$(F).vcd &


conversions-verilog-posit-to-float-quartus:
	cd $(QUARTUS_DIR) && \
	sv2v -DN=$(N) $(ES_FIELD_PRESENCE_FLAG) -DES=$(ES) -DF=$(F) \
	$(SRC_POSIT_TO_FLOAT) \
	> posit_to_float.v && cp posit_to_float.v ppu.v

conversions-verilog-float-to-posit-quartus:
	cd $(QUARTUS_DIR) && \
	sv2v -DN=$(N) $(ES_FIELD_PRESENCE_FLAG) -DES=$(ES) -DF=$(F) \
	$(SRC_FLOAT_TO_POSIT) \
	> float_to_posit.v && cp float_to_posit.v ppu.v
	

yosys:
	cd $(SRC_DIR) && \
	yosys -p "synth_xilinx -edif example.edif -top ppu_top" $(QUARTUS_DIR)/ppu_top.v > yosys_ppu_top.out
	# yosys -p "synth_intel -family max10 -top ppu -vqm ppu.vqm" \
	# $(QUARTUS_DIR)/ppu_top.v > yosys_ppu.out


verilog-quartus:
	cd $(QUARTUS_DIR) && \
	sv2v \
	$(ES_FIELD_PRESENCE_FLAG) \
	$(DIV_WITH_LUT_FLAG) -DLUT_SIZE_IN=$(LUT_SIZE_IN) -DLUT_SIZE_OUT=$(LUT_SIZE_OUT) \
	$(FLOAT_TO_POSIT_FLAG) \
	-DWORD=$(WORD) -DN=$(N) -DES=$(ES) -DF=$(F) \
	$(SRC_DIR)/ppu_top.sv \
	$(SRC_DIR)/ppu.sv \
	$(SRC_PPU_CORE_OPS) > ppu_top.v && \
	iverilog ppu_top.v && ./a.out
	cp -r $(QUARTUS_DIR)/ppu_top.v $(VIVADO_DIR)/ppu_top.v


verilog-quartus16:
	make verilog-quartus N=16 ES=0 F=0


lint:
	slang $(QUARTUS_DIR)/ppu_top.v --top ppu_top # https://github.com/MikePopoloski/slang

fmt:
	# https://github.com/chipsalliance/verible
	verible-verilog-format --inplace --indentation_spaces 4 */*.sv

div-against-pacogen:
	cd $(SCRIPTS_DIR) && python tb_gen.py --operation pacogen -n $(N) -es $(ES) --num-tests 3000 --shuffle-random
	cd $(WAVEFORMS_DIR) && \
	iverilog -g2012 -DN=$(N) -DES=$(ES) -DNR=$(NR_STAGES) $(ES_FIELD_PRESENCE_FLAG) -DTEST_BENCH_COMP_PACOGEN -o comparison_against_pacogen$(N).out \
	$(SRC_DIV_AGAINST_PACOGEN) \
	&& ./comparison_against_pacogen$(N).out > comparison_against_pacogen$(N).log
	cd $(SCRIPTS_DIR) && python pacogen_log_stats.py -n $(N) -es $(ES)

div-against-pacogen_P8E0:
	make div-against-pacogen N=8 ES=0 F=0

div-against-pacogen_P16E1:
	make div-against-pacogen N=16 ES=1 F=0

div-against-pacogen_P32E2:
	make div-against-pacogen N=32 ES=2 F=0

clean:
	rm $(WAVEFORMS_DIR)/*.out
	
open-waveforms:
	gtkwave $(WAVEFORMS_DIR)/tb_ppu_P8E0.gtkw &
	gtkwave $(WAVEFORMS_DIR)/tb_ppu_P16E1.gtkw &
	gtkwave $(WAVEFORMS_DIR)/tb_ppu_P32E2.gtkw &
	gtkwave $(WAVEFORMS_DIR)/tb_comparison_against_pacogenP8E0.gtkw &
	gtkwave $(WAVEFORMS_DIR)/tb_comparison_against_pacogenP16E1.gtkw &
	gtkwave $(WAVEFORMS_DIR)/tb_comparison_against_pacogenP32E2.gtkw &

modelsim:
	make verilog-quartus N=16 ES=1 WORD=64 F=64
	cp quartus/ppu.v modelsim/ppu.v
	# do ppu.do
