`timescale 1ns / 1ps

module aes_core(
    input clk, reset, enable, pt_valid,
    input [127:0] data_in, key_in,
    output ct_valid,
    output [127:0] data_out
    );
    
    wire [127:0] pipe_data[0:10], pipe_key[0:10]; //holds data btwn pipeline registers
    
    //RC lookup fn
    function [7:0] get_RC;
        input [3:0] round_num;
        begin
            case(round_num)
                4'd1:  get_RC = 8'h01;
                4'd2:  get_RC = 8'h02;
                4'd3:  get_RC = 8'h04;
                4'd4:  get_RC = 8'h08;
                4'd5:  get_RC = 8'h10;
                4'd6:  get_RC = 8'h20;
                4'd7:  get_RC = 8'h40;
                4'd8:  get_RC = 8'h80;
                4'd9:  get_RC = 8'h1B;
                4'd10: get_RC = 8'h36;
                default: get_RC = 8'h00;
            endcase
            
       end
       endfunction
       
       // round 0
       wire [127:0] round0_out;
       round_0 ROUND_0(.data_in(data_in),.round_key(key_in),.data_out(round0_out));
       
       pipeline_reg reg0_DATA(.clk(clk),.reset(reset),.enable(enable),.d_in(round0_out),.q_out(pipe_data[1]));
       pipeline_reg reg0_KEY(.clk(clk),.reset(reset),.enable(enable),.d_in(key_in),.q_out(pipe_key[1]));
        
        // round 1-9
        genvar i;
        generate
            for(i=1;i<=9;i=i+1) begin : aes_stages
                wire [127:0] r_data_out, r_key_out;
                //on the fly key expansion
                key_expand KEY_EXPAND_i(.key_in(pipe_key[i]),.RC(get_RC(i[3:0])),.key_out(r_key_out));
                round_1_to_9 ROUND_i(.data_in(pipe_data[i]),.round_key(r_key_out),.data_out(r_data_out));
                
                
                pipeline_reg regi_DATA(.clk(clk),.reset(reset),.enable(enable),.d_in(r_data_out),.q_out(pipe_data[i+1]));
                pipeline_reg regi_KEY(.clk(clk),.reset(reset),.enable(enable),.d_in(r_key_out),.q_out(pipe_key[i+1]));
 
             end
        endgenerate
        
        // round 10      
        wire [127:0] round10_key_out, round10_data_out;
        key_expand KEY_EXPAND_10(.key_in(pipe_key[10]),.RC(get_RC(4'd10)),.key_out(round10_key_out));
        round_10 ROUND_10(.data_in(pipe_data[10]),.round_key(round10_key_out),.data_out(round10_data_out));
        
        pipeline_reg reg10_DATA(.clk(clk),.reset(reset),.enable(enable),.d_in(round10_data_out),.q_out(data_out));
        
       
    reg [10:0] valid_pipe; 

    always @(posedge clk) begin
        if (reset) begin 
            valid_pipe <= 11'b0;
        end else begin
            valid_pipe <= {valid_pipe[9:0], pt_valid}; 
        end
    end

    assign ct_valid = valid_pipe[10]; // The ciphertext is valid exactly when the token pops out the end
endmodule
