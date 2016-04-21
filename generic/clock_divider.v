/* clock_divider.v

	DigitalCold's ARM Challenge VGA Implementation
		Freefull's graphics demo reimplemented on the BASYS2 hardware.
		Additional information at http://io.smashthestack.org/arm/digitalcold/
		All Verilog code written by DigitalCold (sorry for all the warnings).
		
	Released 4/25/13
*/

module clock_divider(clk_in, clk_out);
	input clk_in;
	output clk_out;
	
	reg clk_out = 0;
	
	always @(posedge clk_in)
		clk_out <= ~clk_out;
		
endmodule
