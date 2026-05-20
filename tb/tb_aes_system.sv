`timescale 1ns / 1ps

import axi_vip_pkg::*;
import ichip_ps2_axi_vip_0_0_pkg::*; 

module tb_aes_system();

    // System Signals
    bit clk;
    bit resetn;
    
    // 100MHz Clock Generation
    always #5 clk = ~clk;

    // DUT Instantiation
    ichip_ps2_wrapper UUT (
        .s00_axi_aclk_0(clk),
        .s00_axi_aresetn_0(resetn)
    );

    // AXI VIP Master Agent
    ichip_ps2_axi_vip_0_0_mst_t master_agent;

    // -------------------------------------------------------------------------
    // Task: Single Vector Verification
    // -------------------------------------------------------------------------
    task aes_test_vector(
        input string  test_name,
        input [127:0] plaintext,
        input [127:0] aes_key,
        input [127:0] expected_ct
    );
        xil_axi_resp_t resp;
        bit [31:0] status_reg;
        bit [127:0] actual_ct;
        int timeout;

        $display("[INFO] Starting Test: %s", test_name);
        
        // 1. Load Plaintext
        master_agent.AXI4LITE_WRITE_BURST(32'h4000_0000, 0, plaintext[127:96], resp); 
        master_agent.AXI4LITE_WRITE_BURST(32'h4000_0004, 0, plaintext[95:64],  resp);
        master_agent.AXI4LITE_WRITE_BURST(32'h4000_0008, 0, plaintext[63:32],  resp);
        master_agent.AXI4LITE_WRITE_BURST(32'h4000_000C, 0, plaintext[31:0],   resp);

        // 2. Load Key
        master_agent.AXI4LITE_WRITE_BURST(32'h44A0_0004, 0, aes_key[127:96], resp);
        master_agent.AXI4LITE_WRITE_BURST(32'h44A0_0008, 0, aes_key[95:64],  resp);
        master_agent.AXI4LITE_WRITE_BURST(32'h44A0_000C, 0, aes_key[63:32],  resp);
        master_agent.AXI4LITE_WRITE_BURST(32'h44A0_0010, 0, aes_key[31:0],   resp);

        // 3. Assert Start Pulse
        master_agent.AXI4LITE_WRITE_BURST(32'h44A0_0000, 0, 32'h00000001, resp);
        #20; 
        master_agent.AXI4LITE_WRITE_BURST(32'h44A0_0000, 0, 32'h00000000, resp);

        // 4. Poll Status Register (Wait for DONE bit 2 OR IDLE bit 0)
        status_reg = 0;
        timeout = 0;
        // Check if neither Done (bit 2) nor Idle (bit 0) are high
        while ((status_reg[2] == 1'b0 && status_reg[0] == 1'b0) && (timeout < 500)) begin
            master_agent.AXI4LITE_READ_BURST(32'h44A0_0014, 0, status_reg, resp);
            #10;
            timeout++;
        end

        if (timeout >= 500) begin
            $error("[FAIL] %s - Timeout: AES core stalled.", test_name);
            return;
        end

        // 5. Read Ciphertext
        master_agent.AXI4LITE_READ_BURST(32'h4000_0000, 0, actual_ct[127:96], resp);
        master_agent.AXI4LITE_READ_BURST(32'h4000_0004, 0, actual_ct[95:64],  resp);
        master_agent.AXI4LITE_READ_BURST(32'h4000_0008, 0, actual_ct[63:32],  resp);
        master_agent.AXI4LITE_READ_BURST(32'h4000_000C, 0, actual_ct[31:0],   resp);

        // 6. Verify Results
        if (actual_ct == expected_ct) begin
            $display("[PASS] %s", test_name);
        end else begin
            $error("[FAIL] %s\n  Expected: %h\n  Actual:   %h", test_name, expected_ct, actual_ct);
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: Randomized Stress Test
    // -------------------------------------------------------------------------
    task aes_stress_test(input int iterations);
        xil_axi_resp_t resp;
        bit [31:0] status_reg;
        bit [127:0] rand_pt, rand_key;
        int timeout;

        $display("[INFO] Starting Stress Test (%0d iterations)", iterations);
        
        for (int i = 0; i < iterations; i++) begin
            rand_pt  = {$urandom, $urandom, $urandom, $urandom};
            rand_key = {$urandom, $urandom, $urandom, $urandom};

            master_agent.AXI4LITE_WRITE_BURST(32'h4000_0000, 0, rand_pt[127:96], resp); 
            master_agent.AXI4LITE_WRITE_BURST(32'h4000_0004, 0, rand_pt[95:64],  resp);
            master_agent.AXI4LITE_WRITE_BURST(32'h4000_0008, 0, rand_pt[63:32],  resp);
            master_agent.AXI4LITE_WRITE_BURST(32'h4000_000C, 0, rand_pt[31:0],   resp);

            master_agent.AXI4LITE_WRITE_BURST(32'h44A0_0004, 0, rand_key[127:96], resp);
            master_agent.AXI4LITE_WRITE_BURST(32'h44A0_0008, 0, rand_key[95:64],  resp);
            master_agent.AXI4LITE_WRITE_BURST(32'h44A0_000C, 0, rand_key[63:32],  resp);
            master_agent.AXI4LITE_WRITE_BURST(32'h44A0_0010, 0, rand_key[31:0],   resp);

            master_agent.AXI4LITE_WRITE_BURST(32'h44A0_0000, 0, 32'h00000001, resp);
            #20; 
            master_agent.AXI4LITE_WRITE_BURST(32'h44A0_0000, 0, 32'h00000000, resp);

            status_reg = 0;
            timeout = 0;
            while ((status_reg[2] == 1'b0 && status_reg[0] == 1'b0) && (timeout < 500)) begin
                master_agent.AXI4LITE_READ_BURST(32'h44A0_0014, 0, status_reg, resp);
                #10;
                timeout++;
            end

            if (timeout >= 500) begin
                $error("[FAIL] Stress test stalled on iteration %0d", i);
                return;
            end
        end
        $display("[PASS] Stress test completed without stalls.");
    endtask

    // -------------------------------------------------------------------------
    // Main Verification Sequence
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        resetn = 0;
        
        master_agent = new("master_agent", UUT.ichip_ps2_i.axi_vip_0.inst.IF);
        master_agent.start_master();

        // FIX: Increased from 100ns to 200ns (20 clock cycles) to satisfy the AXI VIP minimum reset requirement
        #200 resetn = 1;
        #100;

        $display("=================================================");
        $display("  AES-128 AXI IP VERIFICATION SUITE");
        $display("=================================================");

        // FIPS-197 Standard Vectors
        aes_test_vector(
            "FIPS-197 Appendix B",
            128'h3243f6a8_885a308d_313198a2_e0370734, 
            128'h2b7e1516_28aed2a6_abf71588_09cf4f3c, 
            128'h3925841d_02dc09fb_dc118597_196a0b32  
        );
        #100;

        aes_test_vector(
            "FIPS-197 Appendix C",
            128'h00112233_44556677_8899aabb_ccddeeff, 
            128'h00010203_04050607_08090a0b_0c0d0e0f, 
            128'h69c4e0d8_6a7b0430_d8cdb780_70b4c55a  
        );
        #100;

        aes_test_vector(
            "Zero Key / Zero Text",
            128'h00000000_00000000_00000000_00000000, 
            128'h00000000_00000000_00000000_00000000, 
            128'h66e94bd4_ef8a2c3b_884cfa59_ca342b2e  
        );
        #100;

        // Pipeline Stability Validation
        aes_stress_test(25); 

        $display("=================================================");
        $display("  VERIFICATION COMPLETE");
        $display("=================================================");
        
        #500;
        $finish;
    end

endmodule