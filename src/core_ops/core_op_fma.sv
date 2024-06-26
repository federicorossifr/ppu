/*
make -f Makefile_new.mk TOP=tb_core_op_fma
cd scripts
./validate_fma_fixedpoint.py
*/

module core_op_fma 
  import ppu_pkg::*;
#(
  /// Posit size. needed by `fir_to_fixed`.
  parameter N               = -1,

  parameter TE_BITS         = -1,
  parameter MANT_SIZE       = -1,
  parameter FRAC_FULL_SIZE  = -1,

  parameter FX_M            = `FX_M,
  parameter FX_B            = `FX_B
) (
  input                         clk_i,
  input                         rst_i,
  input operation_e             op_i,
  
  input fir_t                   fir1_i,
  input fir_t                   fir2_i,
  input fir_t                   fir3_i,
  

  output logic                  sign_o,
  output exponent_t             te_o,
  output [(FRAC_FULL_SIZE)-1:0] frac_o,
  
  output                        frac_truncated_o
);


  wire [(MANT_ADD_RESULT_SIZE)-1:0] mant_out_add_sub;
  wire [(MANT_MUL_RESULT_SIZE)-1:0] mant_out_mul;
  wire [(MANT_DIV_RESULT_SIZE)-1:0] mant_out_div;


  logic sign_out_add_sub, sign_out_mul, sign_out_div;
  exponent_t te_out_add_sub, te_out_mul, te_out_div;
  wire frac_truncated_add_sub, frac_truncated_mul, frac_truncated_div;

  
  core_mul #(
    .TE_BITS                (TE_BITS),
    .MANT_SIZE              (MANT_SIZE),
    .MANT_MUL_RESULT_SIZE   (MANT_MUL_RESULT_SIZE)
  ) core_mul_inst (
    .clk_i                  (clk_i),
    .rst_i                  (rst_i),
    .sign1_i                (fir1_i.sign),
    .sign2_i                (fir2_i.sign),
    .te1_i                  (fir1_i.total_exponent),
    .te2_i                  (fir2_i.total_exponent),
    .mant1_i                (fir1_i.mant),
    .mant2_i                (fir2_i.mant),
    .sign_o                 (sign_out_mul),
    .te_o                   (te_out_mul),
    .mant_o                 (mant_out_mul),
    .frac_truncated_o       (frac_truncated_mul)        // TODO: frac must eventually not be truncated.
  );


  
  logic [(FX_B)-1:0] fixed;
  
  localparam FIR_TE_SIZE = TE_BITS;
  localparam FIR_FRAC_SIZE = FRAC_FULL_SIZE;
  logic [(1+FIR_TE_SIZE+FIR_FRAC_SIZE)-1:0] fir_fma;
  core_fma_accumulator #(
    .N                      (N),
    .TE_BITS                (TE_BITS),
    .MANT_SIZE              (MANT_SIZE),
    .FRAC_FULL_SIZE         (FRAC_FULL_SIZE),
    .FX_M                   (FX_M),
    .FX_B                   (FX_B),
    .FIR_TE_SIZE            (FIR_TE_SIZE),
    .FIR_FRAC_SIZE          (FIR_FRAC_SIZE)
  ) core_fma_accumulator_inst (
    .clk_i                  (clk_i),
    .rst_i                  (rst_i),
    .op_i                   (op_i),
  
    .fir1_i                 ({sign_out_mul, te_out_mul, mant_out_mul}),
    .fir2_i                 (fir3_i),

    .fir_fma                (fir_fma),
    .fixed_o                (fixed)
    // .frac_truncated_o       ()
  );



  assign {sign_o, te_o, frac_o} = fir_fma;


endmodule: core_op_fma






module tb_core_op_fma #(
  parameter CLK_FREQ = `CLK_FREQ
);

  import ppu_pkg::*;

  parameter WORD = `WORD;
  parameter N = `N;
  parameter ES = `ES;
  parameter FSIZE = `F;

  parameter FX_M = `FX_M;
  parameter FX_B = `FX_B;


  localparam ASCII_SIZE = 300;

  logic                                 clk_i;
  logic                                 rst_i;
  logic                                 in_valid_i;
  logic                   [WORD-1:0]    operand1_i;
  logic                   [WORD-1:0]    operand2_i;
  logic                   [WORD-1:0]    operand3_i;
  ppu_pkg::operation_e                  op_i;
  logic                 [ASCII_SIZE:0]  op_i_ascii;
  wire                  [WORD-1:0]      result_o;
  wire                                  out_valid_o;


  logic [ASCII_SIZE-1:0]  operand1_i_ascii,   // operand1_i
                          operand2_i_ascii,   // operand2_i
                          operand3_i_ascii,   // operand3_i
                          result_o_ascii,     // result_o ascii
                          result_gt_ascii;    // result ground truth ascii


  word_t out_ground_truth;
  logic [N-1:0] pout_hwdiv_expected;
  logic diff_out_ground_truth, diff_pout_hwdiv_exp, pout_off_by_1;
  logic [  N:0] test_no;

  logic [100:0] count_errors;


  clk_gen #(
    .CLK_FREQ     (CLK_FREQ)
  ) clk_gen_i (
    .clk_o        (clk_i)
  );  

  ppu #(
    .WORD         (WORD),
    `ifdef FLOAT_TO_POSIT
      .FSIZE        (FSIZE),
    `endif
    .N            (N),
    .ES           (ES)
  ) ppu_inst (
    .clk_i        (clk_i),
    .rst_i        (rst_i),
    .in_valid_i   (in_valid_i),
    .operand1_i   (operand1_i),
    .operand2_i   (operand2_i),
    .operand3_i   (operand3_i),
    .op_i         (op_i),
    .result_o     (result_o),
    .out_valid_o  (out_valid_o)
  );

  ////// log to file //////
  integer f2;
  initial f2 = $fopen("tb_core_op_fma.log", "w");


  initial begin
    $dumpfile("tb_core_op_fma");
    $dumpvars(0, tb_core_op_fma);
  end

  logic [(FX_B)-1:0] fixed;
  
  
  logic[(48)-1:0]       fir_o;
  // ->
  logic                 fir_sign;
  logic signed [7-1:0]  fir_te;
  logic [40-1:0]        fir_frac;


  initial begin
    #32;
    @(posedge clk_i);

    for (int i=0; i<300; i++) begin

      if (i == 0) begin
        $fwrite(f2, "(%0d, %0d)\n", FX_M, FX_B);
        $display("(%0d, %0d)", FX_M, FX_B);
      end
    
      case (i)
        0:      operand3_i =  {$random}%(1 << 16); // 27136 == 10.0    //$urandom%(1 << 16);
        default operand3_i = 'bX;
      endcase

      /*
      case (i)
        0:        force ppu_inst.ppu_core_ops_inst.fir_ops_inst.core_op_fma_inst.core_fma_accumulator_inst.start_fma = 1;
        default:  force ppu_inst.ppu_core_ops_inst.fir_ops_inst.core_op_fma_inst.core_fma_accumulator_inst.start_fma = 0;
      endcase
      */
      
      op_i = FMADD;

      /* P<16,1>(16384) === 1.0 , for easy test */
      
      
      
      // operand1_i = 21504; // 21504 == 2.5  //$urandom%(1 << 16);
      // operand2_i = 20480; // 20480 == 2    //$urandom%(1 << 16);

      // operand1_i = 18063; // 18063 == 1.41  
      // operand2_i = 25754; // 25754 == 6.3   

      
      // operand1_i = $urandom%(1 << 16) & 16'b01111111_11111111; // only positive
      // operand2_i = $urandom%(1 << 16) & 16'b01111111_11111111; // only positive
    
      
      operand1_i = $urandom;
      operand2_i = {$random}%(1 << 16);

      #1;
      fixed = ppu_inst.ppu_core_ops_inst.fir_ops_inst.core_op_inst.core_fma_accumulator_inst.accumulator_inst.fixed_o;

    
      fir_sign = ppu_inst.ppu_core_ops_inst.fir_ops_inst.core_op_inst.core_fma_accumulator_inst.fixed_to_fir_acc.fir_sign;
      fir_te = ppu_inst.ppu_core_ops_inst.fir_ops_inst.core_op_inst.core_fma_accumulator_inst.fixed_to_fir_acc.fir_te;
      fir_frac = ppu_inst.ppu_core_ops_inst.fir_ops_inst.core_op_inst.core_fma_accumulator_inst.fixed_to_fir_acc.fir_frac;


      if (i == 0) $display("0x%x", ppu_inst.p3);
      $display("(0x%h, 0x%h) 0x%h, 0x%h", ppu_inst.p1, ppu_inst.p2, fixed, result_o);

      $display("fir = [0x%h, 0x%h, 0x%h]", fir_sign, fir_te, fir_frac);

      if (i == 0) $fwrite(f2, "0x%x\n", ppu_inst.p3);
      $fwrite(f2, "(0x%h, 0x%h) 0x%h, 0x%h\n", ppu_inst.p1, ppu_inst.p2, fixed, result_o);

      @(posedge clk_i);
    end

    for (int i=0; i<20; i++) begin
      op_i = MUL;
      
      
      @(posedge clk_i);
    end

    #100;
    $finish;
  end

  
endmodule: tb_core_op_fma
