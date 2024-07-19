`timescale 1 ns / 1 ps

/*

MPS ADC Module
개발 4팀 전경원 차장

1. 개요
 총 16개의 ADC Data의 합산
 ADC 주기마다 Shift하여 연산함

2. 연산식
 n-15 + n-14 + ... + n = Output Data
 n은 현재 ADC 값
 해당 값을 Floating Point로 변환 시 공식에 의해서 1개의 데이터로 연산됨
 
*/

module ADC_Data_Moving_Sum
(
	input i_clk,
	input i_rst,

	input [23:0] i_adc_data,
	input i_adc_valid,

	output reg [31:0] o_adc_data
);

	reg [23:0] adc_tmp [15:0];

	always @(posedge i_clk or negedge i_rst) 
    begin
		if (~i_rst)
		begin
			adc_tmp[0] <= 0;
			adc_tmp[1] <= 0;
			adc_tmp[2] <= 0;
			adc_tmp[3] <= 0;
			adc_tmp[4] <= 0;
			adc_tmp[5] <= 0;
			adc_tmp[6] <= 0;
			adc_tmp[7] <= 0;
			adc_tmp[8] <= 0;
			adc_tmp[9] <= 0;
			adc_tmp[10] <= 0;
			adc_tmp[11] <= 0;
			adc_tmp[12] <= 0;
			adc_tmp[13] <= 0;
			adc_tmp[14] <= 0;
			adc_tmp[15] <= 0;
		end

		else if (i_adc_valid)
		begin
			adc_tmp[0] <= {~i_adc_data[23], i_adc_data[22:0]};
			adc_tmp[1] <= adc_tmp[0];
			adc_tmp[2] <= adc_tmp[1];
			adc_tmp[3] <= adc_tmp[2];
			adc_tmp[4] <= adc_tmp[3];
			adc_tmp[5] <= adc_tmp[4];
			adc_tmp[6] <= adc_tmp[5];
			adc_tmp[7] <= adc_tmp[6];
			adc_tmp[8] <= adc_tmp[7];
			adc_tmp[9] <= adc_tmp[8];
			adc_tmp[10] <= adc_tmp[9];
			adc_tmp[11] <= adc_tmp[10];
			adc_tmp[12] <= adc_tmp[11];
			adc_tmp[13] <= adc_tmp[12];
			adc_tmp[14] <= adc_tmp[13];
			adc_tmp[15] <= adc_tmp[14];
		end

		else
		begin
			adc_tmp[0] <= adc_tmp[0];
			adc_tmp[1] <= adc_tmp[1];
			adc_tmp[2] <= adc_tmp[2];
			adc_tmp[3] <= adc_tmp[3];
			adc_tmp[4] <= adc_tmp[4];
			adc_tmp[5] <= adc_tmp[5];
			adc_tmp[6] <= adc_tmp[6];
			adc_tmp[7] <= adc_tmp[7];
			adc_tmp[8] <= adc_tmp[8];
			adc_tmp[9] <= adc_tmp[9];
			adc_tmp[10] <= adc_tmp[10];
			adc_tmp[11] <= adc_tmp[11];
			adc_tmp[12] <= adc_tmp[12];
			adc_tmp[13] <= adc_tmp[13];
			adc_tmp[14] <= adc_tmp[14];
			adc_tmp[15] <= adc_tmp[15];
		end
	end

	always @(posedge i_clk or negedge i_rst) 
    begin
		if (~i_rst)
			o_adc_data <= 0;

		else if (i_adc_valid)
			o_adc_data <= 	adc_tmp[0] + adc_tmp[1] + adc_tmp[2] + adc_tmp[3] + adc_tmp[4] +
							adc_tmp[5] + adc_tmp[6] + adc_tmp[7] + adc_tmp[8] + adc_tmp[9] +
							adc_tmp[10] + adc_tmp[11] + adc_tmp[12] + adc_tmp[13] + adc_tmp[14] + adc_tmp[15];
		
		else
			o_adc_data <= o_adc_data;
	end

endmodule