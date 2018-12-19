PROJECT = caleidoscope

FPGA_SIZE = 85

CONSTRAINTS=ulx3s_v20_segpdi.lpf

TOP_MODULE = top
# design files
VERILOG_FILES = \
  top/top.v \
  clocks/clock.v \
  ../../../../generic/caleidoscope.v \
  ../../../../generic/vga_driver.v \
  ../../../../soc/vgahdmi/OBUFDS.v \
  ../../../../soc/vgahdmi/tmds_encoder_v.v \
  ../../../../soc/vgahdmi/DVI_test.v
  
# list of files with .v extension for conversion to verilog .vhd -> .v
VHDL_TO_VERILOG_FILES = \
  ../../../../soc/vgahdmi/vga2hdmi_ddr.v \

include ../../include/trellis/makefile
