`timescale 1 ns / 1 ps

/*

MPS Front Panel Module
개발 4팀 전경원 차장

24.07.26 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 

1. 개요
 - 

*/

module FRONT_v1_0_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH = 6
)
(
	// to SPI Module
	input i_spi_cs,				// SPI Module (n_cs)
	output o_spi_start,			// SPI Module (i_spi_start)
	output [23:0] o_mosi_data,	// SPI Module (i_mosi_data)
	input [23:0] i_miso_data,	// SPI Module (o_miso_data)

	// to Ext.Port
	input i_sw_intr,
	input i_ro_en_state_a,
	input i_ro_en_state_b,

	output o_lcd_cs,
	output o_sw_cs,

	// DPBRAM Single Clock (LCD Data) Bus Interface Ports Attribute (M : Write Only - AXI / S : Read Only - LCD)
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_lcd_data_dpbram addr0" *) output [7:0] o_lcd_data_m_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_lcd_data_dpbram ce0" *) output o_lcd_data_m_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_lcd_data_dpbram we0" *) output o_lcd_data_m_we,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_lcd_data_dpbram din0" *) output [23:0] o_lcd_data_m_dout,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_lcd_data_dpbram dout0" *) input [23:0] i_lcd_data_m_din,

	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_lcd_data_dpbram addr1" *) output [7:0] o_lcd_data_s_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_lcd_data_dpbram ce1" *) output o_lcd_data_s_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_lcd_data_dpbram we1" *) output o_lcd_data_s_we,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_lcd_data_dpbram din1" *) output [23:0] o_lcd_data_s_dout,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_lcd_data_dpbram dout1" *) input [23:0] i_lcd_data_s_din,

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

	wire lcd_sw_start;
	wire sw_intr_clear;
	wire [7:0] sw_data;

	wire [1:0] ro_en_data;

	wire lcd_sw_cs;

	AXI4_Lite_S03 #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_S03
	(
		.o_lcd_sw_start(lcd_sw_start),
		.o_sw_intr_clear(sw_intr_clear),

		.i_ro_en_data(ro_en_data),
		.i_sw_data(sw_data),

		.o_dpbram_axi_data(o_lcd_data_m_dout),
		.o_dpbram_axi_addr(o_lcd_data_m_addr),
		.o_dpbram_axi_ce(o_lcd_data_m_ce),
		.o_dpbram_axi_we(o_lcd_data_m_we),

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

	LCD_SW
	u_LCD_SW
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_lcd_sw_start(lcd_sw_start),
		.i_sw_intr(i_sw_intr),
		.i_sw_intr_clear(sw_intr_clear),
		.o_sw_data(sw_data),

		.i_dpbram_data(i_lcd_data_s_din),
		.o_dpbram_addr(o_lcd_data_s_addr),

		.o_spi_start(o_spi_start),
		.o_mosi_data(o_mosi_data),
		.i_miso_data(i_miso_data),

		.o_lcd_sw_cs(lcd_sw_cs)
	);

	RO_EN
	u_RO_EN
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_ro_en_state_a(i_ro_en_state_a),
		.i_ro_en_state_b(i_ro_en_state_b),

		.i_sw_intr_clear(sw_intr_clear),
		.o_ro_en_data(ro_en_data)
	);

	assign o_lcd_cs = ~(lcd_sw_cs) ? i_spi_cs : 1;
	assign o_sw_cs = (lcd_sw_cs) ? i_spi_cs : 1;

	assign o_lcd_data_s_ce = 1;
	assign o_lcd_data_s_we = 0;
	assign o_lcd_data_s_dout = 0;

endmodule