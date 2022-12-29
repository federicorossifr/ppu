`ifdef FLOAT_TO_POSIT
module float_encoder #(
  parameter FSIZE = `F
)(
  input                                       sign,
  input signed [FLOAT_EXP_SIZE_F`F-1:0]       exp,
  input [FLOAT_MANT_SIZE_F`F-1:0]             frac,
  output [FSIZE-1:0]                          bits
);

  wire [FLOAT_EXP_SIZE_F`F-1:0] exp_bias = (1 << (FLOAT_EXP_SIZE_F`F - 1)) - 1;

  wire [FLOAT_EXP_SIZE_F`F-1:0] exp_biased;
  assign exp_biased = exp + exp_bias;
  assign bits = {sign, exp_biased, frac};

endmodule: float_encoder
`endif



`ifdef TB_FLOAT_DECODE
`define STRINGIFY(DEFINE) $sformatf("%0s", `"DEFINE`")
module tb_float_encoder;
  parameter FSIZE = `F
  
  reg sign;
  reg [FLOAT_EXP_SIZE-1:0] exp;
  reg [FLOAT_MANT_SIZE-1:0] frac;
  wire [FSIZE-1:0] bits;

  float_encoder #(
    .FSIZE(FSIZE)
  ) float_encoder_inst (
    .sign(sign),
    .exp(exp),
    .frac(frac),
    .bits(bits)
  );

  initial begin
    $dumpfile({"tb_float_encoder_F",`STRINGIFY(`FSIZE),".vcd"});
    $dumpvars(0, tb_float_encoder);                        
    bits = 64'h405ee00000000000; #10;
  end

endmodule: tb_float_encoder
`endif
