--
-- SPDX-License-Identifier: CERN-OHL-P-2.0+
--
-- Copyright (C) 2021 Embedded and Reconfigurable Computing Lab, American University of Beirut
-- Contributed by:
-- Mazen A. R. Saghir <mazen@aub.edu.lb>
--
-- This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
-- INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR
-- A PARTICULAR PURPOSE. Please see the CERN-OHL-P v2 for applicable
-- conditions.
-- Source location: https://github.com/ERCL-AUB/archer/rv32i_single_cycle
--
-- Main control unit

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use work.archer_pkg.all;

entity control is
  port (
    instruction : in std_logic_vector (XLEN-1 downto 0);
    BranchCond : in std_logic; -- BR. COND. SATISFIED = 1; NOT SATISFIED = 0
    MStall : in std_logic; -- stalling to simulate 5cc 
    Jump : out std_logic;
    Lui : out std_logic;
    PCSrc : out std_logic;
    RegWrite : out std_logic;
    ALUSrc1 : out std_logic;
    ALUSrc2 : out std_logic;
    ALUOp : out std_logic_vector (4 downto 0);
    MemWrite : out std_logic;
    MemRead : out std_logic;
    MemToReg : out std_logic;
    CSRWen : out std_logic; -- write enable checks if rs1=x0
    CSR : out std_logic; -- is it a CSR
    Stall : out std_logic;
    Nop : out std_logic;
    MExt : out std_logic -- if from M extension 

  ) ;
end control ; 

architecture arch of control is
    signal opcode : std_logic_vector (6 downto 0);
    signal funct3 : std_logic_vector (2 downto 0);
    signal funct7 : std_logic_vector (6 downto 0);
    signal rs1 : std_logic_vector (4 downto 0);
    signal branch_instr : std_logic;
    signal jump_instr : std_logic;
begin

  opcode <= instruction (6 downto 0);
  funct3 <= instruction (14 downto 12);
  funct7 <= instruction (31 downto 25);
  rs1 <= instruction (LOG2_XRF_SIZE+14 downto 15);

  branch_instr <= '1' when opcode = OPCODE_BRANCH else '0';
  jump_instr <= '1' when ((opcode = OPCODE_JAL) or (opcode = OPCODE_JALR)) else '0';

  PCSrc <= (branch_instr and BranchCond) or jump_instr;

  Jump <= jump_instr;

  process (opcode, funct3, funct7, MStall) is
  begin

    Lui <= '0';
    RegWrite <= '0';
    ALUSrc1 <= '0';
    ALUSrc2 <= '0';
    ALUOp <= (others=>'0');
    MemWrite <= '0';
    MemRead <= '0';
    MemToReg <= '0';
    CSRWen <= '0';
    CSR <= '0';
    Stall <= '0';
    Nop <= '0';
    MExt <= '0';

    case opcode is
      when OPCODE_LUI =>
        Lui <= '1';
        RegWrite <= '1';
        ALUSrc1 <= '1';
        ALUSrc2 <= '1';
        ALUOp <= ALU_OP_ADD;

      when OPCODE_AUIPC | OPCODE_JAL =>
        RegWrite <= '1';
        ALUSrc1 <= '1';
        ALUSrc2 <= '1';
        ALUOp <= ALU_OP_ADD;

      when OPCODE_JALR =>
        RegWrite <= '1';
        ALUSrc2 <= '1';
        ALUOp <= ALU_OP_ADD;

      when OPCODE_BRANCH =>
        ALUSrc1 <= '1';
        ALUSrc2 <= '1';
        ALUOp <= ALU_OP_ADD;

      when OPCODE_LOAD =>
        RegWrite <= '1';
        ALUSrc2 <= '1';
        ALUOp <= ALU_OP_ADD;
        MemRead <= '1';
        MemToReg <= '1';

      when OPCODE_STORE =>
        ALUSrc2 <= '1';
        ALUOp <= ALU_OP_ADD;
        MemWrite <= '1';

      when OPCODE_IMM =>
        RegWrite <= '1';
        ALUSrc2 <= '1';
        if funct3 = "101" then -- SRLI/SRAI
          ALUOp <= '0' & funct7(5) & funct3;
        else
          ALUOp <= "00" & funct3;
        end if;

      when OPCODE_RTYPE =>
        RegWrite <= '1';
        ALUOp <= funct7(0) & funct7(5) & funct3;
        if funct7(0)='1' then
          MExt <='1';
        end if;

      when OPCODE_SYSTEM =>
      -- For CSRRS
        if funct3 ="010" then
          CSR <= '1';
          ALUOp <=ALU_OP_OR;
          RegWrite <='1';
          if rs1 /= "00000" then 
            CSRWen <='1';
          end if;
        -- For CSRRC
        elsif funct3="011" then
          CSR <='1';
          ALUOp <= ALU_OP_XOR_AND;
          RegWrite <='1';
          if rs1 /= "00000" then
            CSRWen <= '1';
          end if;
        end if;
	
      when others =>
        null;
    end case;

    if MStall='1' then 
      Stall<='1';
      Nop <='1';
    end if;

  end process;
end architecture ;
