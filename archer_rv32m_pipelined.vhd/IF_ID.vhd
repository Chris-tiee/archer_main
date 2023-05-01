library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity if_id is
    port (
        clk : in std_logic;
        rst_n : in std_logic;
        instruction_in : in std_logic_vector (XLEN-1 downto 0);
        instruction_out : out std_logic_vector (XLEN-1 downto 0);
        funct3: out std_logic_vector (2 downto 0);
        rs1 : out std_logic_vector (4 downto 0);
        rs2 : out std_logic_vector (4 downto 0);
        pcplus4_in: in std_logic_vector (XLEN-1 downto 0);
        pcplus4_out : out std_logic_vector (XLEN-1 downto 0);
        pc_in : in std_logic_vector (XLEN-1 downto 0);
        pc_out : out std_logic_vector (XLEN-1 downto 0);
        PCSrc : in std_logic;
        Stall : in std_logic
    );
end if_id;

architecture rtl of if_id is
begin
    process(clk, rst_n)
    begin

    if (rising_edge(clk) and Stall/='1') then  
        -- To stall literally all I did was add the condition
        -- The PCSrc condition is for flushing in case of branch and jump instructions
        if (PCSrc='1') then 
            instruction_out <= (others=>'0');
            funct3 <=  (others=>'0');
            rs1 <=  (others=>'0');
            rs2 <=  (others=>'0');
            pcplus4_out <=  (others=>'0');
            pc_out <=  (others=>'0');
        else 
            instruction_out <= instruction_in;
            funct3 <= instruction_in(14 downto 12);
            rs1 <= instruction_in(LOG2_XRF_SIZE+14 downto 15);
            rs2 <= instruction_in(LOG2_XRF_SIZE+19 downto 20);
            pcplus4_out <= pcplus4_in;
            pc_out <= pc_in;
        end if;
    end if;
    end process;
end architecture;