/*

iverilog -DTB_NEWTON_RAPHSON -g2012 -o newton_raphson.out ../src/newton_raphson.sv && ./newton_raphson.out

*/
module newton_raphson #(
        parameter SIZE = 10
    )(
        input [(SIZE-2)-1:0] num,
        input [(3*SIZE-4)-1:0] x0,
        output [(2*SIZE)-1:0] x1
    );


    wire [(2*SIZE)-1:0] num_times_x0;
    assign num_times_x0 = (num * x0) >> (2*SIZE - 6);


    /// generated with `scripts/gen_fixed_point_values.py`
    wire [(2*SIZE)-1:0] fp_2 = fp_2___N`N; // 4N

    wire [(2*SIZE)-1:0] two_minus_num_x0;
    assign two_minus_num_x0 = fp_2 - num_times_x0;

    
    wire [(2*SIZE)-1:0] x0_on_2n_bits;
    assign x0_on_2n_bits = x0 >> 4;

    wire [(4*SIZE)-1:0] _x1;
    assign _x1 = x0_on_2n_bits * two_minus_num_x0;

    wire [(2*SIZE)-1:0] x1;
    assign x1 = _x1[(4*SIZE-1)-:SIZE];

endmodule


`ifdef TB_NEWTON_RAPHSON

module tb_newton_raphson;

    parameter SIZE = 16;
    reg [SIZE-1:0] num;
    reg [(3*SIZE)-1:0] x0;
    wire [(2*SIZE)-1:0] x1;

    newton_raphson #(
        .SIZE(SIZE)
    ) newton_raphson_inst (
        .num(num),
        .x0(x0),
        .x1(x1)
    );

    initial begin
        $dumpfile("tb_newton_raphson.vcd");
        $dumpvars(0, tb_newton_raphson);
    end

    
    initial begin

              num = 47104;
              x0 = 11364;

    #10;
    end


endmodule
`endif
