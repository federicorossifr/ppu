module core_div
  import ppu_pkg::*;
#(
  parameter TE_BITS = -1,
  parameter MANT_SIZE = -1,
  parameter MANT_DIV_RESULT_SIZE = -1
) (
  input                               clk,
  input                               rst,
  input  [               TE_BITS-1:0] te1,
  input  [               TE_BITS-1:0] te2,
  input  [             MANT_SIZE-1:0] mant1,
  input  [             MANT_SIZE-1:0] mant2,
  output [(MANT_DIV_RESULT_SIZE)-1:0] mant_out,
  output [               TE_BITS-1:0] te_out,
  output                              frac_truncated
);

  logic [MANT_SIZE-1:0] mant1_st0, mant1_st1;
  assign mant1_st0 = mant1;

  logic [TE_BITS-1:0] te_diff_st0, te_diff_st1;
  assign te_diff_st0 = te1 - te2;

  wire [(MANT_DIV_RESULT_SIZE)-1:0] mant_div;

  //// assign mant_div = (mant1 << (2 * size - 1)) / mant2;


  wire [(3*MANT_SIZE-4)-1:0] mant2_reciprocal;


`ifdef DIV_WITH_LUT

  initial $display("***** Using DIV with LUT *****");

  parameter LUT_WIDTH_IN = `LUT_SIZE_IN;
  parameter LUT_WIDTH_OUT = `LUT_SIZE_OUT;

  //// python scripts/pacogen_mant_recip_LUT_gen.py -i 14 -o 39 > src/reciprocate_lut.sv
  generate
    wire [(LUT_WIDTH_OUT)-1:0] _mant_out;

    if (MANT_SIZE < LUT_WIDTH_IN) begin

      wire [(LUT_WIDTH_IN)-1:0] addr;
      assign addr = {mant2[MANT_SIZE-2:0], {1'b0}, {LUT_WIDTH_IN - MANT_SIZE{1'b0}}};
      //                                      ^- one more zero due to lack to unit digit in mant2

      wire mant_is_one;
      assign mant_is_one = addr == 0;

      // e.g P8 mant_size = 6, lut_width_in = 8
      lut_reciprocate #(
          .LUT_WIDTH_IN   (LUT_WIDTH_IN),
          .LUT_WIDTH_OUT  (LUT_WIDTH_OUT)
      ) lut_inst (
          .addr_i         (addr),
          .out_o          (_mant_out)
      );


      //// if mant is one we fall under a special case since the reciprocate of 1 is 1
      //// and it cannot be represented by only fractional bits (which is the interpretation of
      //// the number spat out by the lut).
      assign mant2_reciprocal =
          mant_is_one
          ? { 1'b1, {3*MANT_SIZE-4 - 1{1'b0}} } : {_mant_out, {3*MANT_SIZE-4 - LUT_WIDTH_OUT{1'b0}}} >> 1;

    end else begin
      // e.g. P16 upwards
      wire [(LUT_WIDTH_IN)-1:0] addr;
      assign addr = mant2[MANT_SIZE-2-:LUT_WIDTH_IN];

      wire mant_is_one;
      assign mant_is_one = addr == 0;

      lut_reciprocate #(
        .LUT_WIDTH_IN   (LUT_WIDTH_IN),
        .LUT_WIDTH_OUT  (LUT_WIDTH_OUT)
      ) lut_reciprocate_inst (
        .addr_i         (addr),
        .out_o          (_mant_out)
      );

      assign mant2_reciprocal =
        mant_is_one ? { 1'b1, {3*MANT_SIZE-4 - 1{1'b0}} } : {_mant_out, {3*MANT_SIZE-4 - LUT_WIDTH_OUT{1'b0}}} >> 1'b1;
    end
  endgenerate

  // wire [(3*MANT_SIZE-4)-1:0] mant2_reciprocal_fast_reciprocal;
  // fast_reciprocal #(
  //     .SIZE(MANT_SIZE)
  // ) fast_reciprocal_inst_dummy (
  //     .fraction(mant2),
  //     .one_over_fraction(mant2_reciprocal_fast_reciprocal)
  // );

`else
  initial $display("***** NOT using DIV with LUT *****");

  fast_reciprocal #(
    .SIZE               (MANT_SIZE)
  ) fast_reciprocal_inst (
    .fraction           (mant2),
    .one_over_fraction  (mant2_reciprocal)
  );
`endif

  wire [(2*MANT_SIZE)-1:0] x1;

`define NEWTON_RAPHSON
`ifdef NEWTON_RAPHSON
  initial $display("***** Using NR *****");
  
  newton_raphson #(
    .NR_SIZE (N)
  ) newton_raphson_inst (
    .clk_i  (clk),
    .rst_i  (rst),
    .num_i  (mant2),
    .x0_i   (mant2_reciprocal),
    .x1_o   (x1)
  );
`else
  initial $display("***** NOT using NR *****");
  assign x1 = mant2_reciprocal >> ((3 * MANT_SIZE - 4) - (2 * MANT_SIZE));
`endif

  assign mant_div = mant1_st1 * x1;


  wire mant_div_less_than_one;
  assign mant_div_less_than_one = (mant_div & (1 << (3 * MANT_SIZE - 2))) == 0;

  assign mant_out = mant_div_less_than_one ? mant_div << 1 : mant_div;
  assign te_out = mant_div_less_than_one ? te_diff_st1 - 1 : te_diff_st1;

  assign frac_truncated = 1'b0;


`ifdef PIPELINE_STAGE
  always_ff @(posedge clk) begin
    if (rst) begin
      te_diff_st1 <= 0;
      mant1_st1   <= 0;
    end else begin
      te_diff_st1 <= te_diff_st0;
      mant1_st1   <= mant1_st0;
    end
  end
`else
  assign te_diff_st1 = te_diff_st0;
  assign mant1_st1   = mant1_st0;
`endif

endmodule: core_div
