`timescale 1 ns / 1 ps

/*

MPS SFP Reset Module
개발 4팀 전경원 차장

24.08.20 :	최초 생성

이성진 차장의 퇴사로 인하여 MPS PL 프로그래밍

0. 기타
 - Datasheet 60 Page 참조

1. 개요
 - https://www.notion.so/Aurora-64B66B-SFP-94b20ca79cf949f187575ade0d66bebc

*/

module SFP_RST_v1_0_Top
(
	input aurora_axis_aclk,
	input aurora_axis_aresetn,

	output reg reset_pb,
	output reg pma_init,

	output o_aurora_init_flag
);

	reg [27:0] cnt;

	always @(posedge aurora_axis_aclk or negedge aurora_axis_aresetn)
	begin
		if (!aurora_axis_aresetn)
			cnt <= 0;

		else if (cnt == 260_000_000)
			cnt <= cnt;

		else
			cnt <= cnt + 1;
	end
		
	always @(posedge aurora_axis_aclk or negedge aurora_axis_aresetn)
	begin
		if (!aurora_axis_aresetn)
			reset_pb <= 0;

		else if (cnt == 100)
			reset_pb <= 1;

		else if (cnt > 200_100_000)
			reset_pb <= 0;

		else
			reset_pb <= reset_pb;
	end

	always @(posedge aurora_axis_aclk or negedge aurora_axis_aresetn)
	begin
		if (!aurora_axis_aresetn)
			pma_init <= 0;

		else if (cnt == 300)
			pma_init <= 1;

		else if (cnt == 200_050_000)
			pma_init <= 0;

		else
			pma_init <= pma_init;
	end

	assign o_aurora_init_flag = (cnt > 200_200_000);

endmodule