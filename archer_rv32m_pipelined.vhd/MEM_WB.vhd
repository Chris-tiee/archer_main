library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity mem_wb is
    port (
        clk : in std_logic;
        rst_n : in std_logic;

        instruction_in : in std_logic_vector (XLEN-1 downto 0);
        instruction_out : out std_logic_vector (XLEN-1 downto 0);
        pcplus4_in: in std_logic_vector (XLEN-1 downto 0);
        pcplus4_out : out std_logic_vector (XLEN-1 downto 0);

        alu_in : in std_logic_vector (XLEN-1 downto 0);
        alu_out : out std_logic_vector (XLEN-1 downto 0);
        mem_in: in std_logic_vector (XLEN-1 downto 0);
        mem_out: out std_logic_vector (XLEN-1 downto 0);

        rd_in: in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        rd_out: out std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
       
        Jump_in : in std_logic;
        RegWrite_in : in std_logic;
        MemToReg_in : in std_logic;
        CSRWen_in : in std_logic; 

        Jump_out : out std_logic;
        RegWrite_out : out std_logic;
        MemToReg_out : out std_logic;
        CSRWen_out : out std_logic
    );
end mem_wb;

architecture rtl of mem_wb is
begin
    process(clk, rst_n)
    begin
    if rst_n='0' then 
        instruction_out <= (others=>'0'); 
        pcplus4_out <= (others=>'0');
        rd_out <= (others=>'0');

        alu_out <= (others=>'0');
        mem_out <= (others=>'0');
        
        Jump_out <= '0';
        RegWrite_out <= '0';
        MemToReg_out <= '0';
        CSRWen_out <= '0';
    elsif rising_edge(clk) then  

        instruction_out <= instruction_in;   
        pcplus4_out <= pcplus4_in;
        rd_out <=rd_in;

        alu_out <= alu_in;
        mem_out <= mem_in;
        
        Jump_out <= Jump_in;
        RegWrite_out <= RegWrite_in;
        MemToReg_out <= MemToReg_in;
        CSRWen_out <= CSRWen_in;

    end if;
    end process;
end architecture;