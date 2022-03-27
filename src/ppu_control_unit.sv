module ppu_control_unit (
    input                      clk,
    input                      rst,
    input                      valid_i,
    input        [OP_SIZE-1:0] op,
    output                     valid_o,
    output logic               stall_o,
    output logic               new_div_op_o
);


    reg [(4)-1:0] state_reg, state_next;
    localparam INIT = 0;
    localparam OP = 1;
    localparam DIV_OP = 2;


    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= INIT;
        end else begin
            state_reg <= state_next;
        end
    end


    always @(*) begin
        state_next = state_reg;
        stall_o = 0;
        new_div_op_o = 0;

        case (state_reg)
            INIT: begin
                case (valid_i)
                    0: state_next = INIT;
                    1: begin
                        if (op == DIV) begin
                            state_next   = DIV_OP;
                            new_div_op_o = 1;
                        end else state_next = OP;
                    end
                endcase
            end
            OP: begin
                case (valid_i)
                    0: state_next = INIT;
                    1: begin
                        if (op == DIV) begin
                            state_next   = DIV_OP;
                            new_div_op_o = 1;
                        end else state_next = OP;
                    end
                endcase
            end
            DIV_OP: begin
                case (valid_i)
                    0: state_next = INIT;
                    1: begin
                        if (op == DIV) begin
                            state_next   = DIV_OP;
                            new_div_op_o = 1;
                        end else begin
                            state_next = OP;
                            stall_o = 1;
                        end
                    end
                endcase
            end
            default: begin
            end
        endcase
    end


    logic valid_in_st0, valid_in_st1, valid_in_st2, valid_in_st3, valid_in_st4;
    always_ff @(posedge clk) begin
        if (rst) begin
            valid_in_st0 <= 0;
            valid_in_st1 <= 0;
            valid_in_st2 <= 0;
            valid_in_st3 <= 0;
            // valid_in_st4 <= 0;
        end else begin
            valid_in_st0 <= stall_o ? valid_in_st0 : valid_i;
            valid_in_st1 <= valid_in_st0;
            valid_in_st2 <= valid_in_st1;
            valid_in_st3 <= valid_in_st2;
            valid_in_st4 <= valid_in_st3;
        end
    end

    assign valid_o = op_st4 !== DIV ? valid_in_st3 : valid_in_st4;


    logic [OP_SIZE-1:0] op_st0, op_st1, op_st2, op_st3, op_st4;
    always_ff @(posedge clk) begin
        if (rst) begin
            op_st0 <= 0;
            op_st1 <= 0;
            op_st2 <= 0;
            op_st3 <= 0;
            op_st4 <= 0;
        end else begin
            op_st0 <= op;
            op_st1 <= op_st0;
            op_st2 <= op_st1;
            op_st3 <= op_st2;
            op_st4 <= op_st3;
        end
    end

endmodule


















// module ppu_control_unit (
//     input                      clk,
//     input                      rst,
//     input                      valid_in,
//     input        [OP_SIZE-1:0] op,
//     output logic               stall,
//     output logic               valid_o
// );

//     logic [OP_SIZE-1:0] op_prev;
//     always_ff @(posedge clk) begin
//         if (rst) begin
//             stall   <= 0;
//             op_prev <= 0;
//         end else begin
//             op_prev <= op;
//             if (op_prev !== DIV && op === DIV) begin
//                 stall <= 0;  //stall <= 1;
//             end else begin
//                 stall <= 0;
//             end
//         end
//     end


//     logic valid_in_st0, valid_in_st1, valid_in_st2, valid_in_st3;

//     always_ff @(posedge clk) begin
//         if (rst) begin
//             valid_in_st0 <= 0;
//             valid_in_st1 <= 0;
//             valid_in_st2 <= 0;
//             valid_in_st3 <= 0;
//         end else begin
//             valid_in_st0 <= valid_in;
//             valid_in_st1 <= valid_in_st0;  // stall == 1'b1 ? valid_in_st1 : valid_in_st0;
//             valid_in_st2 <= valid_in_st1;  // stall == 1'b1 ? 1'b0 : valid_in_st1;
//             valid_in_st3 <= valid_in_st2;
//         end
//     end

//     assign valid_o = valid_in_st2;
// endmodule


