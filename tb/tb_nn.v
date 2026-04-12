`timescale 1ns/1ps
`include "nn_model.v"

module tb_nn;

reg clk, resetn, enable;    
reg signed [31:0] input_1, input_2;
wire total_ovf, total_zero;
wire [2:0] ovf_fsm_stage, zero_fsm_stage;
wire signed [31:0] final_output;
reg signed [31:0] expected_output;

//Instantiate
nn DUT (.clk(clk), .resetn(resetn), .enable(enable), .input_1(input_1), .input_2(input_2), .total_ovf(total_ovf), .total_zero(total_zero), .ovf_fsm_stage(ovf_fsm_stage), .zero_fsm_stage(zero_fsm_stage), .final_output(final_output));

integer i, PASS_cases = 0, total_cases = 0;
parameter signed [31:0] max_positive_number = 32'sh7FFFFFFF;
parameter signed [31:0] max_negative_number = 32'sh80000000;

//Clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

task nn_test_case(
    input signed [31:0] test_input_1,test_input_2);
    begin
        input_1 = test_input_1;
        input_2 = test_input_2;
        #10;
        enable = 1;  

        #10;
        enable = 0;

        #129
        expected_output = nn_model(input_1, input_2);
        if(final_output == expected_output) begin
            #1 PASS_cases = PASS_cases + 1;
            total_cases = total_cases + 1;
        end
        else begin
            #1 $display("FAIL at time %tps\n input_1: %d\n input_2: %d\n final_output: %d\n expected_output: %d\n\n", $time,input_1, input_2, final_output, expected_output); 
        end
    end
endtask

//Stimulus  
initial begin
    $dumpfile("tb_nn.vcd");
    $dumpvars(0,tb_nn);
    $display("Starting Simulation");
    resetn = 1'b1;
    enable = 1'b0;
    input_1 = 1'b0;
    input_2 = 1'b0;
    expected_output = 32'sd0;
    #10
    resetn = 0;
    enable = 0;
    #12;
    resetn = 1;
    for(i=0; i<100; i = i+1) begin
        //Test case 1
        nn_test_case($signed($urandom_range(8192)) - 4096, $signed($urandom_range(8192)) - 4096);

        //Test case 2 (Positive overflow check)
        nn_test_case($urandom_range(max_positive_number, max_positive_number / 2), $urandom_range(max_positive_number, max_positive_number / 2));


        //Test case 3 (Negative overflow check)
        nn_test_case($urandom_range(32'hC0000000, max_negative_number), $urandom_range(32'hC0000000, max_negative_number));
        
    end

    $display("Number of PASS/Total Cases: %d/%d", PASS_cases, total_cases);
    $display("Simulation Ended");
    $stop;
end
endmodule
