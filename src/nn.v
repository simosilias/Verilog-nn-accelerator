module nn(
    output reg [2:0] ovf_fsm_stage, zero_fsm_stage,
    output reg signed [31:0] final_output,
    output wire total_ovf, total_zero,
    input wire clk, resetn, enable, 
    input wire signed [31:0] input_1, input_2
);

reg [2:0] current_state, next_state;
parameter DEACTIVATED_STATE = 3'b000,
          LOADING_WEIGHTS_AND_BIASES = 3'b001,
          PRE_PROCESSING_LAYER = 3'b010,
          INPUT_LAYER = 3'b011,
          OUTPUT_LAYER = 3'b100,
          POST_PROCESSING_LAYER = 3'b101,
          IDLE_STATE = 3'b110;

//Arithmetic shift op codes for the alu's used in the pre and post processing layers
parameter[3:0] ALUOP_ASHIFTR = 4'b0010,
               ALUOP_ASHIFTL = 4'b0011;  

//Rom
reg [7:0] addr1, addr2;
wire signed [31:0] dout1, dout2;         
WEIGHT_BIAS_MEMORY rom (.addr1(addr1), .addr2(addr2), .clk(clk), .dout1(dout1), .dout2(dout2));

//ALUs and mac_unit's
wire alu1_zero, alu1_ovf, alu2_zero, alu2_ovf, mac_unit1_ovf_mul, mac_unit1_ovf_add, mac_unit1_zero_mul, mac_unit1_zero_add, mac_unit2_ovf_mul, mac_unit2_ovf_add,  mac_unit2_zero_mul, mac_unit2_zero_add;
wire signed [31:0] alu1_result, alu2_result, mac_unit1_result, mac_unit2_result;
reg signed [31:0] alu1_op1, alu1_op2, alu2_op1, alu2_op2, mac_unit1_op1, mac_unit1_op2, mac_unit1_op3, mac_unit2_op1, mac_unit2_op2, mac_unit2_op3;
reg [3:0] alu1_op, alu2_op;

alu alu1(.result(alu1_result), .zero(alu1_zero), .alu_op(alu1_op), .op1(alu1_op1), .op2(alu1_op2), .ovf(alu1_ovf));
alu alu2(.result(alu2_result), .zero(alu2_zero), .alu_op(alu2_op), .op1(alu2_op1), .op2(alu2_op2), .ovf(alu2_ovf));

mac_unit mac_unit1(.ovf_add(mac_unit1_ovf_add), .ovf_mul(mac_unit1_ovf_mul), .total_result(mac_unit1_result), .op1(mac_unit1_op1), .op2(mac_unit1_op2), .op3(mac_unit1_op3), .zero_add(mac_unit1_zero_add), .zero_mul(mac_unit1_zero_mul));

mac_unit mac_unit2(.ovf_add(mac_unit2_ovf_add), .ovf_mul(mac_unit2_ovf_mul), .total_result(mac_unit2_result), .op1(mac_unit2_op1), .op2(mac_unit2_op2), .op3(mac_unit2_op3), .zero_add(mac_unit2_zero_add), .zero_mul(mac_unit2_zero_mul));

//network's regfile
reg nn_regfile_resetn;
reg nn_regfile_write;
reg [3:0] nn_regfile_readReg1, nn_regfile_readReg2, nn_regfile_readReg3, nn_regfile_readReg4, nn_regfile_writeReg1,nn_regfile_writeReg2;
reg [31:0] nn_regfile_writeData1, nn_regfile_writeData2;
wire signed [31:0] nn_regfile_readData1,nn_regfile_readData2,nn_regfile_readData3,nn_regfile_readData4;

regfile nn_regfile (.readData1(nn_regfile_readData1), .readData2(nn_regfile_readData2), .readData3(nn_regfile_readData3), .readData4(nn_regfile_readData4), .clk(clk), .resetn(nn_regfile_resetn), .write(nn_regfile_write), .readReg1(nn_regfile_readReg1), .readReg2(nn_regfile_readReg2), .readReg3(nn_regfile_readReg3), .readReg4(nn_regfile_readReg4), .writeData1(nn_regfile_writeData1), .writeData2(nn_regfile_writeData2), .writeReg1(nn_regfile_writeReg1), .writeReg2(nn_regfile_writeReg2));

//intermediate registers
reg signed [31:0] inter1, inter2, inter3, inter4, inter5, inter6;

//Counter and flag for loading weights and biases into regfile
reg [2:0] load_counter;
reg loaded;

//Overflow and zero flags
reg ovf_flag; 
reg zero_flag;


//State memory
always @(posedge clk or negedge resetn)
begin : STATE_MEMORY
    if (!resetn)
        current_state <= DEACTIVATED_STATE;
    else
        current_state <= next_state;
end

//Next State Logic
always @(current_state or enable or ovf_flag or loaded) 
begin : NEXT_STATE_LOGIC
    next_state = current_state;
    case(current_state)
        DEACTIVATED_STATE : if(enable == 1'b1)
                                next_state = LOADING_WEIGHTS_AND_BIASES;
                            else
                                next_state = DEACTIVATED_STATE;
        LOADING_WEIGHTS_AND_BIASES : if(loaded) next_state = PRE_PROCESSING_LAYER;
        PRE_PROCESSING_LAYER : next_state = ovf_flag ? IDLE_STATE : INPUT_LAYER;
        INPUT_LAYER : next_state = ovf_flag ? IDLE_STATE : OUTPUT_LAYER;
        OUTPUT_LAYER : next_state = ovf_flag ? IDLE_STATE : POST_PROCESSING_LAYER;
        POST_PROCESSING_LAYER : next_state = IDLE_STATE;
        IDLE_STATE : if(enable == 1'b1)
                            next_state = PRE_PROCESSING_LAYER;
                    else 
                        next_state = IDLE_STATE;
        default : next_state = DEACTIVATED_STATE;
endcase
end

//Counter implementation
always @(posedge clk or negedge resetn) begin
    if(!resetn)begin
        load_counter <= 0;
        loaded <= 0;
    end
    else if(current_state == LOADING_WEIGHTS_AND_BIASES && !loaded) begin
        load_counter <= load_counter + 1;
        if(load_counter == 6)
            loaded <= 1'b1;
    end
end

//Control logic
always @(*) begin
    //Default values for avoiding latch
    ovf_flag = 1'b0;
    zero_flag = 1'b0;
    nn_regfile_write = 1'b0;
    nn_regfile_resetn = 1'b1;
    alu1_op = 4'b0000; alu2_op = 4'b0000;
    alu1_op1 = 0; alu1_op2 = 0;
    alu2_op1 = 0; alu2_op2 = 0;
    mac_unit1_op1 = 0; mac_unit1_op2 = 0; mac_unit1_op3 = 0;
    mac_unit2_op1 = 0; mac_unit2_op2 = 0; mac_unit2_op3 = 0;
    nn_regfile_readReg1 = 0; nn_regfile_readReg2 = 0;
    nn_regfile_readReg3 = 0; nn_regfile_readReg4 = 0;
    nn_regfile_writeReg1 = 0; nn_regfile_writeReg2 = 0;
    nn_regfile_writeData1 = 0; nn_regfile_writeData2 = 0;
    addr1 = 0; addr2 = 0;
    case(current_state)
        DEACTIVATED_STATE: nn_regfile_resetn = 0;
        LOADING_WEIGHTS_AND_BIASES:
        begin
            nn_regfile_resetn = 1;
            nn_regfile_write = 1'b1;
            case(load_counter)
                0 : begin
                        addr1 = 8'd0;
                        addr2 = 8'd4;
                end
                1 : begin
                        nn_regfile_writeReg1 = 4'h0;
                        nn_regfile_writeReg2 = 4'h1;
                        nn_regfile_writeData1 = dout1;
                        nn_regfile_writeData2 = dout2;
                        addr1 = 8'd8;
                        addr2 = 8'd12;
                end
                2 : begin
                        addr1 = 8'd16;
                        addr2 = 8'd20;
                        nn_regfile_writeReg1 = 4'h2;
                        nn_regfile_writeReg2 = 4'h3;
                        nn_regfile_writeData1 = dout1;
                        nn_regfile_writeData2 = dout2;
                end
                3 : begin
                        addr1 <= 8'd24;
                        addr2 <= 8'd28;
                        nn_regfile_writeReg1 = 4'h4;
                        nn_regfile_writeReg2 = 4'h5;
                        nn_regfile_writeData1 = dout1;
                        nn_regfile_writeData2 = dout2;
                end
                4 : begin
                        addr1 = 8'd32;
                        addr2 = 8'd36;
                        nn_regfile_writeReg1 = 4'h6;
                        nn_regfile_writeReg2 = 4'h7;
                        nn_regfile_writeData1 = dout1;
                        nn_regfile_writeData2 = dout2;
                end
                5 : begin
                        addr1 = 8'd40;
                        addr2 = 8'd44;
                        nn_regfile_writeReg1 = 4'h8;
                        nn_regfile_writeReg2 = 4'h9;
                        nn_regfile_writeData1 = dout1;
                        nn_regfile_writeData2 = dout2;
                end
                6 : begin
                    nn_regfile_writeReg1 = 4'hA;
                    nn_regfile_writeReg2 = 4'hB;
                    nn_regfile_writeData1 = dout1;
                    nn_regfile_writeData2 = dout2;
                end
            endcase
        end
        PRE_PROCESSING_LAYER:
        begin
            nn_regfile_readReg1 = 4'h2; //Shift_bias_1
            nn_regfile_readReg2 = 4'h3; //Shift_bias_2
            alu1_op1 = input_1;
            alu1_op2 = nn_regfile_readData1;
            alu1_op = ALUOP_ASHIFTR;
            alu2_op1 = input_2;
            alu2_op2 = nn_regfile_readData2;
            alu2_op = ALUOP_ASHIFTR;
            ovf_flag = alu1_ovf | alu2_ovf;
            zero_flag = alu1_zero | alu2_zero;
        end
        INPUT_LAYER:
        begin
            nn_regfile_readReg1 = 4'h4; //weight_1
            nn_regfile_readReg2 = 4'h5; //bias_1
            nn_regfile_readReg3 = 4'h6; //weight_2
            nn_regfile_readReg4 = 4'h7; //bias_2
            mac_unit1_op1 = inter1;
            mac_unit1_op2 = nn_regfile_readData1;
            mac_unit1_op3 = nn_regfile_readData2;
            mac_unit2_op1 = inter2;
            mac_unit2_op2 = nn_regfile_readData3;
            mac_unit2_op3 = nn_regfile_readData4;
            ovf_flag = mac_unit1_ovf_add | mac_unit1_ovf_mul | mac_unit2_ovf_add | mac_unit2_ovf_mul;
            zero_flag = mac_unit1_zero_add | mac_unit1_zero_mul | mac_unit2_zero_add | mac_unit2_zero_mul; 
        end
        OUTPUT_LAYER:
        begin
            nn_regfile_readReg1 = 4'h8; //weight_3
            nn_regfile_readReg2 = 4'h9; //weight_4
            nn_regfile_readReg3 = 4'hA; //bias_3
            mac_unit1_op1 = inter3;
            mac_unit1_op2 = nn_regfile_readData1;
            mac_unit1_op3 = nn_regfile_readData3;
            mac_unit2_op1 = inter4;
            mac_unit2_op2 = nn_regfile_readData2;
            mac_unit2_op3 = mac_unit1_result;
            ovf_flag = mac_unit1_ovf_add | mac_unit1_ovf_mul | mac_unit2_ovf_add | mac_unit2_ovf_mul;
            zero_flag = mac_unit1_zero_add | mac_unit1_zero_mul | mac_unit2_zero_add | mac_unit2_zero_mul; 
        end 
        POST_PROCESSING_LAYER:
        begin
            nn_regfile_readReg1 = 4'hB; //Shift_bias_3
            alu1_op1 = inter5;
            alu1_op2 = nn_regfile_readData1;
            alu1_op = ALUOP_ASHIFTL;
            ovf_flag = alu1_ovf;
            zero_flag = alu1_zero;
        end
    endcase
end 

//updating intermediate registers
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        inter1 <= 32'b0; inter2 <= 32'b0; inter3 <= 32'b0; inter4 <= 32'b0; inter5 <= 32'b0; inter6 <= 32'b0;
    end else begin
        case (current_state)
            PRE_PROCESSING_LAYER: begin
                inter1 <= alu1_result;
                inter2 <= alu2_result;
            end
            INPUT_LAYER: begin
                inter3 <= mac_unit1_result;
                inter4 <= mac_unit2_result;
            end
            OUTPUT_LAYER: begin
                inter5 <= mac_unit2_result; //inter_4*weight_4 + mac_unit1_result = inter_4*weight_4 + inter_3*weight_3 + bias_3
            end
            POST_PROCESSING_LAYER: begin
                inter6 <= alu1_result;
            end
        endcase
    end
end

//Output logic 
always @(current_state) begin
    case (current_state) 
        DEACTIVATED_STATE: begin
            final_output = 32'sb0;
        end
        LOADING_WEIGHTS_AND_BIASES: begin
            final_output = 32'sb0;
        end
        PRE_PROCESSING_LAYER: begin
            final_output = 32'sb0;
        end
        INPUT_LAYER: begin
            final_output = 32'sb0;
        end
        OUTPUT_LAYER: begin
            final_output = 32'sb0;
        end
        POST_PROCESSING_LAYER: begin
            final_output = 32'sb0;
        end
        IDLE_STATE: begin
            if(total_ovf)
                final_output = -32'sd1;
            else
                final_output = inter6;
        end
        default: begin
            final_output = 32'sb0;
        end

    endcase
end 

//Overflow and zero control
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        ovf_fsm_stage  <= 3'b111;
        zero_fsm_stage <= 3'b111;
    end
    else if (current_state == IDLE_STATE && enable) begin
        ovf_fsm_stage  <= 3'b111;
        zero_fsm_stage <= 3'b111;
    end
    else begin
        if (ovf_flag == 1'b1 && ovf_fsm_stage == 3'b111)
            ovf_fsm_stage <= current_state;

        if (zero_flag && zero_fsm_stage == 3'b111)
            zero_fsm_stage <= current_state; 
    end
end

assign total_ovf  = (ovf_fsm_stage  != 3'b111);
assign total_zero = (zero_fsm_stage != 3'b111);


endmodule
