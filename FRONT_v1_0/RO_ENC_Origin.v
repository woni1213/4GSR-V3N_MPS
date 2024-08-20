`timescale 1 ns / 1 ps

/*

MPS ROtary switch ENcorder Module
개발 4팀 전경원 차장

24.07.25 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 동작 시방하게 되는데?
	두칸씩 움직여야 한번 동작함
	빠르게 돌리면 LCD 가끔 먹통됨
 - 원인 판별 필요 (PS or PL?)
 - 아마 PS가 원인일 확률이 매우 높음
 - 만약 원인이 PL이거나 PS에서 사용하기 어렵다면 RO_ENC_Test.v로 적용하여 테스트
 - """거지같이 동작해서 코드 폐기함"""

1. 개요
 - 

2. 동작
 - a, b는 00 01 이런식으로 표기
 - 멈춰있을때는 00 or 11로 대기함
 - 한칸이 CW나 CCW로 동작 시 00 -> 01 or 10 -> 11로 변경됨
 - 11부터 시작시에도 마찬가지

*/

module RO_ENC_Origin
(
	input i_clk,
	input i_rst,

	input i_ro_enc_state_a,
	input i_ro_enc_state_b,

	input i_sw_intr_clear,
	output [1:0] o_ro_enc_data	
);

	parameter IDLE 	= 0;
	parameter CW	= 1;	// o_ro_enc_data = 01, a가 먼저 변화하면
	parameter CCW	= 2;	// o_ro_enc_data = 10, b가 먼저 변화하면
	parameter LOW	= 3;	// o_ro_enc_data = 11, ab = 00
	parameter HIGH	= 4;	// o_ro_enc_data = 00, ab = 11

	// FSM
	reg [2:0] state;
	reg [2:0] n_state;

	// Flag
	wire low_state;
	wire high_state;

	// FSM Control
	always @(posedge i_clk or negedge i_rst)
    begin
        if (~i_rst)
            state <= IDLE;

        else 
			state <= n_state;
    end

	// FSM
	always @(*)
    begin
        case (state)
            IDLE :
            begin
                if (low_state)
                    n_state <= LOW;

				else if (high_state)
					n_state <= HIGH;

                else
                    n_state <= IDLE;
            end

			LOW :
            begin
				if (i_sw_intr_clear)
					n_state <= IDLE;

                else if (i_ro_enc_state_a)
                    n_state <= CW;

				else if (i_ro_enc_state_b)
					n_state <= CCW;

                else
                    n_state <= LOW;
            end

			HIGH :
            begin
				if (i_sw_intr_clear)
					n_state <= IDLE;

                else if (~i_ro_enc_state_a)
                    n_state <= CW;

				else if (~i_ro_enc_state_b)
					n_state <= CCW;

                else
                    n_state <= HIGH;
            end

			CW :
            begin
				if (i_sw_intr_clear)
					n_state <= IDLE;

                else
                    n_state <= CW;
            end

			CCW :
            begin
				if (i_sw_intr_clear)
					n_state <= IDLE;

                else
                    n_state <= CCW;
            end

			default :
                    n_state <= IDLE;
		endcase
	end

	assign low_state = ~(i_ro_enc_state_a | i_ro_enc_state_b);
	assign high_state = i_ro_enc_state_a & i_ro_enc_state_b;

	assign o_ro_enc_data = state[1:0];

endmodule
