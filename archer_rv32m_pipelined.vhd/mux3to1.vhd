-- 3-to-1 XLEN-bit multiplexer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity mux3to1 is
    port (
        sel : in std_logic_vector(1 downto 0);
        input00 : in std_logic_vector (XLEN-1 downto 0);
        input01 : in std_logic_vector (XLEN-1 downto 0);
        input10 : in std_logic_vector (XLEN-1 downto 0);
        output : out std_logic_vector (XLEN-1 downto 0)
    );
end mux3to1;

architecture rtl of mux3to1 is
begin
    output <=   input00 when sel = "00" else 
                input01 when sel = "01" else
                input10 when sel = "10" else
                (others=>'0');
end architecture;