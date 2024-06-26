module handle_special_or_trivial 
  import ppu_pkg::*;  
#(
  parameter N = -1
) (
  input   operation_e   op_i,
  input   posit_t       p1_i,
  input   posit_t       p2_i,
  input   posit_t       p3_i,
  output  posit_t       pout_o
);

  posit_t p_out_lut_mul, p_out_lut_add, p_out_lut_sub, p_out_lut_div;

  lut_mul #(
    .N          (N)
  ) lut_mul_inst (
    .p1         (p1_i),
    .p2         (p2_i),
    .p_out      (p_out_lut_mul)
  );

  lut_add #(
    .N          (N)
  ) lut_add_inst (
    .p1         (p1_i),
    .p2         (p2_i),
    .p_out      (p_out_lut_add)
  );

  lut_sub #(
    .N          (N)
  ) lut_sub_inst (
    .p1         (p1_i),
    .p2         (p2_i),
    .p_out      (p_out_lut_sub)
  );

  lut_div #(
    .N          (N)
  ) lut_div_inst (
    .p1         (p1_i),
    .p2         (p2_i),
    .p_out      (p_out_lut_div)
  );

  assign pout_o = op_i == MUL
    ? p_out_lut_mul : op_i == ADD
    ? p_out_lut_add : op_i == SUB
    ? p_out_lut_sub : /* op_i == DIV */
      p_out_lut_div;

endmodule: handle_special_or_trivial


module lut_mul
  import ppu_pkg::*;
#(
  parameter N = -1
) (
  input   posit_t p1,
  input   posit_t p2,
  output  posit_t p_out
);

  wire [(2*N)-1:0] addr;
  assign addr = {p1, p2};

  always_comb begin
    case (p1)
      ZERO:    p_out = p2 == NAR || p2 == ZERO ? p2 : ZERO;
      NAR:     p_out = NAR;
      default: p_out = p2;
    endcase
  end
endmodule: lut_mul

module lut_add
  import ppu_pkg::*;
#(
  parameter N = -1
) (
  input   posit_t p1,
  input   posit_t p2,
  output  posit_t p_out
);

  always_comb begin
    case (p1)
      ZERO:    p_out = p2;
      NAR:     p_out = NAR;
      default: p_out = p2 == c2(p1) ? ZERO : p2 == ZERO ? p1 : NAR;
    endcase
  end
endmodule: lut_add

module lut_sub
  import ppu_pkg::*;
#(
  parameter N = -1
) (
  input   posit_t p1,
  input   posit_t p2,
  output  posit_t p_out
);

  always_comb begin
    case (p1)
      ZERO:    p_out = (p2 == ZERO) || (p2 == NAR) ? p2 : c2(p2);
      NAR:     p_out = NAR;
      default: p_out = p2 == p1 ? ZERO : p2 == ZERO ? p1 : NAR;
    endcase
  end
endmodule: lut_sub

module lut_div
  import ppu_pkg::*;
#(
  parameter N = -1
) (
  input   posit_t p1,
  input   posit_t p2,
  output  posit_t p_out
);

  always_comb begin
    case (p1)
      ZERO:    p_out = (p2 == NAR || p2 == ZERO) ? NAR : ZERO;
      NAR:     p_out = NAR;
      default: p_out = NAR;
    endcase
  end
endmodule: lut_div
