module core_sub 
  import ppu_pkg::*;
#(
  parameter TE_BITS = -1,
  parameter MANT_SUB_RESULT_SIZE = -1
) (
  input  [(MANT_SUB_RESULT_SIZE)-1:0] mant,
  input   exponent_t                  te_diff,
  output [(MANT_SUB_RESULT_SIZE)-1:0] new_mant,
  output  exponent_t                  new_te_diff
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
    .NUM_BITS   (MANT_SUB_RESULT_SIZE)
  ) lzc_inst (
    .bits_i     (mant),
    .lzc_o      (leading_zeros),
    .valid_o    (is_valid)
  );

  assign new_te_diff = te_diff - leading_zeros;
  assign new_mant = (mant << leading_zeros);  // & ~(1 << (MANT_SUB_RESULT_SIZE-1));

endmodule
