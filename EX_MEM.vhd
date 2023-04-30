library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity ex_mem is
    port (
        clk : in std_logic;
        rst_n : in std_logic;

        instruction_in : in std_logic_vector (XLEN-1 downto 0);
        instruction_out : out std_logic_vector (XLEN-1 downto 0);
        byte_mask : out std_logic_vector (1 downto 0);
        sign_ext_n : out std_logic;
        pcplus4_in: in std_logic_vector (XLEN-1 downto 0);
        pcplus4_out : out std_logic_vector (XLEN-1 downto 0);

        Nop : in std_logic;

        alu_in : in std_logic_vector (XLEN-1 downto 0);
        alu_out : out std_logic_vector (XLEN-1 downto 0);
        regB_in : in std_logic_vector (XLEN-1 downto 0);
        regB_out : out std_logic_vector (XLEN-1 downto 0);
       
        Jump_in : in std_logic;
        RegWrite_in : in std_logic;
        MemWrite_in : in std_logic;
        MemRead_in : in std_logic;
        MemToReg_in : in std_logic;
        CSRWen_in : in std_logic; 

        Jump_out : out std_logic;
        RegWrite_out : out std_logic;
        MemWrite_out : out std_logic;
        MemRead_out : out std_logic;
        MemToReg_out : out std_logic;
        CSRWen_out : out std_logic
    );
end ex_mem;

architecture rtl of ex_mem is
begin
    process(clk, rst_n)
    begin
    if rising_edge(clk) then 
        if (Nop='1') then 
            instruction_out <= (others=>'0');
            byte_mask <= (others=>'0');
            sign_ext_n <= '0';
            alu_out <= (others=>'0');
            regB_out <= (others=>'0');
            pcplus4_out <= (others=>'0');

            Jump_out <= '0';
            RegWrite_out <= '0';
            MemWrite_out <= '0';
            MemRead_out <= '0';
            MemToReg_out <= '0';
            CSRWen_out <= '0';
        else
            instruction_out <= instruction_in;
            byte_mask <= instruction_in(13 downto 12);
            sign_ext_n <= instruction_in(14);
            alu_out <= alu_in;
            regB_out <= regB_in;
            pcplus4_out <= pcplus4_in;

            Jump_out <= Jump_in;
            RegWrite_out <= RegWrite_in;
            MemWrite_out <= MemWrite_in;
            MemRead_out <= MemRead_in;
            MemToReg_out <= MemToReg_in;
            CSRWen_out <= CSRWen_in;
        end if;

    end if;
    end process;
end architecture;