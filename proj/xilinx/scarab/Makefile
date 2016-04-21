project = digitalcold
vendor = xilinx
family = spartan6
part = xc6slx25-ftg256-3 # last number -3 is speed grade
flashsize = 8192 # KB (kilobytes) - SPI flash device is M25P40
top_module = top
isedir = /opt/Xilinx/ISE/14.7/ISE_DS
xil_env = . $(isedir)/settings64.sh
SHELL = /bin/bash
# openocd_interface = interface/altera-usb-blaster.cfg
# openocd_interface = ../include/ft2232-fpu1.ocd
openocd_interface = ../include/ft2232-generic.ocd
xc3sprog_interface = ftdi

vfiles = \
../../../generic/top.v \
../../../generic/caleidoscope.v \
../../../generic/vga_driver.v \
../../../generic/vga_tb.v \
../../../generic/clock_shift.v \
../../../generic/clock_divider.v \
../../../generic/clock_divider_tb.v \
../../../soc/vgahdmi/tmds_encoder_v.v \
../../../soc/vgahdmi/vga2hdmi.v \

vhdfiles = \
../../../xilinx/scarab/clocks/pll_50M_100M_25M_250M.vhd  \
../../../xilinx/chip/xc6/hdmi_out_xc6.vhd \
../../../generic/edge_enhance.vhd \
../../../generic/line_delay.vhd \

include ../include/xilinx.mk
