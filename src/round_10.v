`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2026 19:01:05
// Design Name: 
// Module Name: round_10
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


module round_10(
    input [127:0] data_in, round_key,
    output [127:0] data_out
    );
    
    wire [127:0] sub_out,shift_out;
    
    sub_bytes SUB_BYTES(.data_in(data_in),.data_out(sub_out));
    shift_rows SHIFT_ROWS(.data_in(sub_out),.data_out(shift_out));
    add_round_key ADD_ROUND_KEY(.data_in(shift_out),.round_key(round_key),.data_out(data_out));
    
endmodule
