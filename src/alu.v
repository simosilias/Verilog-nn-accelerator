module alu (
    output reg zero, ovf, 
    output reg signed [31:0] result,
    input wire signed [31:0] op1,op2, 
    input wire [3:0] alu_op
    );

    parameter[3:0] ALUOP_AND = 4'b1000;
    parameter[3:0] ALUOP_OR = 4'b1001; 
    parameter[3:0] ALUOP_NOR = 4'b1010;  
    parameter[3:0] ALUOP_NAND = 4'b1011; 
    parameter[3:0] ALUOP_XOR = 4'b1100; 
    parameter[3:0] ALUOP_ADD = 4'b0100; 
    parameter[3:0] ALUOP_SUB = 4'b0101; 
    parameter[3:0] ALUOP_MUL = 4'b0110; 
    parameter[3:0] ALUOP_LSHIFTR = 4'b0000; 
    parameter[3:0] ALUOP_LSHIFTL = 4'b0001; 
    parameter[3:0] ALUOP_ASHIFTR = 4'b0010; 
    parameter[3:0] ALUOP_ASHIFTL = 4'b0011;  

    // temporary full-width product for overflow detection
    reg signed [63:0] fullprod;

    always @(*) 
    begin
        result = 32'd0;
        ovf = 1'd0;
        zero = 1'd0;
        fullprod = 64'd0;
        case (alu_op)
        ALUOP_ADD: 
        begin
            result = op1 + op2;
            ovf = (~(op1[31] ^ op2[31])) & (result[31] ^ op1[31]);
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        ALUOP_SUB: 
        begin
            result = op1 - op2;
            ovf = ((op1[31] ^ op2[31])) & (result[31] ^ op1[31]);
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end     
        ALUOP_MUL: 
        begin
            fullprod = $signed(op1) * $signed(op2);
            result = fullprod[31:0];
            // overflow detection
            ovf = (fullprod[63:32] != {32{fullprod[31]}});
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        ALUOP_AND:
        begin
            result = op1 & op2;
            ovf = 1'b0;
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        ALUOP_OR:
        begin
            result = op1 | op2;
            ovf = 1'b0;
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        ALUOP_NOR:
        begin
            result = ~(op1 | op2);
            ovf = 1'b0;
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        ALUOP_NAND:
        begin
            result = ~(op1 & op2);
            ovf = 1'b0;
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        ALUOP_XOR:
        begin
            result = op1 ^ op2;
            ovf = 1'b0;
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        ALUOP_LSHIFTR:
        begin
            result = op1 >> op2;
            ovf = 1'b0;
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        ALUOP_LSHIFTL:
        begin
            result = op1 << op2;
            ovf = 1'b0;
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        ALUOP_ASHIFTR:
        begin
            result = $signed(op1) >>> op2;
            ovf = 1'b0;
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        ALUOP_ASHIFTL:
        begin
            result = $signed(op1) <<< op2;
            ovf = 1'b0;
            zero = (result == 32'd0) ? 1'b1 : 1'b0;
        end
        default:
        begin  
        result = 32'd0;
        ovf = 1'd0;
        zero = 1'd0;
        end
        endcase


    end
    
endmodule   
