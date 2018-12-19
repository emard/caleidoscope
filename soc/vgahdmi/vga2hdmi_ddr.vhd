--------------------------------------------------------------------------------
-- Engineer:		Mike Field <hamster@snap.net.nz>
-- Description:	Converts VGA signals into DVID bitstreams.
--
--	'clk' should be 5x clk_pixel.
--
--	'blank' should be asserted during the non-display 
--	portions of the frame
--------------------------------------------------------------------------------
-- See: http://hamsterworks.co.nz/mediawiki/index.php/Dvid_test
--		http://hamsterworks.co.nz/mediawiki/index.php/FPGA_Projects
--
-- Copyright (c) 2012 Mike Field <hamster@snap.net.nz>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vga2hdmi_ddr is
	Generic (
		C_depth	: integer := 8
	);
	Port (
		clk       : in	STD_LOGIC;
		clk_pixel : in	STD_LOGIC;
		red_p     : in	STD_LOGIC_VECTOR (C_depth-1 downto 0);
		green_p   : in	STD_LOGIC_VECTOR (C_depth-1 downto 0);
		blue_p    : in	STD_LOGIC_VECTOR (C_depth-1 downto 0);
		blank     : in	STD_LOGIC;
		hsync     : in	STD_LOGIC;
		vsync     : in	STD_LOGIC;
		red_ddr	  : out STD_LOGIC_VECTOR(1 downto 0);
		green_ddr : out STD_LOGIC_VECTOR(1 downto 0);
		blue_ddr  : out STD_LOGIC_VECTOR(1 downto 0);
		clock_ddr : out STD_LOGIC_VECTOR(1 downto 0)
	);
end vga2hdmi_ddr;

architecture Behavioral of vga2hdmi_ddr is

	signal encoded_red, encoded_green, encoded_blue : std_logic_vector(9 downto 0);
	signal latched_red, latched_green, latched_blue : std_logic_vector(9 downto 0) := (others => '0');
	signal shift_red,	shift_green,	shift_blue	: std_logic_vector(9 downto 0) := (others => '0');
	
	signal shift_clock	: std_logic_vector(9 downto 0) := "0000011111";

	constant c_red		: std_logic_vector(1 downto 0) := (others => '0');
	constant c_green	: std_logic_vector(1 downto 0) := (others => '0');
	signal	c_blue		: std_logic_vector(1 downto 0);

	signal	red_d	: STD_LOGIC_VECTOR (7 downto 0);
	signal	green_d	: STD_LOGIC_VECTOR (7 downto 0);
	signal	blue_d	: STD_LOGIC_VECTOR (7 downto 0);
begin	
	c_blue <= vsync & hsync;
	
	red_d(7 downto 8-C_depth)	<= red_p(C_depth-1 downto 0);
	green_d(7 downto 8-C_depth)	<= green_p(C_depth-1 downto 0);
	blue_d(7 downto 8-C_depth)	<= blue_p(C_depth-1 downto 0);
	-- fill vacant low bits with value repeated (so min/max value is always 0 or 255)
	G_bits:
	for i in 8-C_depth-1 downto 0
	generate
		red_d(i)	<= red_p(0);
		green_d(i)	<= green_p(0);
		blue_d(i)	<= blue_p(0);
	end generate;
	
	enc_r : tmds_encoder_v PORT MAP(clk => clk_pixel, VD => red_d,   CD => c_red,   BLANK => blank, TMDS => encoded_red);
	enc_g : tmds_encoder_v PORT MAP(clk => clk_pixel, VD => green_d, CD => c_green, BLANK => blank, TMDS => encoded_green);
	enc_b : tmds_encoder_v PORT MAP(clk => clk_pixel, VD => blue_d,  CD => c_blue,  BLANK => blank, TMDS => encoded_blue);

	-- output ready for DDR vendor primitives
	red_ddr   <= shift_red(1 downto 0);
	green_ddr <= shift_green(1 downto 0);
	blue_ddr  <= shift_blue(1 downto 0);
	clock_ddr <= shift_clock(1 downto 0);

	process(clk_pixel)
	begin
		if rising_edge(clk_pixel) then 
			latched_red	<= encoded_red;
			latched_green <= encoded_green;
			latched_blue	<= encoded_blue;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then 
		if shift_clock = "0000011111" then
			shift_red	<= latched_red;
			shift_green <= latched_green;
			shift_blue	<= latched_blue;
		else
			shift_red	<= "00" & shift_red	(9 downto 2);
			shift_green <= "00" & shift_green(9 downto 2);
			shift_blue	<= "00" & shift_blue (9 downto 2);
		end if;
		shift_clock <= shift_clock(1 downto 0) & shift_clock(9 downto 2);
		end if;
	end process;
	
end Behavioral;
