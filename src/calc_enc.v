module calc_enc (
    output wire [3:0] alu_op,
    input wire btnl, btnr, btnd
);

//Making the inverted signals of the buttons    
wire btnl_n,btnr_n,btnd_n;
not U0(btnl_n,btnl);
not U1(btnr_n,btnr);
not U2(btnd_n,btnd);

//aluop[0] internal nets
wire m0,m1,m2;

//aluop[0] 
and U3(m0,btnl_n,btnd);
and U4(m1,btnl,btnr);
and U5(m2,m1,btnd_n);
or U6(alu_op[0],m2,m0);

//aluop[1] internal nets
wire m3;

//aluop[1]
or U7(m3,btnr_n,btnd_n);
and U8(alu_op[1],m3,btnl);

//aluop[2] internal nets
wire m4,m5,m5_n,m6;

//aluop[2]
and(m4,btnr,btnl_n);
xor(m5,btnr,btnd);
not(m5_n,m5);
and(m6,m5_n,btnl);
or(alu_op[2],m6,m4);

//aluop[3] internal nets
wire m7,m8;

//aluop[3]
and(m7,btnl,btnr);
and(m8,btnd,btnl);
or(alu_op[3],m7,m8);

endmodule