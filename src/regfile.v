module regfile
        #(parameter DATAWIDTH = 32)
        (output reg [DATAWIDTH-1:0] readData1, [DATAWIDTH-1:0] readData2, [DATAWIDTH-1:0] readData3, [DATAWIDTH-1:0] readData4,
        input clk, resetn, write, [3:0] readReg1, [3:0] readReg2, [3:0] readReg3, [3:0] readReg4, [3:0] writeReg1, [3:0] writeReg2, [DATAWIDTH-1:0] writeData1, [DATAWIDTH-1:0] writeData2);


reg [DATAWIDTH-1:0] registers [15:0];
integer i;

always @(posedge clk, negedge resetn) 
begin
    //Reset registers to 0 when resetn goes 1->0
    if (!resetn) begin
        for(i=0; i<16; i=i+1)
        begin
            registers[i] <= 0;
        end
    end
    else if(write)
    begin
        registers[writeReg1] <= writeData1;
        registers[writeReg2] <= writeData2;
    end
end

always@(*) begin
    if(readReg1 == writeReg1 && write == 1) begin
        readData1 = writeData1;
    end else if(readReg1 == writeReg2 && write == 1) begin
        readData1 = writeData2;
    end else begin
        readData1 = registers[readReg1];
    end

    if(readReg2 == writeReg1 && write == 1) begin
        readData2 = writeData1;
    end else if(readReg2 == writeReg2 && write == 1) begin
        readData2 = writeData2;
    end else begin
        readData2 = registers[readReg2];
    end

    if(readReg3 == writeReg1 && write == 1) begin
        readData3 = writeData1;
    end else if(readReg3 == writeReg2 && write == 1) begin
        readData3 = writeData2;
    end else begin
        readData3 = registers[readReg3];
    end

    if(readReg4 == writeReg1 && write == 1) begin
        readData4 = writeData1;
    end else if(readReg1 == writeReg2 && write == 1) begin
        readData4 = writeData2;
    end else begin
        readData4 = registers[readReg4];
    end

end



endmodule
