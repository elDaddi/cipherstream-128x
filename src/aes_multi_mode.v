`timescale 1ns / 1ps

module aes_multi_mode(
    input  wire clk,
    input  wire reset,
    input  wire enable,
    input  wire mode, // 0 = ECB Mode, 1 = CTR Mode
    input  wire [127:0] data_in, // Plaintext
    input  wire [127:0] key_in,
    input  wire [127:0] iv, // Initial Vector (for CTR mode)
    output wire [127:0] ciphertext
);

    // ctr mode counter
    reg [127:0] counter;
    always @(posedge clk) begin
        if (!reset) 
            counter <= iv;
        else if (enable && mode == 1'b1) 
            counter <= counter + 1'b1; // Only count if in CTR mode
    end

    // Mode=0 (ECB), send data_In to the core. mode=1 (CTR), send the counter to the core.
    wire [127:0] core_input;
    assign core_input = (mode==1'b1)?counter:data_in;

    wire [127:0] aes_out;
    aes_core AES_ENGINE (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .data_in(core_input), 
        .key_in(key_in),
        .data_out(aes_out)
    );

    // 11 cycle delay for ctr
    reg [127:0] pt_pipe [0:10]; 
    integer i;
    always @(posedge clk) begin
        if (!reset) begin
            for (i=0; i<11; i=i+1) pt_pipe[i] <= 128'h0;
        end else if (enable) begin
            pt_pipe[0] <= data_in;
            for (i=1; i<11; i=i+1) pt_pipe[i] <= pt_pipe[i-1];
        end
    end

    // mode=0 (ECB), the ciphertext is just the direct AES output. mode=1 (CTR), the ciphertext is the AES output XOR'd with the delayed plaintext.
    assign ciphertext = (mode==1'b1)?(aes_out^pt_pipe[10]):aes_out;

endmodule