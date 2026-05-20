`timescale 1ns / 1ps

module mix_columns(
    input  wire [127:0] data_in,
    output wire [127:0] data_out
);

    // Function to multiply by 2 and fix the overflow
	function [7:0] xtime;
		input [7:0] in;
		if(in[7] == 1) xtime = (in << 1) ^ 8'h1B;
		else xtime = in << 1;
	endfunction

	genvar i;
	generate
		for(i = 0; i < 4; i = i + 1)begin: mixColumnsLoop
			// state[0,c] = 2*state[0,c] + (2 * state[1,c] + state[1,c]) + state[2,c] + state[3,c]
			assign data_out[32*i+24+:8] =  xtime(data_in[32*i+24+:8]) ^ (xtime(data_in[32*i+16+:8]) ^ data_in[32*i+16+:8]) ^ data_in[32*i+8 +:8] ^ data_in[32*i   +:8];
			
			// state[1,c] = 2*state[1,c] + (2 * state[2,c] + state[2,c]) + state[3,c] + state[0,c]
			assign data_out[32*i+16+:8] =  xtime(data_in[32*i+16+:8]) ^ (xtime(data_in[32*i+8 +:8]) ^ data_in[32*i+8 +:8]) ^ data_in[32*i   +:8] ^ data_in[32*i+24+:8];
			
			// state[2,c] = 2*state[2,c] + (2 * state[3,c] + state[3,c]) + state[0,c] + state[1,c]
			assign data_out[32*i+8 +:8] =  xtime(data_in[32*i+8 +:8]) ^ (xtime(data_in[32*i   +:8]) ^ data_in[32*i   +:8]) ^ data_in[32*i+24+:8] ^ data_in[32*i+16+:8];
			
			// state[3,c] = 2*state[3,c] + (2 * state[0,c] + state[0,c]) + state[1,c] + state[2,c]
			assign data_out[32*i   +:8] =  xtime(data_in[32*i   +:8]) ^ (xtime(data_in[32*i+24+:8]) ^ data_in[32*i+24+:8]) ^ data_in[32*i+16+:8] ^ data_in[32*i+8 +:8];
		end
	endgenerate
endmodule