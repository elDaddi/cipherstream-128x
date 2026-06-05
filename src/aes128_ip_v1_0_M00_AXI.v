`timescale 1 ns / 1 ps

module aes128_ip_v1_0_M00_AXI #
(
    parameter  C_M_START_DATA_VALUE       = 32'hAA000000,
    parameter  C_M_TARGET_SLAVE_BASE_ADDR = 32'h40000000,
    parameter integer C_M_AXI_ADDR_WIDTH  = 32,
    parameter integer C_M_AXI_DATA_WIDTH  = 32,
    parameter integer C_M_TRANSACTIONS_NUM = 4
)
(
    // User Ports
    input wire start_fetch,      
    output reg [127:0] pt_data,  
    output reg pt_valid,         
    input wire [127:0] ct_data,  
    input wire ct_valid,

    // AXI Infrastructure
    input wire  M_AXI_ACLK,
    input wire  M_AXI_ARESETN,
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output wire [2 : 0] M_AXI_ARPROT,
    output reg  M_AXI_ARVALID,
    input wire  M_AXI_ARREADY,
    input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input wire [1 : 0] M_AXI_RRESP,
    input wire  M_AXI_RVALID,
    output reg  M_AXI_RREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output wire [2 : 0] M_AXI_AWPROT,
    output reg  M_AXI_AWVALID,
    input wire  M_AXI_AWREADY,
    output reg [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
    output reg  M_AXI_WVALID,
    input wire  M_AXI_WREADY,
    input wire [1 : 0] M_AXI_BRESP,
    input wire  M_AXI_BVALID,
    output reg  M_AXI_BREADY,
    output wire  TXN_DONE,
    output wire  ERROR,
    input wire  INIT_AXI_TXN
);

    // FSM States
    parameter IDLE=0, READ_ADDR=1, READ_DATA=2, TRIGGER_AES=3, WAIT_AES=4, WRITE_ADDR=5, WRITE_DATA=6, WRITE_RESP=7;
    
    reg [2:0] state, next_state;
    reg [1:0] word_ct;
    reg [31:0] read_addr_ptr;
    reg [31:0] write_addr_ptr;

    // Address Offsets
    assign M_AXI_ARADDR = C_M_TARGET_SLAVE_BASE_ADDR + read_addr_ptr;
    assign M_AXI_AWADDR = C_M_TARGET_SLAVE_BASE_ADDR + write_addr_ptr;

    // AXI Static Signals
    assign M_AXI_WSTRB = 4'b1111;
    assign M_AXI_AWPROT = 3'b000;
    assign M_AXI_ARPROT = 3'b000;
    assign ERROR = 1'b0;

    assign TXN_DONE = (state == WRITE_RESP && M_AXI_BVALID && M_AXI_BREADY && word_ct == 3);

    // Data Multiplexer (Ciphertext to 32-bit AXI)
    always @(*) begin
        case(word_ct)
            2'd0: M_AXI_WDATA = ct_data[127:96];
            2'd1: M_AXI_WDATA = ct_data[95:64];
            2'd2: M_AXI_WDATA = ct_data[63:32];
            2'd3: M_AXI_WDATA = ct_data[31:0];
            default: M_AXI_WDATA = 32'b0;
        endcase
    end

    // State Transition
    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) state <= IDLE;
        else state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        case(state)
            IDLE: next_state = start_fetch ? READ_ADDR : IDLE;
            READ_ADDR: next_state = M_AXI_ARREADY ? READ_DATA : READ_ADDR;
            READ_DATA: begin
                            if (M_AXI_RVALID && M_AXI_RREADY) 
                               next_state = (word_ct == 3) ? TRIGGER_AES : READ_ADDR;
                            else 
                                next_state = READ_DATA;
                        end
            TRIGGER_AES: next_state = WAIT_AES; // Pulse state
            WAIT_AES: next_state = ct_valid ? WRITE_ADDR : WAIT_AES;
            WRITE_ADDR: next_state = M_AXI_AWREADY ? WRITE_DATA : WRITE_ADDR;
            WRITE_DATA: next_state = M_AXI_WREADY ? WRITE_RESP : WRITE_DATA;
            WRITE_RESP: begin
                            if (M_AXI_BVALID && M_AXI_BREADY)
                                next_state = (word_ct == 3) ? IDLE : WRITE_ADDR;
                            else 
                                next_state = WRITE_RESP;
                        end
            default: next_state = IDLE;
        endcase
    end

    // Control Signal Logic
    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            M_AXI_ARVALID <= 0; M_AXI_RREADY <= 0; M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0; M_AXI_BREADY <= 0; pt_valid <= 0;
        end else begin
            M_AXI_ARVALID <= (next_state == READ_ADDR);
            M_AXI_RREADY <= (next_state == READ_DATA);
            pt_valid <= (next_state == TRIGGER_AES); // Pure 1-cycle pulse
            M_AXI_AWVALID <= (next_state == WRITE_ADDR);
            M_AXI_WVALID <= (next_state == WRITE_DATA);
            M_AXI_BREADY <= (next_state == WRITE_RESP);
        end
    end

    // Register & Counter Logic
    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            word_ct <= 0; 
            read_addr_ptr <= 0; 
            write_addr_ptr <= 32'h0000_0000;
            pt_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    word_ct <= 0;
                    read_addr_ptr <= 0;
                    write_addr_ptr <= 0; // FIX 1: Reset the write pointer!
                end
               READ_DATA: begin
                    if (M_AXI_RVALID && M_AXI_RREADY) begin
                        // PACK MSB FIRST (Fixed Endianness)
                        case(word_ct)
                            2'd0: pt_data[127:96] <= M_AXI_RDATA;
                            2'd1: pt_data[95:64] <= M_AXI_RDATA;
                            2'd2: pt_data[63:32] <= M_AXI_RDATA;
                            2'd3: pt_data[31:0] <= M_AXI_RDATA;
                        endcase
                        word_ct <= word_ct+1;
                        read_addr_ptr <= read_addr_ptr+4;
                    end
                end
                TRIGGER_AES: begin
                    word_ct <= 0; // Reset counter for the write phase
                end
                WRITE_RESP: begin
                    if (M_AXI_BVALID && M_AXI_BREADY) begin
                        word_ct <= word_ct + 1;
                        write_addr_ptr <= write_addr_ptr + 4;
                    end
                end
            endcase
        end
    end

endmodule
