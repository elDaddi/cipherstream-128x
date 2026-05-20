`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2026 03:00:09
// Design Name: 
// Module Name: pipeline_reg
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


module pipeline_reg(
    input clk, reset, enable,
    input [127:0] d_in,
    output reg [127:0] q_out
    );
    
    always@(posedge clk)
    begin
        if(reset) q_out<=0;
        else if(enable) q_out<=d_in;
    end
endmodule
