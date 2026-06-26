`timescale 1ns / 1ps

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
