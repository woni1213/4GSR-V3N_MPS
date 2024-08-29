`timescale 1 ns / 1 ps
/*

SFP Test Module
개발 4팀 전경원 차장

24.08.26 :	최초 생성

1. 개요
 - 직병렬 테스트 전 개념 학습 및 기능 테스트
 - Master에서 명령을 주면 Slave LED 동작, 데이터 전송
 - Master, Slave 통합 코드
 - Stream은 전체 데이터
 - Frame은 Frame 데이터
 - Aurora SFP AXIS Frame IP와 같이 사용 (Custom IP)

2. M 동작
 - AXI4 Lite로 데이터와 신호를 주면 Master로 동작
 - Slave에서 데이터를 주면 종료

3. S 동작
 - SFP에서 Rx 신호가 발생하면 동작
 - 받은 데이터로 동작 처리 후 Tx로 데이터 전송

*/

module SFP_Test_Top #
(
	parameter integer C_AXIS_TDATA_WIDTH = 64,		// Frame Data Width
	parameter integer C_NUMBER_OF_SLAVE = 3,		// Slave 수
	parameter integer C_NUMBER_OF_FRAME = 1,		// Slave의 Frame 수

	parameter integer C_S_AXI_DATA_WIDTH = 32,		// AXI4 Lite
	parameter integer C_S_AXI_ADDR_WIDTH = 6,

	parameter integer C_DATA_BIT = ((C_AXIS_TDATA_WIDTH) * (C_NUMBER_OF_SLAVE) * (C_NUMBER_OF_FRAME)),	// Stream Bit 수
	parameter integer C_DATA_FRAME_BIT = ((C_AXIS_TDATA_WIDTH) * (C_NUMBER_OF_FRAME))					// Frame Bit 수
)
(
	output o_aurora_tx_start_flag,				// Tx 시작
	input i_aurora_rx_end_flag,					// Rx 종료

	output [C_DATA_BIT - 1 : 0] o_tx_stream_data,	// Aurora SFP AXIS Frame IP의 Stream 데이터 출력
	input [C_DATA_BIT - 1 : 0] i_rx_stream_data,	// Aurora SFP AXIS Frame IP의 Stream 데이터 입력

	output o_led_test,

	output [C_DATA_FRAME_BIT - 1 : 0] o_test_rx_frame_data,
	output [C_DATA_FRAME_BIT - 1 : 0] o_test_tx_frame_data,

	output [3:0] o_test_state,
	output o_test_clr,
	output [C_DATA_BIT - 1 : 0] o_ps_i_data,

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

	wire sfp_start_flag;
	wire sfp_stream_data_valid;
	wire sfp_stream_data_clr;
	wire frame_data_valid;
	wire frmae_data_clr;

	wire [C_DATA_BIT - 1 : 0] ps_i_data;
	wire [C_DATA_BIT - 1 : 0] ps_o_data;

	wire [C_DATA_FRAME_BIT - 1 : 0] rx_frame_data;
	wire [C_DATA_FRAME_BIT - 1 : 0] tx_frame_data;

	AXI4_Lite_S00 #
	(
		.C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),

		.C_DATA_BIT(C_DATA_BIT)
	)
	u_AXI4_Lite_S00
	(
		.o_data(ps_o_data),
		.i_data(ps_i_data),

		.o_sfp_start_flag(sfp_start_flag),
		.i_sfp_stream_data_valid(sfp_stream_data_valid),
		.o_sfp_stream_data_clr(sfp_stream_data_clr),

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

	SFP_Data_Handler #
	(
		.C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),

		.C_DATA_BIT(C_DATA_BIT),
		.C_DATA_FRAME_BIT(C_DATA_FRAME_BIT)
	)
	u_SFP_Data_Handler
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_axi_data(ps_o_data),
		.o_axi_data(ps_i_data),

		.i_rx_stream_data(i_rx_stream_data),
		.o_tx_stream_data(o_tx_stream_data),

		.i_frame_data(tx_frame_data),
		.o_frame_data(rx_frame_data),

		.i_ps_sfp_start(sfp_start_flag),
		.o_ps_sfp_valid(sfp_stream_data_valid),
		.i_ps_sfp_valid_clr(sfp_stream_data_clr),
		.o_frame_data_valid(frame_data_valid),
		.i_frame_data_clr(frmae_data_clr),

		.o_sfp_start_flag(o_aurora_tx_start_flag),
		.i_sfp_end_flag(i_aurora_rx_end_flag),

		.o_test_state(o_test_state)
	);

	LED_Test #
	(
		.C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
		.C_NUMBER_OF_FRAME(C_NUMBER_OF_FRAME),

		.C_DATA_FRAME_BIT(C_DATA_FRAME_BIT)
	)
	u_LED_Test
	(
		.i_clk(s00_axi_aclk),
		.i_rst(s00_axi_aresetn),

		.i_frame_data(rx_frame_data),
		.o_frame_data(tx_frame_data),

		.i_frame_data_valid(frame_data_valid),
		.o_frmae_data_clr(frmae_data_clr),

		.o_led_test(o_led_test)
	);

	assign o_test_rx_frame_data = rx_frame_data;
	assign o_test_tx_frame_data = tx_frame_data;

	assign o_test_clr = sfp_stream_data_clr;
	assign o_ps_i_data = ps_i_data;

endmodule	