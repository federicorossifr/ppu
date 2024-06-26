module core_div
  import ppu_pkg::*;
#(
  parameter TE_BITS = -1,
  parameter MANT_SIZE = -1,
  parameter MANT_DIV_RESULT_SIZE = -1
) (
  input                               clk_i,
  input                               rst_i,
  input logic                         sign1_i,
  input logic                         sign2_i,
  input  exponent_t                   te1_i,
  input  exponent_t                   te2_i,
  input  [             MANT_SIZE-1:0] mant1_i,
  input  [             MANT_SIZE-1:0] mant2_i,
  
  output logic                        sign_o,
  output exponent_t                   te_o,
  output [(MANT_DIV_RESULT_SIZE)-1:0] mant_o,
  
  output                              frac_truncated_o
);

  logic [MANT_SIZE-1:0] mant1_st0, mant1_st1;
  assign mant1_st0 = mant1_i;

  exponent_t te_diff_st0, te_diff_st1;
  assign te_diff_st0 = te1_i - te2_i;
  assign sign_o = sign1_i ^ sign2_i;

  wire [(MANT_DIV_RESULT_SIZE)-1:0] mant_div;

`ifdef EXACT_DIV

	assign mant_div = ((mant1_i << ((2 * MANT_SIZE) - 1)) / mant2_i) << (MANT_SIZE-1);
 
`else

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
      assign addr = {mant2_i[MANT_SIZE-2:0], {1'b0}, {LUT_WIDTH_IN - MANT_SIZE{1'b0}}};
      //                                      ^- one more zero due to lack to unit digit in mant2_i

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
      assign addr = mant2_i[MANT_SIZE-2-:LUT_WIDTH_IN];

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

`else
  initial $display("***** Using DIV with Fast reciprocate algorithm, no LUT *****");

  fast_reciprocal #(
    .SIZE               (MANT_SIZE)
  ) fast_reciprocal_inst (
    .fraction           (mant2_i),
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
    .clk_i  (clk_i),
    .rst_i  (rst_i),
    .num_i  (mant2_i),
    .x0_i   (mant2_reciprocal),
    .x1_o   (x1)
  );
`else
  initial $display("***** NOT using NR *****");
  assign x1 = mant2_reciprocal >> ((3 * MANT_SIZE - 4) - (2 * MANT_SIZE));
`endif

  assign mant_div = mant1_st1 * x1;
`endif

  wire mant_div_less_than_one;
  assign mant_div_less_than_one = (mant_div & (1 << (3 * MANT_SIZE - 2))) == 0;

  assign mant_o = mant_div_less_than_one ? mant_div << 1 : mant_div;
  assign te_o = mant_div_less_than_one ? te_diff_st1 - 1 : te_diff_st1;

  assign frac_truncated_o = 1'b0;


`ifdef PIPELINE_STAGE
  always_ff @(posedge clk_i) begin
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
