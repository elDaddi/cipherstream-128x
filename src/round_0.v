`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2026 19:01:05
// Design Name: 
// Module Name: round_0
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


module round_0(
    input [127:0] data_in, round_key,
    output [127:0] data_out
    );
   
    add_round_key ADD_ROUND_KEY(.data_in(data_in),.round_key(round_key),.data_out(data_out));
    
endmodule
