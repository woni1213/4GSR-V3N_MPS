`timescale 1 ns / 1 ps

/*

MPS ROtary switch ENcorder Module
개발 4팀 전경원 차장

24.07.25 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - 동작 시방하게 되는데?

1. 개요
 - 

*/

module RO_EN
(
	input i_clk,
	input i_rst,

	input i_ro_en_state_a,
	input i_ro_en_state_b,

	input i_sw_intr_clear,
	output [1:0] o_ro_en_data
);

	parameter IDLE 	= 0;
	parameter CW	= 1;	// a가 변화하면
	parameter CCW	= 2;	// b가 변화하면
	parameter LOW	= 3;	// 00
	parameter HIGH	= 4;	// 11

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

                else if (i_ro_en_state_a)
                    n_state <= CW;

				else if (i_ro_en_state_b)
					n_state <= CCW;

                else
                    n_state <= LOW;
            end

			HIGH :
            begin
				if (i_sw_intr_clear)
					n_state <= IDLE;

                else if (~i_ro_en_state_a)
                    n_state <= CW;

				else if (~i_ro_en_state_b)
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

	assign low_state = ~(i_ro_en_state_a | i_ro_en_state_b);
	assign high_state = i_ro_en_state_a & i_ro_en_state_b;

	assign o_ro_en_data = state[1:0];

endmodule
