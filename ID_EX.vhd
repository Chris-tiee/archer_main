library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity id_ex is
    port (
        clk : in std_logic;
        rst_n : in std_logic;

        instruction_in : in std_logic_vector (XLEN-1 downto 0);
        instruction_out : out std_logic_vector (XLEN-1 downto 0);
        regA_in : in std_logic_vector (XLEN-1 downto 0);
        regB_in : in std_logic_vector (XLEN-1 downto 0);
        regA_out : out std_logic_vector (XLEN-1 downto 0);
        regB_out : out std_logic_vector (XLEN-1 downto 0);
        immediate_in : in std_logic_vector (XLEN-1 downto 0);
        immediate_out : out std_logic_vector (XLEN-1 downto 0);
        pcplus4_in: in std_logic_vector (XLEN-1 downto 0);
        pcplus4_out : out std_logic_vector (XLEN-1 downto 0);
        pc_in : in std_logic_vector (XLEN-1 downto 0);
        pc_out : out std_logic_vector (XLEN-1 downto 0);
        Stall : in std_logic;

       
        Jump_in : in std_logic;
        Lui_in : in std_logic;
        RegWrite_in : in std_logic;
        ALUSrc1_in : in std_logic;
        ALUSrc2_in : in std_logic;
        ALUOp_in : in std_logic_vector (4 downto 0);
        MemWrite_in : in std_logic;
        MemRead_in : in std_logic;
        MemToReg_in : in std_logic;
        CSRWen_in : in std_logic; -- write enable checks if rs1=x0
	    CSR_in : in std_logic; -- is it a CSR  
        MExt_in : in std_logic; 

        Jump_out : out std_logic;
        Lui_out : out std_logic;
        RegWrite_out : out std_logic;
        ALUSrc1_out : out std_logic;
        ALUSrc2_out : out std_logic;
        ALUOp_out : out std_logic_vector (4 downto 0);
        MemWrite_out : out std_logic;
        MemRead_out : out std_logic;
        MemToReg_out : out std_logic;
        CSRWen_out : out std_logic; -- write enable checks if rs1=x0
	    CSR_out : out std_logic; -- is it a CSR   
        MExt_out :  out std_logic
    );
end id_ex;

architecture rtl of id_ex is
begin
    process(clk, rst_n)
    begin
    if (rising_edge(clk) and Stall/='1') then   
        instruction_out <= instruction_in;
        regA_out <= regA_in;
        regB_out <= regB_in;
        immediate_out <= immediate_in;
        pcplus4_out <= pcplus4_in;
        pc_out <= pc_in;

        Jump_out <= Jump_in;
        Lui_out <= Lui_in;
        RegWrite_out <= RegWrite_in;
        ALUSrc1_out <= ALUSrc1_in;
        ALUSrc2_out <= ALUSrc2_in;
        ALUOp_out <= ALUOp_in;
        MemWrite_out <= MemWrite_in;
        MemRead_out <= MemRead_in;
        MemToReg_out <= MemToReg_in;
        CSRWen_out <= CSRWen_in;
        CSR_out <= CSR_in;  
        MExt_out <= MExt_in;   
    end if;
    end process;
end architecture;