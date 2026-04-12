module calc(
       output wire signed [15:0] led,
       input [15:0] sw,
       input clc, btnc, btnac, btnl, btnr, btnd
);

wire signed [31:0] op2 = {{16{sw[15]}}, sw[15:0]};

//accumulator
reg signed [15:0] accumulator;

wire alu_zero, alu_ovf;
wire signed [31:0] alu_result;

//Finding alu_op
wire [3:0] alu_op;
calc_enc alu_op_finder(.alu_op(alu_op), .btnl(btnl), .btnr(btnr), .btnd(btnd));

//Instantiate alu
alu alu_unit (.op1({{16{accumulator[15]}}, accumulator[15:0]}), .op2(op2), .result(alu_result), .alu_op(alu_op), .zero(alu_zero), .ovf(alu_ovf));

always @(posedge clc)
begin
       if(btnac) begin
              accumulator <= 32'd0;
       end
       else begin
              if(btnc) begin
                     accumulator <= alu_result[15:0]; 
              end
       end
end

assign led = accumulator;

endmodule