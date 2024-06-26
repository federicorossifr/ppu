/// Contains all the parameters and functions used in the core

/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSEDPARAM */
/* verilator lint_off VARHIDDEN */
package ppu_pkg;

`ifdef N
/// Posit size 
parameter N = `N;
`endif

`ifdef ES
/// Posit exponent width
parameter ES = `ES;
`endif



localparam OP_BITS = $clog2(7);
typedef enum logic [OP_BITS-1:0] {
  ADD,
  SUB,
  MUL,
  DIV,
  FMADD_S, // FMADD start: accumulator is initialized
  FMADD_C, // FMADD continue: accumulator maintains its value
  F2P,
  P2F
} operation_e;


typedef struct packed {
  logic [N-1:0] bits;
} posit_t;

typedef struct packed {
  posit_t posit;
  logic   special_tag;
} posit_special_t;


/// S := ceil(log2(N))
parameter S = $clog2(N);

/// Total exponent bits
parameter TE_BITS = (ES + 1) + (S + 1);

/// Regime length bits
parameter REG_LEN_BITS = S + 1;

/// Mantissa length bits
parameter MANT_LEN_BITS = S + 1;

/// K, no of bits
parameter K_BITS = S + 2; // prev. S + 1 (leads to bug when `te` too large)

parameter FRAC_SIZE = N - 1;

// mant (mantissa) and frac (fraction) are
// not the same thing. mant is a Fx<1,MANT_SIZE>.
// frac is a Fx<0, MANT_SIZE-1>
parameter MANT_SIZE = N - 2;


/////////////////////////////////////////////////////////////////////////////
/// Exponent
typedef logic /*signed*/ [TE_BITS-1:0]  exponent_t;
/// WORD
typedef logic [`WORD-1:0]                word_t;
/////////////////////////////////////////////////////////////////////////////


/// FMA accumulator
typedef logic [`FX_B-1:0] accumulator_t;



// Operation input FIR type.
typedef struct packed {
  logic                 sign;
  exponent_t            total_exponent;
  logic [MANT_SIZE-1:0] mant;
} fir_t;


parameter MS = MANT_SIZE;  // alias

parameter MAX_TE_DIFF = MS;  // not really, but it works anyway.
parameter MTD = MAX_TE_DIFF;  // alias


parameter RECIPROCATE_MANT_SIZE = 2 * MANT_SIZE;
parameter RMS = RECIPROCATE_MANT_SIZE;  // alias

/****************************************/
parameter MANT_MUL_RESULT_SIZE = 2 * MS;
parameter MANT_ADD_RESULT_SIZE = MS + MTD + 1;
parameter MANT_SUB_RESULT_SIZE = MS + MTD;
parameter MANT_DIV_RESULT_SIZE = MS + RMS;
/****************************************/
parameter FRAC_FULL_SIZE = MANT_DIV_RESULT_SIZE - 2; // this is the largest among all the operation, most likely.

/// Fir type (output of `ops` stage. Fraction is unrounded.)
typedef struct packed {
  logic                       sign;
  exponent_t                  total_exponent;
  logic [FRAC_FULL_SIZE-1:0]  frac;
} long_fir_t; // prev. FIR_TOTAL_SIZE

/// Ops (posit operations) output "metadata" type (?)
typedef struct packed {
  long_fir_t  long_fir;
  logic       frac_truncated;
} ops_out_meta_t;

/// Zero
parameter ZERO = {`N{1'b0}};
/// Not A Real
parameter NAR = {1'b1, {`N - 1{1'b0}}};



`define STRINGIFY(DEFINE) $sformatf("%0s", `"DEFINE`")











/*
Fixed point equivalent values of the rational numbers
1.466, 1.0012, 2.0 expressed on a range of different bits.

to visualize what i mean try:

>>> import fixed2float as f2f
>>> a = f2f.Fx(3148211028, 1, 32) # e.g.: fx_1_466___N32
>>> print(a, a.eval())


This file exists because SV doesn't support proper conditional compilation.
*/

// Fixedpoint format of 1.4567844114901045
parameter fx_1_466___N4 = 2'd3; // Fx<1, 2>
parameter fx_1_466___N5 = 3'd6; // Fx<1, 3>
parameter fx_1_466___N6 = 4'd12; // Fx<1, 4>
parameter fx_1_466___N7 = 5'd23; // Fx<1, 5>
parameter fx_1_466___N8 = 6'd47; // Fx<1, 6>
parameter fx_1_466___N9 = 7'd93; // Fx<1, 7>
parameter fx_1_466___N10 = 8'd186; // Fx<1, 8>
parameter fx_1_466___N11 = 9'd373; // Fx<1, 9>
parameter fx_1_466___N12 = 10'd746; // Fx<1, 10>
parameter fx_1_466___N13 = 11'd1492; // Fx<1, 11>
parameter fx_1_466___N14 = 12'd2983; // Fx<1, 12>
parameter fx_1_466___N15 = 13'd5967; // Fx<1, 13>
parameter fx_1_466___N16 = 14'd11934; // Fx<1, 14>
parameter fx_1_466___N17 = 15'd23868; // Fx<1, 15>
parameter fx_1_466___N18 = 16'd47736; // Fx<1, 16>
parameter fx_1_466___N19 = 17'd95472; // Fx<1, 17>
parameter fx_1_466___N20 = 18'd190944; // Fx<1, 18>
parameter fx_1_466___N21 = 19'd381887; // Fx<1, 19>
parameter fx_1_466___N22 = 20'd763775; // Fx<1, 20>
parameter fx_1_466___N23 = 21'd1527549; // Fx<1, 21>
parameter fx_1_466___N24 = 22'd3055098; // Fx<1, 22>
parameter fx_1_466___N25 = 23'd6110197; // Fx<1, 23>
parameter fx_1_466___N26 = 24'd12220393; // Fx<1, 24>
parameter fx_1_466___N27 = 25'd24440787; // Fx<1, 25>
parameter fx_1_466___N28 = 26'd48881573; // Fx<1, 26>
parameter fx_1_466___N29 = 27'd97763147; // Fx<1, 27>
parameter fx_1_466___N30 = 28'd195526294; // Fx<1, 28>
parameter fx_1_466___N31 = 29'd391052588; // Fx<1, 29>
parameter fx_1_466___N32 = 30'd782105176; // Fx<1, 30>

// Fixedpoint format of 1.0009290026616422
parameter fx_1_0012___N4 = 3'd4; // Fx<1, 3>
parameter fx_1_0012___N5 = 5'd16; // Fx<1, 5>
parameter fx_1_0012___N6 = 7'd64; // Fx<1, 7>
parameter fx_1_0012___N7 = 9'd256; // Fx<1, 9>
parameter fx_1_0012___N8 = 11'd1025; // Fx<1, 11>
parameter fx_1_0012___N9 = 13'd4100; // Fx<1, 13>
parameter fx_1_0012___N10 = 15'd16399; // Fx<1, 15>
parameter fx_1_0012___N11 = 17'd65597; // Fx<1, 17>
parameter fx_1_0012___N12 = 19'd262388; // Fx<1, 19>
parameter fx_1_0012___N13 = 21'd1049550; // Fx<1, 21>
parameter fx_1_0012___N14 = 23'd4198201; // Fx<1, 23>
parameter fx_1_0012___N15 = 25'd16792802; // Fx<1, 25>
parameter fx_1_0012___N16 = 27'd67171208; // Fx<1, 27>
parameter fx_1_0012___N17 = 29'd268684833; // Fx<1, 29>
parameter fx_1_0012___N18 = 31'd1074739333; // Fx<1, 31>
parameter fx_1_0012___N19 = 33'd4298957332; // Fx<1, 33>
parameter fx_1_0012___N20 = 35'd17195829328; // Fx<1, 35>
parameter fx_1_0012___N21 = 37'd68783317313; // Fx<1, 37>
parameter fx_1_0012___N22 = 39'd275133269251; // Fx<1, 39>
parameter fx_1_0012___N23 = 41'd1100533077005; // Fx<1, 41>
parameter fx_1_0012___N24 = 43'd4402132308019; // Fx<1, 43>
parameter fx_1_0012___N25 = 45'd17608529232075; // Fx<1, 45>
parameter fx_1_0012___N26 = 47'd70434116928301; // Fx<1, 47>
parameter fx_1_0012___N27 = 49'd281736467713206; // Fx<1, 49>
parameter fx_1_0012___N28 = 51'd1126945870852824; // Fx<1, 51>
parameter fx_1_0012___N29 = 53'd4507783483411295; // Fx<1, 53>
parameter fx_1_0012___N30 = 55'd18031133933645177; // Fx<1, 55>
parameter fx_1_0012___N31 = 57'd72124535734580705; // Fx<1, 57>
parameter fx_1_0012___N32 = 59'd288498142938322817; // Fx<1, 59>

// Fixedpoint format of 2.0
parameter fx_2___N4 = 4'd8; // Fx<2, 4>
parameter fx_2___N5 = 6'd32; // Fx<2, 6>
parameter fx_2___N6 = 8'd128; // Fx<2, 8>
parameter fx_2___N7 = 10'd512; // Fx<2, 10>
parameter fx_2___N8 = 12'd2048; // Fx<2, 12>
parameter fx_2___N9 = 14'd8192; // Fx<2, 14>
parameter fx_2___N10 = 16'd32768; // Fx<2, 16>
parameter fx_2___N11 = 18'd131072; // Fx<2, 18>
parameter fx_2___N12 = 20'd524288; // Fx<2, 20>
parameter fx_2___N13 = 22'd2097152; // Fx<2, 22>
parameter fx_2___N14 = 24'd8388608; // Fx<2, 24>
parameter fx_2___N15 = 26'd33554432; // Fx<2, 26>
parameter fx_2___N16 = 28'd134217728; // Fx<2, 28>
parameter fx_2___N17 = 30'd536870912; // Fx<2, 30>
parameter fx_2___N18 = 32'd2147483648; // Fx<2, 32>
parameter fx_2___N19 = 34'd8589934592; // Fx<2, 34>
parameter fx_2___N20 = 36'd34359738368; // Fx<2, 36>
parameter fx_2___N21 = 38'd137438953472; // Fx<2, 38>
parameter fx_2___N22 = 40'd549755813888; // Fx<2, 40>
parameter fx_2___N23 = 42'd2199023255552; // Fx<2, 42>
parameter fx_2___N24 = 44'd8796093022208; // Fx<2, 44>
parameter fx_2___N25 = 46'd35184372088832; // Fx<2, 46>
parameter fx_2___N26 = 48'd140737488355328; // Fx<2, 48>
parameter fx_2___N27 = 50'd562949953421312; // Fx<2, 50>
parameter fx_2___N28 = 52'd2251799813685248; // Fx<2, 52>
parameter fx_2___N29 = 54'd9007199254740992; // Fx<2, 54>
parameter fx_2___N30 = 56'd36028797018963968; // Fx<2, 56>
parameter fx_2___N31 = 58'd144115188075855872; // Fx<2, 58>
parameter fx_2___N32 = 60'd576460752303423488; // Fx<2, 60>







/// Two's complement
function [(N)-1:0] c2(input [(N)-1:0] a);
  c2 = ~a + 1'b1;
endfunction

// function automatic c2(a);
//   return unsigned'(-a);
// endfunction





/// Absolute value
function [N-1:0] abs(input [N-1:0] in);
  abs = in[N-1] == 0 ? in : c2(in);
endfunction

/// Returns minimum between two signed values
function [N-1:0] min(input [N-1:0] a, b);
  min = $signed(a) <= $signed(b) ? a : b;
endfunction

/// Returns maximum between two signed values
function [N-1:0] max(input [N-1:0] a, b);
  max = a >= b ? a : b;
endfunction

function is_negative(input [S:0] k);
  is_negative = k[S];
endfunction

function [N-1:0] shl(input [N-1:0] bits, input [N-1:0] rhs);
  shl = rhs[N-1] == 0 ? bits << rhs : bits >> c2(rhs);
endfunction







/// F64
parameter FLOAT_EXP_SIZE_F64 = 11;
parameter FLOAT_MANT_SIZE_F64 = 52;
/// F32
parameter FLOAT_EXP_SIZE_F32 = 8;
parameter FLOAT_MANT_SIZE_F32 = 23;
/// F16
parameter FLOAT_EXP_SIZE_F16 = 5;
parameter FLOAT_MANT_SIZE_F16 = 10;



endpackage: ppu_pkg
/* verilator lint_on DECLFILENAME */
/* verilator lint_on UNUSEDPARAM */
/* verilator lint_on VARHIDDEN */
