`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2026 17:23:13
// Design Name: 
// Module Name: sub_bytes
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


module sub_bytes(
    input [127:0] data_in,
    output [127:0] data_out
    );
    
    genvar i;
    generate
        for(i=0;i<16;i=i+1) begin : sbox_loop
            sbox SBOX(.data_in(data_in[(8*i)+7:(8*i)]),.subByte(data_out[(8*i)+7:(8*i)]));
        end
    endgenerate
        
endmodule
