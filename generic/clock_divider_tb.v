/* clock_divider_tb.v - A quick testbench to clock shifting

	DigitalCold's ARM Challenge VGA Implementation
		Freefull's graphics demo reimplemented on the BASYS2 hardware.
		Additional information at http://io.smashthestack.org/arm/digitalcold/
		All Verilog code written by DigitalCold (sorry for all the warnings).
		
	Released 4/25/13
*/

module clock_divider_tb;

	// Inputs
	reg clk_in;

	// Outputs
	wire clk_out;

	// Instantiate the Unit Under Test (UUT)
	clock_divider uut (
		.clk_in(clk_in), 
		.clk_out(clk_out)
	);

	initial begin
		// Initialize Inputs
		clk_in = 0;

		while(1) #1 clk_in = ~clk_in;
	end

endmodule
