`timescale 1ns / 1ps

module round_10(
    input [127:0] data_in, round_key,
    output [127:0] data_out
    );
    
    wire [127:0] sub_out,shift_out;
    
    sub_bytes SUB_BYTES(.data_in(data_in),.data_out(sub_out));
    shift_rows SHIFT_ROWS(.data_in(sub_out),.data_out(shift_out));
    add_round_key ADD_ROUND_KEY(.data_in(shift_out),.round_key(round_key),.data_out(data_out));
    
endmodule
