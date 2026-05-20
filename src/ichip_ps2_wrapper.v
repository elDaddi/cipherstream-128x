//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
//Date        : Sun Apr  5 00:22:58 2026
//Host        : EL_DADDI running 64-bit major release  (build 9200)
//Command     : generate_target ichip_ps2_wrapper.bd
//Design      : ichip_ps2_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ichip_ps2_wrapper
   (s00_axi_aclk_0,
    s00_axi_aresetn_0);
  input s00_axi_aclk_0;
  input s00_axi_aresetn_0;

  wire s00_axi_aclk_0;
  wire s00_axi_aresetn_0;

  ichip_ps2 ichip_ps2_i
       (.s00_axi_aclk_0(s00_axi_aclk_0),
        .s00_axi_aresetn_0(s00_axi_aresetn_0));
endmodule
