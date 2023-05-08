library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity dataForwarding is
    port (
        clk : in std_logic;
        rs1 : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        rs2 : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        rd_EX : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        instruction : in std_logic_vector (XLEN-1 downto 0);
        instruction_mult : in std_logic_vector (XLEN-1 downto 0);
        MExt : in std_logic;
        rd_mult_EX : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        rd_MEM: in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        MemToReg_MEM : in std_logic;
        RegWrite_MEM : in std_logic;
        Jump_MEM : in std_logic;
        rd_WB: in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        RegWrite_WB : in std_logic;
        regA : out  std_logic_vector (1 downto 0);
        regB : out std_logic_vector (1 downto 0);
        regA_mult : out  std_logic_vector (1 downto 0);
        regB_mult : out std_logic_vector (1 downto 0);
        stall : out std_logic
    );
end dataForwarding;

architecture rtl of dataForwarding is
    signal opcode : std_logic_vector (6 downto 0);
    signal opcode_mult : std_logic_vector (6 downto 0);
    signal rs1_mult : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
    signal rs2_mult : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
begin

    process(clk, rs1, rs2, rd_EX, MemToReg_MEM, Jump_MEM, RegWrite_MEM, rd_MEM, rd_WB, RegWrite_WB) is
    begin

        opcode <= instruction (6 downto 0);
        opcode_mult <= instruction_mult (6 downto 0);
        rs1_mult <= instruction_mult(LOG2_XRF_SIZE+14 downto 15);
        rs2_mult <= instruction_mult(LOG2_XRF_SIZE+19 downto 20);
        stall <='0';
        regA <="00";
        regB <="00";
        regA_mult <="00";
        regB_mult <="00";

        if rd_EX/="00000" then

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
                elsif (rs2 = rd_WB and RegWrite_WB='1') then 
                    regB <= "10";
                -- condition when load in MEM
                elsif (rs2 = rd_MEM and (MemToReg_MEM='1' or Jump_MEM='1') and RegWrite_MEM='1') then
                    stall <= '1';
                end if;
            end if;
            
        end if;

        if rd_mult_EX/="00000" and MExt='1' then
             
             if opcode_mult/=OPCODE_LUI and opcode_mult/=OPCODE_AUIPC and opcode_mult/=OPCODE_JAL then
                -- condition when not load and depends on instr in MEM
                if (rs1_mult = rd_MEM and MemToReg_MEM/='1' and Jump_MEM/='1' and RegWrite_MEM='1') then
                    regA_mult<= "01";
                -- condition when not load and depends on instr in WB
                elsif (rs1_mult = rd_WB and RegWrite_WB='1') then 
                    regA_mult <= "10";
                -- condition when load in MEM
                elsif (rs1_mult = rd_MEM and (MemToReg_MEM='1' or Jump_MEM='1') and RegWrite_MEM='1') then
                    stall <= '1';
                end if;
            end if;

            if opcode_mult=OPCODE_BRANCH or opcode_mult=OPCODE_STORE or opcode_mult=OPCODE_RTYPE then
                -- condition when not load and depends on instr in MEM
                if (rs2_mult = rd_MEM and MemToReg_MEM/='1' and Jump_MEM/='1' and RegWrite_MEM='1') then
                    regB_mult<= "01";
                -- condition when not load and depends on instr in WB
                elsif (rs2_mult = rd_WB and RegWrite_MEM='1') then 
                    regB_mult <= "10";
                -- condition when load in MEM
                elsif (rs2_mult = rd_MEM and (MemToReg_MEM='1' or Jump_MEM='1') and RegWrite_MEM='1') then
                    stall <= '1';
                end if;
            end if;

        end if;
    end process;   

end architecture;