`timescale 1ns / 1ps

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
