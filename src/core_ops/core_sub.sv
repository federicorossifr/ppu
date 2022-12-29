module core_sub 
  import ppu_pkg::*;
#(
  parameter N = 4
) (
  input  [(MANT_SUB_RESULT_SIZE)-1:0] mant,
  input  [               TE_BITS-1:0] te_diff,
  output [(MANT_SUB_RESULT_SIZE)-1:0] new_mant,
  output [               TE_BITS-1:0] new_te_diff
);

  wire [($clog2(MANT_SUB_RESULT_SIZE))-1:0] leading_zeros;

  /*
  cls #(
      .NUM_BITS(MANT_SUB_RESULT_SIZE)
  ) clz_inst (
      .bits               (mant),
      .val                (1'b0),
      .leading_set        (leading_zeros),
      .index_highest_set  ()
  );
  */

  wire is_valid;  // flag we dont care about here.

  lzc #(
    .NUM_BITS(MANT_SUB_RESULT_SIZE)
  ) lzc_inst (
    .in (mant),
    .out(leading_zeros),
    .vld(is_valid)
  );

  assign new_te_diff = te_diff - leading_zeros;
  assign new_mant = (mant << leading_zeros);  // & ~(1 << (MANT_SUB_RESULT_SIZE-1));

endmodule
