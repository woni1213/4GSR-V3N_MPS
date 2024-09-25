`timescale 1 ns / 1 ps

/*
*/

module WF_v1_0_Top #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_NUM = 8,
	parameter integer C_S_AXI_ADDR_WIDTH = $clog2(C_S_AXI_ADDR_NUM) + 2
)
(
	input i_wf_read_cnt,							// Core IP
	
	output o_dsp_wf_mode,							// WF Mode MMTXP1 DMTXP1(GPIO32)

	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_WF_DPBRAM addr0" *) output [9:0] o_xintf_wf_ram_addr,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_WF_DPBRAM ce0" *) output o_xintf_wf_ram_ce,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_WF_DPBRAM we0" *) output o_xintf_wf_ram_we,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_WF_DPBRAM din0" *) output [15:0] o_xintf_wf_ram_din,
    (* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 M_XINTF_WF_DPBRAM dout0" *) input [15:0] i_xintf_wf_ram_dout,

    // AXI4 Lite Bus Interface Ports
	input wire  s00_axi_aclk,
    input wire  s00_axi_aresetn,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire  s00_axi_awvalid,
    output wire  s00_axi_awready,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire  s00_axi_wvalid,
    output wire  s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire  s00_axi_bvalid,
    input wire  s00_axi_bready,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire  s00_axi_arvalid,
    output wire  s00_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire  s00_axi_rvalid,
    input wire  s00_axi_rready
);

	wire wf_mode_start;
	wire wf_write_en;
	wire [9:0] wf_write_addr;
	wire [15:0] wf_write_data;
	wire [31:0] wf_read_data_num;

	AXI4_Lite_S04 #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_NUM(C_S_AXI_ADDR_NUM),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_S04
	(
		// DPBRAM Write
		.o_wf_mode_start(wf_mode_start),						
		.o_wf_write_en(wf_write_en),						
		.o_wf_write_addr(wf_write_addr),
		.o_wf_write_data(wf_write_data),

		// DPRAM Read
		.i_wf_read_data_num(wf_read_data_num),

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

    WF
	u_WF
	(
		.i_clk(s00_axi_aclk),
        .i_rst(s00_axi_aresetn),

		.i_wf_start(wf_mode_start),
		.o_dsp_wf_mode(o_dsp_wf_mode),

		.i_wf_read_cnt(i_wf_read_cnt),

		.i_wf_write_en(wf_write_en),

        // DPBRAM Write
        .o_xintf_wf_ram_addr(o_xintf_wf_ram_addr),
        .o_xintf_wf_ram_din(o_xintf_wf_ram_din),
		.o_xintf_wf_ram_ce(o_xintf_wf_ram_ce),

		.i_wf_write_addr(wf_write_addr),
		.i_wf_write_data(wf_write_data),

		.o_wf_read_data_num(wf_read_data_num)
    );

	assign o_xintf_wf_ram_we = 1;

endmodule