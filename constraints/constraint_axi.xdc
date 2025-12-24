## AXI Clock (100 MHz = 10 ns)
create_clock -name s00_axi_aclk -period 10.000 [get_ports s00_axi_aclk]

## AXI clock uncertainty (recommended)
set_clock_uncertainty 0.1 [get_clocks s00_axi_aclk]
