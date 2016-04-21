/* clock_shift.v - shifts the clk_in by half of the period

	DigitalCold's ARM Challenge VGA Implementation
		Freefull's graphics demo reimplemented on the BASYS2 hardware.
		Additional information at http://io.smashthestack.org/arm/digitalcold/
		All Verilog code written by DigitalCold (sorry for all the warnings).
		
	Released 4/25/13
*/

module clock_shift(clk_in, clk_out);
	input clk_in;
	output clk_out;

	assign clk_out = ~clk_in;
endmodule
