library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity multALU is
    port (
        clk : in std_logic;
        MExt : in std_logic;
        ALUOp : in std_logic_vector (4 downto 0);
        inputA: in std_logic_vector (XLEN-1 downto 0);
        inputB: in std_logic_vector (XLEN-1 downto 0);
        result : out std_logic_vector (XLEN-1 downto 0);
        MStall : out std_logic
    );
end multALU;

architecture rtl of multALU is

    component multALUbus
        port (
            clk : in std_logic;
            MExt_in : in std_logic;
            inputA_in : in std_logic_vector (XLEN-1 downto 0);
            inputB_in : in std_logic_vector (XLEN-1 downto 0);
            ALUOp_in : in std_logic_vector (4 downto 0);
            MExt_out : out std_logic;
            inputA_out : out std_logic_vector (XLEN-1 downto 0);
            inputB_out : out std_logic_vector (XLEN-1 downto 0);
            ALUOp_out : out std_logic_vector (4 downto 0)
        );
    end component;

    signal MExt_EX1 : std_logic :='0';
    signal inputA_EX1 : std_logic_vector (XLEN-1 downto 0);
    signal inputB_EX1: std_logic_vector (XLEN-1 downto 0);
    signal ALUOp_EX1 : std_logic_vector (4 downto 0);

    signal MExt_EX2 : std_logic :='0';
    signal inputA_EX2 : std_logic_vector (XLEN-1 downto 0);
    signal inputB_EX2: std_logic_vector (XLEN-1 downto 0);
    signal ALUOp_EX2 : std_logic_vector (4 downto 0);

    signal MExt_EX3 : std_logic :='0';
    signal inputA_EX3 : std_logic_vector (XLEN-1 downto 0);
    signal inputB_EX3: std_logic_vector (XLEN-1 downto 0);
    signal ALUOp_EX3 : std_logic_vector (4 downto 0);

    signal MExt_EX4 : std_logic :='0';
    signal inputA_EX4 : std_logic_vector (XLEN-1 downto 0);
    signal inputB_EX4: std_logic_vector (XLEN-1 downto 0);
    signal ALUOp_EX4 : std_logic_vector (4 downto 0);

    signal MExt_EX5: std_logic :='0';
    signal inputA_EX5 : std_logic_vector (XLEN-1 downto 0);
    signal inputB_EX5: std_logic_vector (XLEN-1 downto 0);
    signal ALUOp_EX5 : std_logic_vector (4 downto 0);

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

    MExt_EX1<=MExt;
    inputA_EX1 <= inputA;
    inputB_EX1 <= inputB;
    ALUOp_EX1 <= ALUop;

    bus1 : multALUbus port map(clk=>clk, MExt_in=>MExt_EX1, inputA_in=>inputA_EX1, inputB_in=>inputB_EX1, ALUOp_in=>ALUOp_EX1, MExt_out=>MExt_EX2, inputA_out=>inputA_EX2, inputB_out=>inputB_EX2,ALUOp_out=>ALUOp_EX2);
    bus2 : multALUbus port map(clk=>clk, MExt_in=>MExt_EX2, inputA_in=>inputA_EX2, inputB_in=>inputB_EX2, ALUOp_in=>ALUOp_EX2, MExt_out=>MExt_EX3, inputA_out=>inputA_EX3, inputB_out=>inputB_EX3,ALUOp_out=>ALUOp_EX3);
    bus3 : multALUbus port map(clk=>clk, MExt_in=>MExt_EX3, inputA_in=>inputA_EX3, inputB_in=>inputB_EX3, ALUOp_in=>ALUOp_EX3, MExt_out=>MExt_EX4, inputA_out=>inputA_EX4, inputB_out=>inputB_EX4,ALUOp_out=>ALUOp_EX4);
    bus4 : multALUbus port map(clk=>clk, MExt_in=>MExt_EX4, inputA_in=>inputA_EX4, inputB_in=>inputB_EX4, ALUOp_in=>ALUOp_EX4, MExt_out=>MExt_EX5, inputA_out=>inputA_EX5, inputB_out=>inputB_EX5,ALUOp_out=>ALUOp_EX5);

    --Multiply
    temp_mul <= std_logic_vector(signed(inputA_EX5) * signed(inputB_EX5));
    mul_result <= temp_mul(XLEN-1 downto 0);
    mulh_result <= temp_mul(2*XLEN-1 downto XLEN);
    temp_mulhu <= std_logic_vector(unsigned(inputA_EX5) * unsigned(inputB_EX5));
    mulhu_result <= temp_mulhu(2*XLEN-1 downto XLEN);
    temp_mulhsu <= std_logic_vector(signed(inputA_EX5) * (signed('0'& inputB_EX5))); --check back
    mulhsu_result <= temp_mulhsu(2*XLEN-1 downto XLEN);
    --Divide and remainder
    div_result<= 	X"FFFFFFFF" when inputB_EX5=X"00000000" else
    			inputA_EX5 when inputA_EX5=X"FFFFFFFF" and inputB_EX5=X"FFFFFFFF" else
    			std_logic_vector(signed(inputA_EX5)/signed(inputB_EX5));
    divu_result<=	X"FFFFFFFF" when inputB_EX5=X"00000000" else
    			std_logic_vector(unsigned(inputA_EX5)/unsigned(inputB_EX5));
    rem_result<=	inputA_EX5 when inputB_EX5=X"00000000" else
    			X"00000000" when inputA_EX5=X"FFFFFFFF" and inputB_EX5=X"FFFFFFFF" else
    			std_logic_vector(signed(inputA_EX5) rem signed(inputB_EX5));
    remu_result<=	inputA_EX5 when inputB_EX5=X"00000000" else
    			std_logic_vector(signed(inputA_EX5) rem signed(inputB_EX5));

    with ALUop select
    result <=   mul_result when ALU_OP_MUL, --MUL
                mulh_result when ALU_OP_MULH, --MULH
                mulhu_result when ALU_OP_MULHU, --MULHU 
                mulhsu_result when ALU_OP_MULHSU, --MULHSU
		        div_result when ALU_OP_DIV, --div
                divu_result when ALU_OP_DIVU, --divu
                rem_result when ALU_OP_REM, --rem
                remu_result when ALU_OP_REMU, --remu
                (others=>'0') when others;

    MStall <= '1' when MExt_EX1='1' and MExt_EX5/='1' else
            '0' when MExt_EX5='1';

end architecture;