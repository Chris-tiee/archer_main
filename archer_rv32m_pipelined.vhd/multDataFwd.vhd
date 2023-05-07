library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity multDataFwd is
    port (
        clk : in std_logic;
        MExt : in std_logic;
        instruction_in : in std_logic_vector (XLEN-1 downto 0);
        rd_EX : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        rd_MEM: in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        MemToReg_MEM : in std_logic;
        RegWrite_MEM : in std_logic;
        Jump_MEM : in std_logic;
        rd_WB: in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        RegWrite_WB : in std_logic;
        regA : out  std_logic_vector (1 downto 0);
        regB : out std_logic_vector (1 downto 0);
        stall : out std_logic
    );
end multDataFwd;

architecture rtl of multDataFwd is

    signal rs1 : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
    signal rs2 : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
    signal opcode : std_logic_vector (6 downto 0);

begin

    process(clk, instruction_in, rd_EX, MemToReg_MEM, Jump_MEM, RegWrite_MEM, rd_MEM, rd_WB, RegWrite_WB) is
    begin
        stall <='0';
        regA <="00";
        regB <="00";
        rs1 <= instruction_in(LOG2_XRF_SIZE+14 downto 15);
        rs2 <= instruction_in(LOG2_XRF_SIZE+19 downto 20);
        opcode <= instruction_in (6 downto 0);
        if rd_EX/="00000" and MExt='1' then

            if opcode/=OPCODE_LUI and opcode/=OPCODE_AUIPC and opcode/=OPCODE_JAL then
                -- condition when not load and depends on instr in MEM
                if (rs1 = rd_MEM and MemToReg_MEM/='1' and Jump_MEM/='1' and RegWrite_MEM='1') then
                    regA<= "01";
                -- condition when not load and depends on instr in WB
                elsif (rs1 = rd_WB and RegWrite_WB='1') then 
                    regA <= "10";
                -- condition when load in MEM
                elsif (rs1 = rd_MEM and (MemToReg_MEM='1' or Jump_MEM='1') and RegWrite_MEM='1') then
                    stall <= '1';
                end if;
            end if;

            if opcode=OPCODE_BRANCH or opcode=OPCODE_STORE or opcode=OPCODE_RTYPE then
                -- condition when not load and depends on instr in MEM
                if (rs2 = rd_MEM and MemToReg_MEM/='1' and Jump_MEM/='1' and RegWrite_MEM='1') then
                    regB<= "01";
                -- condition when not load and depends on instr in WB
                elsif (rs2 = rd_WB and RegWrite_MEM='1') then 
                    regB <= "10";
                -- condition when load in MEM
                elsif (rs2 = rd_MEM and (MemToReg_MEM='1' or Jump_MEM='1') and RegWrite_MEM='1') then
                    stall <= '1';
                end if;
            end if;
            
        end if;
    end process;   

end architecture;