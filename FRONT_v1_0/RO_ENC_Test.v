`timescale 1 ns / 1 ps

/*

MPS ROtary switch ENcorder Module
개발 4팀 전경원 차장

24.08.05 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 

1. 개요
 - RO_ENC.v 수정 코드
 - 기존의 코드가 정상동작하면 폐기 요망

2. 수정 사항
 - o_ro_enc_data 정보 변경 (이동 칸 수로 변경)
 - Direction 추가

3. 기능
 - 여러칸 움직임을 감지 (Clear 후 다시 초기화)
 - 비트로 움직임을 감지하지 않고 칸수 누적으로 변경 (o_ro_enc_data)
 - 회전 방향 추가
 - irq 추가 (알아서 판별 후 사용)

4. 동작
 - 동작이 감지되면 o_ro_enc_data에 칸수 누적 및 회전 방향 출력
 - 동시에 irq 신호 출력 (0일때 동작 X)
 - i_sw_intr_clear시 o_ro_enc_data를 0으로 초기화

*/

module RO_ENC
(
	input i_clk,
	input i_rst,

	input i_ro_enc_state_a,
	input i_ro_enc_state_b,

	input i_sw_intr_clear,
	output o_ro_enc_irq,
	output reg o_ro_enc_dir,			// 0 : CW, 1 : CCW
	output reg [4:0] o_ro_enc_data
);

	reg [1:0] prev_ab;
	reg [1:0] curr_ab;
	wire [3:0] ab_state;

	always @(posedge i_clk or negedge i_rst)
    begin
		if (~i_rst)
		begin
			prev_ab <= 0;
			curr_ab <= 0;
		end

		else
		begin
			prev_ab <= curr_ab;
			curr_ab <= {i_ro_enc_state_a, i_ro_enc_state_b};
		end
	end

	always @(posedge i_clk or negedge i_rst)
    begin
		if (~i_rst || i_sw_intr_clear)
		begin
			o_ro_enc_dir <= 0;
			o_ro_enc_data <= 0;
		end

		else if ((ab_state == 4'b0001) || (ab_state == 4'b1110))
		begin
			o_ro_enc_dir <= 0;
			o_ro_enc_data <= o_ro_enc_data + 1;
		end

		else if ((ab_state == 4'b0010) || (ab_state == 4'b1101))
		begin
			o_ro_enc_dir <= 1;
			o_ro_enc_data <= o_ro_enc_data + 1;
		end

		else
		begin
			o_ro_enc_dir <= o_ro_enc_dir;
			o_ro_enc_data <= o_ro_enc_data;
		end
	end

	assign ab_state = {prev_ab, curr_ab};
	assign o_ro_enc_irq = (o_ro_enc_data > 0) ? 1 : 0;

endmodule
