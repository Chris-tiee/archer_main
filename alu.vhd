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
-- Arithmetic and Logic Unit (ALU)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity alu is
    port (
        inputA : in std_logic_vector (XLEN-1 downto 0);
        inputB : in std_logic_vector (XLEN-1 downto 0);
        ALUop : in std_logic_vector (4 downto 0);
        result : out std_logic_vector (XLEN-1 downto 0)
    );
end alu;

architecture rtl of alu is
--original set
    signal add_result : std_logic_vector (XLEN-1 downto 0);
    signal sub_result : std_logic_vector (XLEN-1 downto 0);
    signal and_result : std_logic_vector (XLEN-1 downto 0);
    signal or_result : std_logic_vector (XLEN-1 downto 0);
    signal xor_result : std_logic_vector (XLEN-1 downto 0);
    signal sll_result : std_logic_vector (XLEN-1 downto 0);
    signal srl_result : std_logic_vector (XLEN-1 downto 0);
    signal sra_result : std_logic_vector (XLEN-1 downto 0);
    signal slt_result : std_logic_vector (XLEN-1 downto 0);
    signal sltu_result : std_logic_vector (XLEN-1 downto 0); 
--For the CSRRC
    signal xor_and_result: std_logic_vector (XLEN-1 downto 0);
--Multiply 
    signal mul_result: std_logic_vector (XLEN-1 downto 0);
    signal mulh_result: std_logic_vector (XLEN-1 downto 0);
    signal mulhsu_result: std_logic_vector (XLEN-1 downto 0);
    signal mulhu_result: std_logic_vector (XLEN-1 downto 0);
--Temporary for multiplications
    signal temp_mul: std_logic_vector (2*XLEN-1 downto 0);
    signal temp_mulhu: std_logic_vector (2*XLEN-1 downto 0);
    signal temp_mulhsu: std_logic_vector (2*XLEN downto 0);
--Division
    signal div_result: std_logic_vector (XLEN-1 downto 0);
    signal divu_result: std_logic_vector (XLEN-1 downto 0);
    signal rem_result: std_logic_vector (XLEN-1 downto 0);
    signal remu_result: std_logic_vector (XLEN-1 downto 0);

begin
    --Original set
    add_result <= std_logic_vector(signed(inputA) + signed(inputB));
    sub_result <= std_logic_vector(signed(inputA) - signed(inputB));
    and_result <= inputA and inputB;
    or_result <= inputA or inputB;
    xor_result <= inputA xor inputB;
    sll_result <= std_logic_vector(shift_left(unsigned(inputA), to_integer(unsigned(inputB(4 downto 0)))));
    srl_result <= std_logic_vector(shift_right(unsigned(inputA), to_integer(unsigned(inputB(4 downto 0)))));
    sra_result <= std_logic_vector(shift_right(signed(inputA), to_integer(unsigned(inputB(4 downto 0)))));
    slt_result <= (XLEN-1 downto 1 =>'0')&'1' when signed(inputA) < signed(inputB) else (others=>'0');
    sltu_result <= (XLEN-1 downto 1 =>'0')&'1' when unsigned(inputA) < unsigned(inputB) else (others=>'0');
    xor_and_result <= (inputA xor X"FFFFFFFF" ) and inputB;
    --Multiply
    temp_mul <= std_logic_vector(signed(inputA) * signed(inputB));
    mul_result <= temp_mul(XLEN-1 downto 0);
    mulh_result <= temp_mul(2*XLEN-1 downto XLEN);
    temp_mulhu <= std_logic_vector(unsigned(inputA) * unsigned(inputB));
    mulhu_result <= temp_mulhu(2*XLEN-1 downto XLEN);
    temp_mulhsu <= std_logic_vector(signed(inputA) * (signed('0'& inputB))); --check back
    mulhsu_result <= temp_mulhsu(2*XLEN-1 downto XLEN);
    --Divide and remainder
    div_result<= 	X"FFFFFFFF" when inputB=X"00000000" else
    			inputA when inputA=X"FFFFFFFF" and inputB=X"FFFFFFFF" else
    			std_logic_vector(signed(inputA)/signed(inputB));
    divu_result<=	X"FFFFFFFF" when inputB=X"00000000" else
    			std_logic_vector(unsigned(inputA)/unsigned(inputB));
    rem_result<=	inputA when inputB=X"00000000" else
    			X"00000000" when inputA=X"FFFFFFFF" and inputB=X"FFFFFFFF" else
    			std_logic_vector(signed(inputA) rem signed(inputB));
    remu_result<=	inputA when inputB=X"00000000" else
    			std_logic_vector(signed(inputA) rem signed(inputB));

    with ALUop select
    result <=   add_result when ALU_OP_ADD, -- add
                sub_result when ALU_OP_SUB, -- sub
                and_result when ALU_OP_AND, -- and
                or_result when ALU_OP_OR, -- or
                xor_result when ALU_OP_XOR, -- xor
                sll_result when ALU_OP_SLL, -- sll
                srl_result when ALU_OP_SRL, -- srl
                sra_result when ALU_OP_SRA, -- sra
                slt_result when ALU_OP_SLT, -- slt
                sltu_result when ALU_OP_SLTU, -- sltu
                xor_and_result when ALU_OP_XOR_AND, --XOR AND
                mul_result when ALU_OP_MUL, --MUL
                mulh_result when ALU_OP_MULH, --MULH
                mulhu_result when ALU_OP_MULHU, --MULHU 
                mulhsu_result when ALU_OP_MULHSU, --MULHSU
		        div_result when ALU_OP_DIV, --div
                divu_result when ALU_OP_DIVU, --divu
                rem_result when ALU_OP_REM, --rem
                remu_result when ALU_OP_REMU, --remu
                (others=>'0') when others;

end architecture;
