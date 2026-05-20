`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2026 03:11:42
// Design Name: 
// Module Name: key_expand
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module key_expand(
    input [127:0] key_in,
    input [7:0] RC,
    output [127:0] key_out
    );
    
    wire [31:0] w0, w1, w2, w3;
    wire [31:0] w4, w5, w6, w7;
    wire [7:0]  sub0, sub1, sub2, sub3;
    wire [31:0] g_w3;
    
    assign {w0, w1, w2, w3} = key_in; //splitting
    
    sbox s0 (.data_in(w3[23:16]), .subByte(sub0));
    sbox s1 (.data_in(w3[15:8]),  .subByte(sub1));
    sbox s2 (.data_in(w3[7:0]),   .subByte(sub2));
    sbox s3 (.data_in(w3[31:24]), .subByte(sub3));
    assign g_w3 = {sub0 ^ RC, sub1, sub2, sub3}; //g function

    assign w4 = w0 ^ g_w3;
    assign w5 = w1 ^ w4;
    assign w6 = w2 ^ w5;
    assign w7 = w3 ^ w6;

    assign key_out = {w4, w5, w6, w7};
    
    
    
    
endmodule
