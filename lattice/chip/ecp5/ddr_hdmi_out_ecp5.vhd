--------------------------------------------------------------------------------
-- Engineer:		Mike Field <hamster@snap.net.nz>
-- Description:	Converts VGA signals into DVID bitstreams.
--
--	'clk' and 'clk_n' should be 5x clk_pixel.
--
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

library ecp5u;
use ecp5u.components.all;

entity ddr_hdmi_out_ecp5 is
	Port (
		clk	  : in	STD_LOGIC; -- positive clock 125MHz (phase 0)
		-- input hdmi data for DDR out
		red_ddr	  : in STD_LOGIC_VECTOR(1 downto 0);
		green_ddr : in STD_LOGIC_VECTOR(1 downto 0);
		blue_ddr  : in STD_LOGIC_VECTOR(1 downto 0);
		clock_ddr : in STD_LOGIC_VECTOR(1 downto 0);
		-- DDR out suitable for external hardware drivers
		gpdi_dp, gpdi_dn : out STD_LOGIC_VECTOR(3 downto 0)
	);
end;

architecture Behavioral of ddr_hdmi_out_ecp5 is
      signal S_ddr_red, S_ddr_green, S_ddr_blue, S_ddr_clock: std_logic;
begin	
      -- DDR vendor primitives
      gpdi_ddr_clock: ODDRX1F port map(D0=>clock_ddr(0), D1=>clock_ddr(1), Q=>S_ddr_clock, SCLK=>clk, RST=>'0');
      gpdi_diff_clock: OLVDS port map(A => S_ddr_clock, Z => gpdi_dp(3), ZN => gpdi_dn(3));

      gpdi_ddr_red: ODDRX1F port map(D0=>red_ddr(0), D1=>red_ddr(1), Q=>S_ddr_red, SCLK=>clk, RST=>'0');
      gpdi_diff_red: OLVDS port map(A => S_ddr_red, Z => gpdi_dp(2), ZN => gpdi_dn(2));

      gpdi_ddr_green: ODDRX1F port map(D0=>green_ddr(0), D1=>green_ddr(1), Q=>S_ddr_green, SCLK=>clk, RST=>'0');
      gpdi_diff_green: OLVDS port map(A => S_ddr_green, Z => gpdi_dp(1), ZN => gpdi_dn(1));

      gpdi_ddr_blue: ODDRX1F port map(D0=>blue_ddr(0), D1=>blue_ddr(1), Q=>S_ddr_blue, SCLK=>clk, RST=>'0');
      gpdi_diff_blue: OLVDS port map(A => S_ddr_blue, Z => gpdi_dp(0), ZN => gpdi_dn(0));

end Behavioral;
