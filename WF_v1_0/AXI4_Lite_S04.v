`timescale 1 ns / 1 ps

module AXI4_Lite_S04 #
(
	parameter integer C_S_AXI_DATA_WIDTH	= 0,
	parameter integer C_S_AXI_ADDR_NUM 		= 0,
	parameter integer C_S_AXI_ADDR_WIDTH	= 0
)
(
	// DPBRAM Write
	output reg o_wf_mode_start,
	output reg o_wf_write_en,
	output reg [9:0] o_wf_write_addr,
	output reg [15:0] o_wf_write_data,
	output reg [31:0] o_wf_max_cnt,

	// DPBRAM Read
	input [31:0] i_wf_read_cnt,

	input S_AXI_ACLK,
	input S_AXI_ARESETN,
	input [C_S_AXI_ADDR_WIDTH - 1 : 0] S_AXI_AWADDR,
	input [2:0] S_AXI_AWPROT,
	input S_AXI_AWVALID,
	output S_AXI_AWREADY,
	input [C_S_AXI_DATA_WIDTH - 1 : 0] S_AXI_WDATA,
	input [(C_S_AXI_DATA_WIDTH / 8) - 1 : 0] S_AXI_WSTRB,
	input S_AXI_WVALID,
	output S_AXI_WREADY,
	output [1:0] S_AXI_BRESP,
	output wire S_AXI_BVALID,
	input S_AXI_BREADY,
	input [C_S_AXI_ADDR_WIDTH - 1 : 0] S_AXI_ARADDR,
	input [2 : 0] S_AXI_ARPROT,
	input S_AXI_ARVALID,
	output S_AXI_ARREADY,
	output [C_S_AXI_DATA_WIDTH - 1 : 0] S_AXI_RDATA,
	output [1 : 0] S_AXI_RRESP,
	output S_AXI_RVALID,
	input S_AXI_RREADY
);

	reg [C_S_AXI_ADDR_WIDTH - 1 : 0] axi_awaddr;
	reg axi_awready;
	reg axi_wready;
	reg [1:0] axi_bresp;
	reg axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
	reg axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
	reg [1:0] axi_rresp;
	reg axi_rvalid;

	localparam integer ADDR_LSB = 2;
	localparam integer OPT_MEM_ADDR_BITS = $clog2(C_S_AXI_ADDR_NUM) - 1;

	// slv_reg IO Type Select. 0 : Input, 1 : Output
	// slv_reg Start to LSB
	// 0 : Input, 1 : Output
	localparam [C_S_AXI_ADDR_NUM - 1 : 0] io_sel = 8'b0001_1111;

	reg [C_S_AXI_DATA_WIDTH - 1 : 0] slv_reg[C_S_AXI_ADDR_NUM - 1 : 0];

	wire slv_reg_rden;
	wire slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
	integer byte_index;
	reg aw_en;

	genvar i;
	integer j;

	// Address Write Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_awready <= 1'b0;
			aw_en <= 1'b1;
		end

		else
		begin
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
			begin
				axi_awready <= 1'b1;
				aw_en <= 1'b0;
			end

			else if (S_AXI_BREADY && axi_bvalid)
			begin
				aw_en <= 1'b1;
				axi_awready <= 1'b0;
			end

			else
	          axi_awready <= 1'b0;
	    end 
	end

	// Address Write
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_awaddr <= 0;

		else
		begin
			if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
				axi_awaddr <= S_AXI_AWADDR;
		end

	end

	// Write Data Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_wready <= 1'b0;

		else
		begin
			if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
				axi_wready <= 1'b1;
			else
				axi_wready <= 1'b0;
		end 
	end

	// Write Data (M to S)
	generate
	for (i = 0; i < C_S_AXI_ADDR_NUM; i = i + 1)
	begin
		always @( posedge S_AXI_ACLK )
		begin
		if (io_sel[i])
		begin
			if (S_AXI_ARESETN == 1'b0)
				slv_reg[i] <= 0;

			else if (slv_reg_wren)
				if (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == i)
					for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
						if ( S_AXI_WSTRB[byte_index] == 1 ) 
							slv_reg[i][(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];

			else
				slv_reg[i] <= slv_reg[i];
			end
		end
	end
	endgenerate

	// Response Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_bvalid  <= 0;
			axi_bresp   <= 2'b0;
		end

		else
		begin
			if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
			begin
				axi_bvalid <= 1'b1;
				axi_bresp  <= 2'b0;
			end

			else
			begin
				if (S_AXI_BREADY && axi_bvalid) 
					axi_bvalid <= 1'b0; 
			end
		end
	end

	// Address Read Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_arready <= 1'b0;
			axi_araddr  <= 32'b0;
		end

		else
		begin
			if (~axi_arready && S_AXI_ARVALID)
			begin
				axi_arready <= 1'b1;
				axi_araddr  <= S_AXI_ARADDR;
			end

			else
				axi_arready <= 1'b0;
		end
	end

	// Read Data Flag
	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
		begin
			axi_rvalid <= 0;
			axi_rresp  <= 0;
		end 

		else
		begin
			if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
			begin
				axi_rvalid <= 1'b1;
				axi_rresp  <= 2'b0;
			end

			else if (axi_rvalid && S_AXI_RREADY)
				axi_rvalid <= 1'b0;
		end
	end

	// Read Data (S to M)
	always @(*)
	begin
		reg_data_out = 0;

		for (j = 0; j < C_S_AXI_ADDR_NUM; j = j + 1)
			if (axi_araddr[ADDR_LSB + OPT_MEM_ADDR_BITS : ADDR_LSB] == j)
				reg_data_out = slv_reg[j];
	end

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
			axi_rdata  <= 0;

		else
		begin
			if (slv_reg_rden)
				axi_rdata <= reg_data_out;
		end
	end

	// Input
	always @(posedge S_AXI_ACLK)
	begin
		slv_reg[5]			<= i_wf_read_cnt;
	end

	// Output
	always @(posedge S_AXI_ACLK)
	begin
		o_wf_mode_start		<= slv_reg[0];			// PS에서 Waveform Mode를 시작하려면 1로 설정해야 함
		o_wf_write_en		<= slv_reg[1];			// PS에서 Waveform data를 줄 때 1로 설정해야 함
		o_wf_write_addr		<= slv_reg[2];
		o_wf_write_data		<= slv_reg[3];
		o_wf_max_cnt		<= slv_reg[4];
	end

	assign S_AXI_AWREADY = axi_awready;
	assign S_AXI_WREADY = axi_wready;
	assign S_AXI_BRESP = axi_bresp;
	assign S_AXI_BVALID = axi_bvalid;
	assign S_AXI_ARREADY = axi_arready;
	assign S_AXI_RDATA = axi_rdata;
	assign S_AXI_RRESP = axi_rresp;
	assign S_AXI_RVALID = axi_rvalid;

	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	
endmodule