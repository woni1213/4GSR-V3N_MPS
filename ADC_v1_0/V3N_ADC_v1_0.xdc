# SOM240_2 Connector Pinout

set_property -dict { PACKAGE_PIN AH8	IOSTANDARD LVCMOS18 } [get_ports mosi_0];			# MSDADC0A
set_property -dict { PACKAGE_PIN AF7	IOSTANDARD LVCMOS18 } [get_ports i_v_adc_busy_0];	# MBYADCA
set_property -dict { PACKAGE_PIN AE8	IOSTANDARD LVCMOS18 } [get_ports n_cs_0];   		# MCSADCA~
set_property -dict { PACKAGE_PIN AB8	IOSTANDARD LVCMOS18 } [get_ports spi_clk_0];   		# MSKADCA
set_property -dict { PACKAGE_PIN AC8	IOSTANDARD LVCMOS18 } [get_ports miso_0];   		# MSCADCA
set_property -dict { PACKAGE_PIN AE9	IOSTANDARD LVCMOS18 } [get_ports o_v_c_adc_cnv_0];	# MSTADCA

set_property -dict { PACKAGE_PIN AC4	IOSTANDARD LVCMOS18 } [get_ports mosi_1];   		# MSDADC0B
set_property -dict { PACKAGE_PIN AF6	IOSTANDARD LVCMOS18 } [get_ports i_c_adc_busy_0];  	# MBYADCB
set_property -dict { PACKAGE_PIN AE7	IOSTANDARD LVCMOS18 } [get_ports n_cs_1];   		# MCSADCB~
set_property -dict { PACKAGE_PIN AB7	IOSTANDARD LVCMOS18 } [get_ports spi_clk_1];   		# MSKADCB
set_property -dict { PACKAGE_PIN AC7	IOSTANDARD LVCMOS18 } [get_ports miso_1];   		# MSCADCB
set_property -dict { PACKAGE_PIN AD7	IOSTANDARD LVCMOS18 } [get_ports o_v_c_adc_cnv_1];	# MSTADCB

set_property -dict { PACKAGE_PIN J11	IOSTANDARD LVCMOS33 } [get_ports i_dc_adc_rvs_0];	# RVADCC
set_property -dict { PACKAGE_PIN J10	IOSTANDARD LVCMOS33 } [get_ports mosi_2];			# SDADCC
set_property -dict { PACKAGE_PIN K13	IOSTANDARD LVCMOS33 } [get_ports spi_clk_2];		# SKADCC
set_property -dict { PACKAGE_PIN K12	IOSTANDARD LVCMOS33 } [get_ports o_dc_adc_cnv_0];	# CSADCC~
set_property -dict { PACKAGE_PIN E12	IOSTANDARD LVCMOS33 } [get_ports miso_2];			# SCADCC

set_property -dict { PACKAGE_PIN AG8	IOSTANDARD LVCMOS18 } [get_ports o_adc_ext_rst_0];	# MMRADCS~