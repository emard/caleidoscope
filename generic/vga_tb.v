/* vga_tb.v - Testbench to verify VGA timing

	DigitalCold's ARM Challenge VGA Implementation
		Freefull's graphics demo reimplemented on the BASYS2 hardware.
		Additional information at http://io.smashthestack.org/arm/digitalcold/
		All Verilog code written by DigitalCold (sorry for all the warnings).
		
	Released 4/25/13
*/

module vga_tb;

	// Inputs
	reg CLK_50MHz;

	// Outputs
	wire VS;
	wire HS;
	wire [2:0] RED;
	wire [2:0] GREEN;
	wire [1:0] BLUE;

	// Instantiate the Unit Under Test (UUT)
	vga_driver uut (
		.CLK_50MHz(CLK_50MHz), 
		.VS(VS), 
		.HS(HS), 
		.RED(RED), 
		.GREEN(GREEN), 
		.BLUE(BLUE)
	);

	initial begin
		// Initialize Inputs
		CLK_50MHz = 0;

		while(1) #1 CLK_50MHz = ~CLK_50MHz;
	end
      
endmodule

