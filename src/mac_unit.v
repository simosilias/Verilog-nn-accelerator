module mac_unit (
    output wire zero_mul, zero_add, ovf_mul, ovf_add,
    output wire signed [31:0] total_result,
    input wire signed [31:0] op1, op2, op3
);

parameter[3:0] ALUOP_ADD = 4'b0100; 
parameter[3:0] ALUOP_MUL = 4'b0110;
wire signed [31:0] intermiate_result;


alu U1 (.alu_op(ALUOP_MUL), .op1(op1), .op2(op2), .zero(zero_mul), .ovf(ovf_mul), .result(intermiate_result));

alu U2 (.alu_op(ALUOP_ADD), .op1(intermiate_result), .op2(op3), .zero(zero_add), .ovf(ovf_add), .result(total_result));

endmodule