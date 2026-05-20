`timescale 1 ns / 1 ps

module aes128_ip_v1_0 #
(
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 5,
    parameter C_M00_AXI_START_DATA_VALUE = 32'hAA000000,
    parameter C_M00_AXI_TARGET_SLAVE_BASE_ADDR = 32'h40000000,
    parameter integer C_M00_AXI_ADDR_WIDTH = 32,
    parameter integer C_M00_AXI_DATA_WIDTH = 32,
    parameter integer C_M00_AXI_TRANSACTIONS_NUM = 4
)
(
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire s00_axi_rready,

    input wire m00_axi_init_axi_txn,
    output wire m00_axi_error,
    output wire m00_axi_txn_done,
    input wire m00_axi_aclk,
    input wire m00_axi_aresetn,
    output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
    output wire [2 : 0] m00_axi_awprot,
    output wire m00_axi_awvalid,
    input wire m00_axi_awready,
    output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
    output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
    output wire m00_axi_wvalid,
    input wire m00_axi_wready,
    input wire [1 : 0] m00_axi_bresp,
    input wire m00_axi_bvalid,
    output wire m00_axi_bready,
    output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
    output wire [2 : 0] m00_axi_arprot,
    output wire m00_axi_arvalid,
    input wire m00_axi_arready,
    input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
    input wire [1 : 0] m00_axi_rresp,
    input wire m00_axi_rvalid,
    output wire m00_axi_rready
);

    wire w_start_aes;
    wire w_stop_aes;
    wire [127:0] w_aes_key;
    wire w_key_valid;
    wire w_start_pulse;

    wire w_aes_idle;
    wire w_aes_busy;
    wire w_aes_done;
    wire w_aes_error;

    wire [127:0] w_pt_data;
    wire w_pt_valid;
    wire [127:0] w_ct_data;
    wire w_ct_valid;

    // AES Core
    aes_core aes_core_inst (
        .clk(s00_axi_aclk),
        .reset(~s00_axi_aresetn), 
        .enable(1'b1),            
        .pt_valid(w_pt_valid),    
        .data_in(w_pt_data),      
        .key_in(w_aes_key),       
        .ct_valid(w_ct_valid),    
        .data_out(w_ct_data)      
    );

    // Ciphertext Register
    reg [127:0] held_ciphertext;
    always @(posedge s00_axi_aclk) begin
        if (!s00_axi_aresetn) begin
            held_ciphertext <= 128'b0;
        end else if (w_ct_valid) begin 
            held_ciphertext <= w_ct_data; 
        end
    end
    
    // Status Flags (Fixed for 1-cycle Done pulse)
    reg r_aes_busy;
    reg r_aes_done;

    always @(posedge s00_axi_aclk) begin
        if (!s00_axi_aresetn) begin
            r_aes_busy <= 1'b0;
            r_aes_done <= 1'b0;
        end else begin
            r_aes_done <= 1'b0; // Default pulldown for 1-cycle pulse
            
            if (w_start_aes) begin
                r_aes_busy <= 1'b1;
            end else if (m00_axi_txn_done && r_aes_busy) begin 
                r_aes_busy <= 1'b0;
                r_aes_done <= 1'b1; 
            end
        end
    end

    assign w_aes_idle  = !r_aes_busy && !r_aes_done; 
    assign w_aes_busy  = r_aes_busy;
    assign w_aes_done  = r_aes_done;
    assign w_aes_error = 1'b0;

    // AXI4-Lite Slave
    aes128_ip_v1_0_S00_AXI # ( 
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) aes128_ip_v1_0_S00_AXI_inst (
        .start_aes(w_start_aes),
        .stop_aes(w_stop_aes),
        .aes_key(w_aes_key),
        .key_valid(w_key_valid),
        .start_pulse(w_start_pulse),
        .aes_idle(w_aes_idle),
        .aes_busy(w_aes_busy),
        .aes_done(w_aes_done),
        .aes_error(w_aes_error),

        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    // AXI4 Master
    aes128_ip_v1_0_M00_AXI # ( 
        .C_M_START_DATA_VALUE(C_M00_AXI_START_DATA_VALUE),
        .C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
        .C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
        .C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
        .C_M_TRANSACTIONS_NUM(C_M00_AXI_TRANSACTIONS_NUM)
    ) aes128_ip_v1_0_M00_AXI_inst (
        .start_fetch(w_start_aes),  
        .pt_data(w_pt_data),
        .pt_valid(w_pt_valid),
        .ct_data(held_ciphertext),  
        .ct_valid(w_ct_valid),      

        .INIT_AXI_TXN(m00_axi_init_axi_txn),
        .ERROR(m00_axi_error),
        .TXN_DONE(m00_axi_txn_done),
        .M_AXI_ACLK(m00_axi_aclk),
        .M_AXI_ARESETN(m00_axi_aresetn),
        .M_AXI_AWADDR(m00_axi_awaddr),
        .M_AXI_AWPROT(m00_axi_awprot),
        .M_AXI_AWVALID(m00_axi_awvalid),
        .M_AXI_AWREADY(m00_axi_awready),
        .M_AXI_WDATA(m00_axi_wdata),
        .M_AXI_WSTRB(m00_axi_wstrb),
        .M_AXI_WVALID(m00_axi_wvalid),
        .M_AXI_WREADY(m00_axi_wready),
        .M_AXI_BRESP(m00_axi_bresp),
        .M_AXI_BVALID(m00_axi_bvalid),
        .M_AXI_BREADY(m00_axi_bready),
        .M_AXI_ARADDR(m00_axi_araddr),
        .M_AXI_ARPROT(m00_axi_arprot),
        .M_AXI_ARVALID(m00_axi_arvalid),
        .M_AXI_ARREADY(m00_axi_arready),
        .M_AXI_RDATA(m00_axi_rdata),
        .M_AXI_RRESP(m00_axi_rresp),
        .M_AXI_RVALID(m00_axi_rvalid),
        .M_AXI_RREADY(m00_axi_rready)
    );

endmodule