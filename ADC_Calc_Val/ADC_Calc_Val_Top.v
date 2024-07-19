`timescale 1 ns / 1 ps

/*

MPS ADC Calculator Module
개발 4팀 전경원 차장

24.06.10 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 

1. 개요
 - Floating Point IP의 결과값을 연산하기 위한 변수 모듈
 - 16개의 ADC Raw Data를 합한 값을 연산

2. 연산식
 - RESULT = ((ADC Raw Data * Gain) + Offset) * Factor
 - Factor는 DSP 모듈에서 보내줌

*/

module ADC_Calc_Val_Top
(
	output [31:0] o_c_gain_axis_tdata,
	output o_c_gain_axis_tvalid,

	output [31:0] o_v_gain_axis_tdata,
	output o_v_gain_axis_tvalid,

	output [31:0] o_c_offset_axis_tdata,
	output o_c_offset_axis_tvalid,

	output [31:0] o_v_offset_axis_tdata,
	output o_v_offset_axis_tvalid
);

assign o_c_gain_axis_tdata = 32'h32000000;		// 7.45058059692382E-09
assign o_v_gain_axis_tdata = 32'h32000000;		// 7.45058059692382E-09

assign o_c_offset_axis_tdata = 32'hbf800000;		// -1
assign o_v_offset_axis_tdata = 32'hbf800000;		// -1

assign o_c_gain_axis_tvalid = 1;
assign o_v_gain_axis_tvalid = 1;
assign o_c_offset_axis_tvalid = 1;
assign o_v_offset_axis_tvalid = 1;

endmodule