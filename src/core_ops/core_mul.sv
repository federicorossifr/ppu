module core_mul 
  import ppu_pkg::*;
#(
  parameter TE_BITS = -1,
  parameter MANT_SIZE = -1,
  parameter MANT_MUL_RESULT_SIZE = -1
) (
  input                             clk_i,
  input                             rst_i,
  input logic                       sign1_i,
  input logic                       sign2_i,
  input  exponent_t                 te1_i,
  input  exponent_t                 te2_i,
  input  [           MANT_SIZE-1:0] mant1_i,
  input  [           MANT_SIZE-1:0] mant2_i,
  
  output logic                      sign_o,
  output exponent_t                 te_o,
  output [MANT_MUL_RESULT_SIZE-1:0] mant_o, // full output mantissa (no rounding)

  output                            frac_truncated_o
);

  exponent_t te_sum_st0, te_sum_st1;
  assign te_sum_st0 = te1_i + te2_i;

  wire [MANT_SUB_RESULT_SIZE-1:0] mant_mul;

//`define DUMPSTUFF
`ifdef DUMPSTUFF
  initial begin
    $display("Dump demo");
  end
`endif

  wire mant_carry;
  assign mant_carry = mant_mul[MANT_MUL_RESULT_SIZE-1];

  assign te_o = mant_carry == 1'b1 ? te_sum_st1 + 1'b1 : te_sum_st1;
  assign mant_o = mant_carry == 1'b1 ? mant_mul >> 1 : mant_mul;

  assign frac_truncated_o = mant_carry && (mant_mul & 1);


  assign sign_o = sign1_i ^ sign2_i;

`ifdef PIPELINE_STAGE
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      te_sum_st1 <= 0;
    end else begin
      te_sum_st1 <= te_sum_st0;
    end
  end

  // `define PIPELINED_MUL
  `ifdef PIPELINED_MUL
    pp_mul #(
      .M(MANT_SIZE),
      .N(MANT_SIZE)
    ) pp_mul_inst (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .a(mant1_i),
      .b(mant2_i),
      .product(mant_mul)
    );
  `else
    assign mant_mul = mant1_i * mant2_i;
  `endif
`elsif NO_PIPELINE
  assign te_sum_st1 = te_sum_st0;
  assign mant_mul = mant1_i * mant2_i;
`else
  initial $error("Missing define: `core_mul`");
`endif

endmodule: core_mul
