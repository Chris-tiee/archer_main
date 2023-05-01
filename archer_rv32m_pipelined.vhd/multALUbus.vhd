library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity multALUbus is
    port (
        clk : in std_logic;
        MExt_in : in std_logic;
        inputA_in: in std_logic_vector (XLEN-1 downto 0);
        inputB_in: in std_logic_vector (XLEN-1 downto 0);
        ALUOp_in : in std_logic_vector (4 downto 0);
        instruction_in: in std_logic_vector (XLEN-1 downto 0);
        MExt_out : out std_logic;
        inputA_out: out std_logic_vector (XLEN-1 downto 0);
        inputB_out: out std_logic_vector (XLEN-1 downto 0);
        ALUOp_out : out std_logic_vector (4 downto 0);
        instruction_out: out std_logic_vector (XLEN-1 downto 0)
    );
end multALUbus;

architecture rtl of multALUbus is
begin
    process(clk, MExt_in)
    begin
    if rising_edge(clk) then
        MExt_out <= MExt_in;
        inputA_out <= inputA_in;
        inputB_out <= inputB_in;
        ALUOp_out <= ALUOp_in;
        instruction_out <= instruction_in;
    end if;
    end process;
    
end architecture;