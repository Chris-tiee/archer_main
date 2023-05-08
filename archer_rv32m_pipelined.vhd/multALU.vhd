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
        instruction_in : in std_logic_vector (XLEN-1 downto 0);
        instruction_out : out std_logic_vector (XLEN-1 downto 0);
        rd_in : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        rd_out : out std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
        regA : in std_logic_vector (1 downto 0);
        regB : in std_logic_vector (1 downto 0);
        stall : in std_logic;
        alu_result_MEM : in std_logic_vector (XLEN-1 downto 0);
        reg_file_WB : in std_logic_vector (XLEN-1 downto 0);
        result : out std_logic_vector (XLEN-1 downto 0);
        MStall : out std_logic_vector(1 downto 0);
        MNop : out std_logic
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
            instruction_in: in std_logic_vector (XLEN-1 downto 0);
            rd_in : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            stall : in std_logic;
            MExt_out : out std_logic;
            inputA_out: out std_logic_vector (XLEN-1 downto 0);
            inputB_out: out std_logic_vector (XLEN-1 downto 0);
            ALUOp_out : out std_logic_vector (4 downto 0);
            instruction_out: out std_logic_vector (XLEN-1 downto 0);
            rd_out : out std_logic_vector (LOG2_XRF_SIZE-1 downto 0)
        );
    end component;

    component mux3to1
        port (  
            sel : in std_logic_vector(1 downto 0);
            input00 : in std_logic_vector (XLEN-1 downto 0);
            input01 : in std_logic_vector (XLEN-1 downto 0);
            input10 : in std_logic_vector (XLEN-1 downto 0);
            output : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    signal MExt_EX1 : std_logic :='0';
    signal inputA_EX1 : std_logic_vector (XLEN-1 downto 0);
    signal inputB_EX1: std_logic_vector (XLEN-1 downto 0);
    signal ALUOp_EX1 : std_logic_vector (4 downto 0);
    signal instruction_EX1 : std_logic_vector (XLEN-1 downto 0);
    signal rd_EX1 : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);

    signal MExt_EX2 : std_logic :='0';
    signal inputA_EX2 : std_logic_vector (XLEN-1 downto 0);
    signal inputB_EX2: std_logic_vector (XLEN-1 downto 0);
    signal ALUOp_EX2 : std_logic_vector (4 downto 0);
    signal instruction_EX2 : std_logic_vector (XLEN-1 downto 0);
    signal rd_EX2 : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);

    signal MExt_EX3 : std_logic :='0';
    signal inputA_EX3 : std_logic_vector (XLEN-1 downto 0);
    signal inputB_EX3: std_logic_vector (XLEN-1 downto 0);
    signal ALUOp_EX3 : std_logic_vector (4 downto 0);
    signal instruction_EX3 : std_logic_vector (XLEN-1 downto 0);
    signal rd_EX3 : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);

    signal MExt_EX4 : std_logic :='0';
    signal inputA_EX4 : std_logic_vector (XLEN-1 downto 0);
    signal inputB_EX4: std_logic_vector (XLEN-1 downto 0);
    signal ALUOp_EX4 : std_logic_vector (4 downto 0);
    signal instruction_EX4 : std_logic_vector (XLEN-1 downto 0);
    signal rd_EX4 : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);

    signal MExt_EX5: std_logic :='0';
    signal inputA_EX5 : std_logic_vector (XLEN-1 downto 0);
    signal inputB_EX5: std_logic_vector (XLEN-1 downto 0);
    signal ALUOp_EX5 : std_logic_vector (4 downto 0);
    signal instruction_EX5 : std_logic_vector (XLEN-1 downto 0);
    signal rd_EX5 : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);

    
    signal inputA_final : std_logic_vector (XLEN-1 downto 0);
    signal inputB_final : std_logic_vector (XLEN-1 downto 0);

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
    instruction_EX1 <= instruction_in;
    rd_EX1 <= rd_in;

    bus1 : multALUbus port map(clk=>clk, MExt_in=>MExt_EX1, inputA_in=>inputA_EX1, inputB_in=>inputB_EX1, ALUOp_in=>ALUOp_EX1,instruction_in =>instruction_EX1, rd_in => rd_EX1, stall => stall, MExt_out=>MExt_EX2, inputA_out=>inputA_EX2, inputB_out=>inputB_EX2,ALUOp_out=>ALUOp_EX2, instruction_out => instruction_EX2, rd_out => rd_EX2);
    bus2 : multALUbus port map(clk=>clk, MExt_in=>MExt_EX2, inputA_in=>inputA_EX2, inputB_in=>inputB_EX2, ALUOp_in=>ALUOp_EX2,instruction_in =>instruction_EX2, rd_in => rd_EX2, stall => stall, MExt_out=>MExt_EX3, inputA_out=>inputA_EX3, inputB_out=>inputB_EX3,ALUOp_out=>ALUOp_EX3, instruction_out => instruction_EX3, rd_out => rd_EX3);
    bus3 : multALUbus port map(clk=>clk, MExt_in=>MExt_EX3, inputA_in=>inputA_EX3, inputB_in=>inputB_EX3, ALUOp_in=>ALUOp_EX3,instruction_in =>instruction_EX3, rd_in => rd_EX3, stall => stall, MExt_out=>MExt_EX4, inputA_out=>inputA_EX4, inputB_out=>inputB_EX4,ALUOp_out=>ALUOp_EX4, instruction_out => instruction_EX4, rd_out => rd_EX4);
    bus4 : multALUbus port map(clk=>clk, MExt_in=>MExt_EX4, inputA_in=>inputA_EX4, inputB_in=>inputB_EX4, ALUOp_in=>ALUOp_EX4,instruction_in =>instruction_EX4, rd_in => rd_EX4, stall => stall, MExt_out=>MExt_EX5, inputA_out=>inputA_EX5, inputB_out=>inputB_EX5,ALUOp_out=>ALUOp_EX5, instruction_out => instruction_EX5, rd_out => rd_EX5);
    inputA_mux : mux3to1 port map (sel => regA, input00 => inputA_EX5, input01 => alu_result_MEM, input10 => reg_file_WB, output => inputA_final);
    inputB_mux : mux3to1 port map (sel => regB, input00 => inputB_EX5, input01 => alu_result_MEM, input10 => reg_file_WB, output => inputB_final);

    --Multiply
    temp_mul <= std_logic_vector(signed(inputA_final) * signed(inputB_EX5));
    mul_result <= temp_mul(XLEN-1 downto 0);
    mulh_result <= temp_mul(2*XLEN-1 downto XLEN);
    temp_mulhu <= std_logic_vector(unsigned(inputA_final) * unsigned(inputB_EX5));
    mulhu_result <= temp_mulhu(2*XLEN-1 downto XLEN);
    temp_mulhsu <= std_logic_vector(signed(inputA_final) * (signed('0'& inputB_EX5))); --check back
    mulhsu_result <= temp_mulhsu(2*XLEN-1 downto XLEN);
    --Divide and remainder
    div_result<= 	X"FFFFFFFF" when inputB_EX5=X"00000000" else
    			inputA_final when inputA_final=X"FFFFFFFF" and inputB_EX5=X"FFFFFFFF" else
    			std_logic_vector(signed(inputA_final)/signed(inputB_EX5));
    divu_result<=	X"FFFFFFFF" when inputB_EX5=X"00000000" else
    			std_logic_vector(unsigned(inputA_final)/unsigned(inputB_EX5));
    rem_result<=	inputA_final when inputB_EX5=X"00000000" else
    			X"00000000" when inputA_final=X"FFFFFFFF" and inputB_EX5=X"FFFFFFFF" else
    			std_logic_vector(signed(inputA_final) rem signed(inputB_EX5));
    remu_result<=	inputA_final when inputB_EX5=X"00000000" else
    			std_logic_vector(signed(inputA_final) rem signed(inputB_EX5));

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

    instruction_out <= instruction_EX5;
    rd_out <= rd_EX5;
    MStall <=   "00" when (MExt_EX1='1' and MExt_EX2='1' and MExt_EX3='1' and MExt_EX4='1' and MExt_EX5='1' and instruction_EX1=instruction_EX5) else
                "11" when (MExt_EX1 ='1'and instruction_EX1(14)='1') else
                "10" when (MExt_EX1='1') else
                "00" ;
    MNop <=     '1' when MExt_EX1='1' and MExt_EX5/='1' else
                '1' when MExt_EX1='1' and MExt_EX5='1' and instruction_EX1/=instruction_EX5 and instruction_EX5(14)='1' else
                '1' when MExt_EX1='1' and MExt_EX5='1' and instruction_EX1/=instruction_EX5 and instruction_EX1(14)='1' else
                '1' when MExt_EX1='1' and MExt_EX5='1' and instruction_EX1/=instruction_EX5 and (MExt_EX2/='1' or MExt_EX3/='1' or MExt_EX4/='1') else
                '0' when MExt_EX5='1';

end architecture;