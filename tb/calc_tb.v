`timescale 1ns/1ps

module calc_tb ();
    
    wire [15:0] led;
    reg [15:0] sw;
    reg clc, btnc, btnac, btnl, btnr, btnd;

    //Instantiate
    calc DUT(.led(led), .sw(sw), .clc(clc), .btnc(btnc), .btnl(btnl), .btnac(btnac), .btnr(btnr), .btnd(btnd));

    //Clock
    initial begin
        clc = 1'b0;
    end

    always begin
        #5 clc = ~clc;
    end

    task calc_operation(
      input btnl_val, btnr_val, btnd_val,
      input signed [15:0] sw_val);
      begin
        btnl = btnl_val;
        btnr = btnr_val;
        btnd = btnd_val;
        sw = sw_val;
        #10;
        btnc = 1;
        #10;
        btnc = 0;
        #10;
      end
    endtask

    task check_and_display( 
      input btnl_val, btnr_val, btnd_val,
      input signed [15:0] expected_result);
      begin
        $display("btnl|btnr|btnd = %b|%b|%b", btnl_val, btnr_val, btnd_val);
        if(led != expected_result)
          $display("FAIL - Result: 0x%h, Expected: 0x%h", led, expected_result);
        else
          $display("PASS - Result: 0x%h, Expected: 0x%h", led, expected_result);
      end
    endtask 
        
    //Stimulus 
    initial begin
      $dumpfile("calc_tb.vcd");
      $dumpvars(0,calc_tb);
      btnc = 1'b0;
      btnac = 1'b0;
      btnd = 1'b0;
      btnl = 1'b0;
      btnr = 1'b0;
      btnd = 1'b0;
      sw = 16'b0;

      $display("Starting Simulation");
        
	    #10
      //Reset the calculator
      btnac = 1'b1;
      #9
      btnac = 1'b0;
      #1 $display("btnac = 1 (Reset) : Result: 0x%h, Expected: 0x%h",led,16'h0);

      //ADD Operation
      calc_operation(1'b0,1'b1,1'b0,16'h285a);
      check_and_display(1'b0,1'b1,1'b0,16'h285a);

      //SUB Operation
      calc_operation(1'b1,1'b1,1'b1,16'h04c8);
      check_and_display(1'b1,1'b1,1'b1,16'h2c92);

      //Logical Shift Right Operation
      calc_operation(1'b0,1'b0,1'b0,16'h0005);
      check_and_display(1'b0,1'b0,1'b0,16'h0164);

      //NOR Operation
      calc_operation(1'b1,1'b0,1'b1,16'ha085);
      check_and_display(1'b1,1'b0,1'b1,16'h5e1a);

      //MULT Operation
      calc_operation(1'b1,1'b0,1'b0,16'h07fe);
      check_and_display(1'b1,1'b0,1'b0,16'h13cc);

      //Logical Shift Left Operation
      calc_operation(1'b0,1'b0,1'b1,16'h0004);
      check_and_display(1'b0,1'b0,1'b1,16'h3cc0);

      //NAND Operation
      calc_operation(1'b1,1'b1,1'b0,16'hfa65);
      check_and_display(1'b1,1'b1,1'b0,16'hc7bf);

      //SUB Operation
      calc_operation(1'b0,1'b1,1'b1,16'hb2e4);
      check_and_display(1'b0,1'b1,1'b1,16'h14db);

      #50
      $display("Simulation Ended");  
      $finish;

    end


endmodule