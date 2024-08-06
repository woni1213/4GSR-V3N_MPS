`timescale 1 ns / 1 ps

/*

MPS ADC Module
개발 4팀 전경원 차장

24.05.08 :	최초 생성

24.08.06 :	INTL용 ADC 출력 데이터 포트 추가

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - System Clock : 200MHz / 5ns
 - C_	: 전류
 - V_	: 전압
 - DC_	: DC-Link 전압

1. ADC
총 3개의 ADC 사용 (AD)
 - AD4030-24	: MPS 출력 전류 측정, 1Ch 24Bit 2MSps
 - AD4030-24	: MPS 출력 전압 측정, 1Ch 24Bit 2MSps
 - ADS8689		: MPS DC-Link 전압 측정 (MPS 내부 SMPS)

2. Module
 2.1 Module
	V3N_ADC_v1_0_Top	- AD4030_24 			: MPS 출력
						- ADS8689 				: MPS DC-Link 전압
						- AXI4_Lite_S00 		: AXI4-Lite
						- ADC_Data_Moving_Sum	: ADC Raw Data Sum

 2.2 IP
  - SPI_v1_0 X 3ea
  - DPBRAM_Single_Clock_v1_0 X 3ea

 2.3 AD4030_24
  - MPS 출력 전압, 전류 ADC Control
  - 2개의 ADC 동시 제어 (타이밍 등 모두 동일)

 2.4 DPBRAM
  - AD4030_24 용
  	; DWIDTH	: 24
	; RAM_DEPTH : 20000

  - ADS8689 용
  	; DWIDTH	: 16
	; RAM_DEPTH : 2000

3. Data Flow
 - ADC Sum Raw Data는 Floating-Point로 변환 및 연산 후 최종적으로 DSP 및 PL로 보냄
 - ADC Raw Data는 DPBRAM에 일정 횟수만큼 저장한 후 Flag
 	; 총 20000개의 데이터 중 10000개 데이터마다 Flag
 - PS는 Flag를 보고 데이터를 10000개씩 Read함
 - ADC 측정 데이터 등은 바로 DPBRAM과 AXI로 보냄

*/

module ADC_v1_0_Top #
(
	parameter integer C_S_AXI_DATA_WIDTH = 32,
	parameter integer C_S_AXI_ADDR_WIDTH = 6,

	parameter integer AD4030_RAM_DWIDTH = 24,
	parameter integer AD4030_RAM_DEPTH = 20000,

	parameter integer ADS8689_RAM_DWIDTH = 16,
	parameter integer ADS8689_RAM_DEPTH = 2000
)
(
	// 공통
	output o_v_c_adc_cnv,					// AD4030 Conversion Port
	output o_v_c_adc_spi_start,				// AD4030 SPI Start

	// V_ADC Ext. Port
	input i_v_adc_busy,						// AD4030 Busy Port

	// V_ADC to SPI
	output [23:0] o_v_adc_o_mosi_data,		// AD4030 MOSI Data. Fixed 0x000000
	input [23:0] i_v_adc_i_miso_data,		// AD4030 MISO Data
	input i_v_adc_data_valid,				// AD4030 SPI Data Valid In

	// C_ADC Ext. Port
	input i_c_adc_busy,

	// C_ADC to SPI
	output [23:0] o_c_adc_o_mosi_data,
	input [23:0] i_c_adc_i_miso_data,
	input i_c_adc_data_valid,

	// DC_ADC Ext. Port
	input i_dc_adc_rvs,						// ADS8689 RVS Port
	output o_dc_adc_cnv,					// ADS8689 Conversion Port

	// DC_ADC to SPI
	output o_dc_adc_spi_start,				
	output [31:0] o_dc_adc_o_mosi_data,
	input [31:0] i_dc_adc_i_miso_data,
	input i_dc_adc_data_valid,

	// Ext.Reset
	output o_adc_ext_rst,
	input i_adc_ps_rst,

	// ADC Data
	output [15:0] o_dc_adc_data,
	output [31:0] o_v_axis_tdata,
	output [31:0] o_c_axis_tdata,

	// Floating-Point
	output o_v_axis_tvalid,
	output o_c_axis_tvalid,

	// To INTL
	output [31:0] o_v_adc_data,
	output [31:0] o_c_adc_data,

	// DPBRAM (Voltage) Bus Interface Ports Attribute
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_v_dpbram addr0" *) output [$clog2(AD4030_RAM_DEPTH) - 1 : 0] o_v_adc_m_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_v_dpbram ce0" *) output o_v_adc_m_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_v_dpbram we0" *) output o_v_adc_m_we,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_v_dpbram din0" *) output [AD4030_RAM_DWIDTH - 1 : 0] o_v_adc_m_dout,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_v_dpbram dout0" *) input [AD4030_RAM_DWIDTH - 1 : 0] i_v_adc_m_din,

	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_v_dpbram addr1" *) output [$clog2(AD4030_RAM_DEPTH) - 1 : 0] o_v_adc_s_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_v_dpbram ce1" *) output o_v_adc_s_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_v_dpbram we1" *) output o_v_adc_s_we,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_v_dpbram din1" *) output [AD4030_RAM_DWIDTH - 1 : 0] o_v_adc_s_dout,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_v_dpbram dout1" *) input [AD4030_RAM_DWIDTH - 1 : 0] i_v_adc_s_din,

	// DPBRAM (Current) Bus Interface Ports Attribute
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_c_dpbram addr0" *) output [$clog2(AD4030_RAM_DEPTH) - 1 : 0] o_c_adc_m_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_c_dpbram ce0" *) output o_c_adc_m_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_c_dpbram we0" *) output o_c_adc_m_we,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_c_dpbram din0" *) output [AD4030_RAM_DWIDTH - 1 : 0] o_c_adc_m_dout,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_c_dpbram dout0" *) input [AD4030_RAM_DWIDTH - 1 : 0] i_c_adc_m_din,

	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_c_dpbram addr1" *) output [$clog2(AD4030_RAM_DEPTH) - 1 : 0] o_c_adc_s_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_c_dpbram ce1" *) output o_c_adc_s_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_c_dpbram we1" *) output o_c_adc_s_we,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_c_dpbram din1" *) output [AD4030_RAM_DWIDTH - 1 : 0] o_c_adc_s_dout,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_c_dpbram dout1" *) input [AD4030_RAM_DWIDTH - 1 : 0] i_c_adc_s_din,

	// DPBRAM (DC-Link) Bus Interface Ports Attribute
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_dc_dpbram addr0" *) output [$clog2(ADS8689_RAM_DEPTH) - 1 : 0] o_dc_adc_m_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_dc_dpbram ce0" *) output o_dc_adc_m_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_dc_dpbram we0" *) output o_dc_adc_m_we,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_dc_dpbram din0" *) output [ADS8689_RAM_DWIDTH - 1 : 0] o_dc_adc_m_dout,
	(* X_INTERFACE_INFO = "HMT:JKW:s_dpbram_port:1.0 m_dc_dpbram dout0" *) input [ADS8689_RAM_DWIDTH - 1 : 0] i_dc_adc_m_din,

	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_dc_dpbram addr1" *) output [$clog2(ADS8689_RAM_DEPTH) - 1 : 0] o_dc_adc_s_addr,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_dc_dpbram ce1" *) output o_dc_adc_s_ce,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_dc_dpbram we1" *) output o_dc_adc_s_we,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_dc_dpbram din1" *) output [ADS8689_RAM_DWIDTH - 1 : 0] o_dc_adc_s_dout,
	(* X_INTERFACE_INFO = "HMT:JKW:m_dpbram_port:1.0 s_dc_dpbram dout1" *) input [ADS8689_RAM_DWIDTH - 1 : 0] i_dc_adc_s_din,

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

	wire rst;
	wire o_adc_rst;

	// AD4030_24
	wire v_c_adc_ram_1_flag;
	wire v_c_adc_ram_2_flag;
	wire adc_data_valid;

	// ADS8689
	wire dc_adc_ram_1_flag;
	wire dc_adc_ram_2_flag;

	// DPBRAM
	wire [14:0] v_c_adc_m_addr;
	wire v_c_adc_m_ram_ce;
	wire [14:0] v_c_adc_ram_addr;
	wire v_c_adc_s_ram_ce;

	// Debug
	wire [1:0] v_c_debug_state;
	wire [2:0] dc_debug_state;

	wire [31:0] v_adc_data;
	wire [31:0] c_adc_data;

	AXI4_Lite_S00 #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
	)
	u_AXI4_Lite_S00
	(
		// ADC DPBRAM Control
		.o_v_c_adc_ram_cs(v_c_adc_s_ram_ce),
		.o_v_c_adc_ram_w(),			// Not Used
		.o_v_c_adc_ram_r(),			// Not Used

		.o_dc_adc_ram_cs(o_dc_adc_s_ce),
		.o_dc_adc_ram_w(),			// Not Used
		.o_dc_adc_ram_r(),			// Not Used

		// ADC DPBRAM Write Data
		.o_v_c_adc_ram_wdata(),		// Not Used
		.o_dc_adc_ram_wdata(),		// Not Used

		// ADC DPBRAM Address
		.o_v_c_adc_ram_addr(v_c_adc_ram_addr),
		.o_dc_adc_ram_addr(o_dc_adc_s_addr),

		// ADC Reset
		.o_adc_rst(o_adc_rst),

		// ADC DPBRAM Data Flag
		.i_v_c_adc_ram_1_flag(v_c_adc_ram_1_flag),
		.i_v_c_adc_ram_2_flag(v_c_adc_ram_2_flag),
		.i_dc_adc_ram_1_flag(dc_adc_ram_1_flag),
		.i_dc_adc_ram_2_flag(dc_adc_ram_2_flag),

		.i_v_adc_ram_rdata(i_v_adc_s_din),
		.i_c_adc_ram_rdata(i_c_adc_s_din),
		.i_dc_adc_ram_rdata(i_dc_adc_s_din),

		// Debug
		.i_v_adc_i_miso_data(i_v_adc_i_miso_data),
		.i_c_adc_i_miso_data(i_c_adc_i_miso_data),
		.i_dc_adc_i_miso_data(i_dc_adc_i_miso_data[15:0]),
		.i_v_c_debug_state(v_c_debug_state),
		.i_dc_debug_state(dc_debug_state),

		.rst(rst),
		.i_adc_ps_rst(i_adc_ps_rst),

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

	// MPS Output ADC
	AD4030_24 #
	(
		.AD4030_RAM_DEPTH(AD4030_RAM_DEPTH)
	)
	u_AD4030_24
	(
		.i_clk(s00_axi_aclk),
		.i_rst(rst),

		.i_v_adc_busy(i_v_adc_busy),
		.i_c_adc_busy(i_c_adc_busy),
		.o_v_c_adc_cnv(o_v_c_adc_cnv),

		.o_v_c_adc_spi_start(o_v_c_adc_spi_start),
		.i_v_adc_data_valid(i_v_adc_data_valid),
		.i_c_adc_data_valid(i_c_adc_data_valid),

		.o_v_c_adc_ram_addr(v_c_adc_m_addr),
		.o_v_c_adc_ram_cs(v_c_adc_m_ram_ce),
		.o_v_c_adc_ram_1_flag(v_c_adc_ram_1_flag),
		.o_v_c_adc_ram_2_flag(v_c_adc_ram_2_flag),
		.o_adc_data_valid(adc_data_valid),					// Valid를 1로 고정하였기 때문에 사용하지 않음

		.o_debug_state(v_c_debug_state)
	);

	ADS8689 #
	(
		.ADS8689_RAM_DEPTH(ADS8689_RAM_DEPTH)
	)
	u_ADS8689
	(
		.i_clk(s00_axi_aclk),
		.i_rst(rst),

		.i_dc_adc_rvs(i_dc_adc_rvs),
		.o_dc_adc_cnv(o_dc_adc_cnv),

		.o_dc_adc_spi_start(o_dc_adc_spi_start),
		.i_dc_adc_data_valid(i_dc_adc_data_valid),

		.o_dc_adc_ram_addr(o_dc_adc_m_addr),
		.o_dc_adc_ram_cs(o_dc_adc_m_ce),
		.o_dc_adc_ram_1_flag(dc_adc_ram_1_flag),
		.o_dc_adc_ram_2_flag(dc_adc_ram_2_flag),

		.o_dc_adc_o_mosi_data(o_dc_adc_o_mosi_data),

		.o_debug_state(dc_debug_state)
	);

	ADC_Data_Moving_Sum
	v_ADC_Data_Moving_Sum
	(
		.i_clk(s00_axi_aclk),
		.i_rst(rst),

		.i_adc_data(i_v_adc_i_miso_data),
		.i_adc_valid(v_c_adc_m_ram_ce),

		.o_adc_data(v_adc_data)
	);

	ADC_Data_Moving_Sum
	c_ADC_Data_Moving_Sum
	(
		.i_clk(s00_axi_aclk),
		.i_rst(rst),

		.i_adc_data(i_c_adc_i_miso_data),
		.i_adc_valid(v_c_adc_m_ram_ce),

		.o_adc_data(c_adc_data)
	);

	// Flag Assign
	assign rst = s00_axi_aresetn & ~i_adc_ps_rst & ~o_adc_rst;
	assign o_adc_ext_rst = rst;

	// Data Assign
	// assign o_v_axis_tvalid = adc_data_valid;					//Custom IP - Xillinx IP를 BUS로 연결할 경우 valid와 ready 신호가 어긋나서 data가 전달되지 못하므로 주석 처리 후 1(high)로 고정
	// assign o_c_axis_tvalid = adc_data_valid;
	assign o_v_axis_tvalid = 1;
	assign o_c_axis_tvalid = 1;
	assign o_v_adc_o_mosi_data = 24'h000000;
	assign o_c_adc_o_mosi_data = 24'h000000;
	assign o_v_adc_m_dout = i_v_adc_i_miso_data;
	assign o_c_adc_m_dout = i_c_adc_i_miso_data;
	assign o_dc_adc_m_dout = i_dc_adc_i_miso_data[15:0];
	assign o_dc_adc_data = i_dc_adc_i_miso_data[15:0];
	assign o_v_adc_m_addr = v_c_adc_m_addr;
	assign o_c_adc_m_addr = v_c_adc_m_addr;
	assign o_v_adc_m_ce = v_c_adc_m_ram_ce;
	assign o_c_adc_m_ce = v_c_adc_m_ram_ce;
	assign o_v_adc_m_we = 1;
	assign o_c_adc_m_we = 1;
	assign o_dc_adc_m_we = 1;
	assign o_v_adc_s_addr = v_c_adc_ram_addr;
	assign o_c_adc_s_addr = v_c_adc_ram_addr;
	assign o_v_adc_s_ce = v_c_adc_s_ram_ce;
	assign o_c_adc_s_ce = v_c_adc_s_ram_ce;
	assign o_v_adc_s_we = 0;
	assign o_c_adc_s_we = 0;
	assign o_dc_adc_s_we = 0;
	assign o_v_adc_s_dout = 0;
	assign o_c_adc_s_dout = 0;
	assign o_dc_adc_s_dout = 0;

	assign o_v_axis_tdata = v_adc_data;
	assign o_c_axis_tdata = c_adc_data;
	assign o_v_adc_data = v_adc_data;
	assign o_c_adc_data = c_adc_data;
endmodule