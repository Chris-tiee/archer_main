library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity archer_rv32i_pipelined is
    port (
        clk : in std_logic;
        rst_n : in std_logic;
        -- local instruction memory bus interface
        imem_addr : out std_logic_vector (ADDRLEN-1 downto 0);
        imem_datain : out std_logic_vector (XLEN-1 downto 0);
        imem_dataout : in std_logic_vector (XLEN-1 downto 0);
        imem_wen : out std_logic; -- write enable signal
        imem_ben : out std_logic_vector (3 downto 0); -- byte enable signals
        -- local data memory bus interface
        dmem_addr : out std_logic_vector (ADDRLEN-1 downto 0);
        dmem_datain : out std_logic_vector (XLEN-1 downto 0);
        dmem_dataout : in std_logic_vector (XLEN-1 downto 0);
        dmem_wen : out std_logic; -- write enable signal
        dmem_ben : out std_logic_vector (3 downto 0) -- byte enable signals
    );
end archer_rv32i_pipelined;

architecture rtl of archer_rv32i_pipelined is

    component add4
        port (
            datain : in std_logic_vector (XLEN-1 downto 0);
            result : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component lmb
        port (
            proc_addr : in std_logic_vector (XLEN-1 downto 0);
            proc_data_send : in std_logic_vector (XLEN-1 downto 0);
            proc_data_receive : out std_logic_vector (XLEN-1 downto 0);
            proc_byte_mask : in std_logic_vector (1 downto 0); -- "00" = byte; "01" = half-word; "10" = word
            proc_sign_ext_n : in std_logic;
            proc_mem_write : in std_logic;
            proc_mem_read : in std_logic;
            mem_addr : out std_logic_vector (ADDRLEN-1 downto 0);
            mem_datain : out std_logic_vector (XLEN-1 downto 0);
            mem_dataout : in std_logic_vector (XLEN-1 downto 0);
            mem_wen : out std_logic; -- write enable signal
            mem_ben : out std_logic_vector (3 downto 0) -- byte enable signals
        );
    end component;

    component mux2to1
        port (
            sel : in std_logic;
            input0 : in std_logic_vector (XLEN-1 downto 0);
            input1 : in std_logic_vector (XLEN-1 downto 0);
            output : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component mux2to1_5b
        port (
            sel : in std_logic;
            input0 : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            input1 : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            output : out std_logic_vector (LOG2_XRF_SIZE-1 downto 0)
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

    component pc
        port (
            clk : in std_logic;
            rst_n : in std_logic;
            datain : in std_logic_vector(XLEN-1 downto 0);
            dataout : out std_logic_vector(XLEN-1 downto 0)
        );
    end component;

    component branch_cmp
        port (
            inputA : in std_logic_vector(XLEN-1 downto 0);
            inputB : in std_logic_vector(XLEN-1 downto 0);
            cond : in std_logic_vector(2 downto 0);
            result : out std_logic
        );
    end component;

    component control
        port (
            instruction : in std_logic_vector (XLEN-1 downto 0);
            BranchCond : in std_logic; -- BR. COND. SATISFIED = 1; NOT SATISFIED = 0
            MStall : in std_logic_vector(1 downto 0); -- stalling to simulate 5cc 
            MNop : in std_logic;
            dfStall : in std_logic;
            bStall : in std_logic;
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
            regularStall : out std_logic;
            branchStall : out std_logic;
            Nop : out std_logic;
            bNop : out std_logic;
            MExt : out std_logic -- if from M extension
        ) ;
    end component; 

    component immgen
        port (
            instruction : in std_logic_vector (XLEN-1 downto 0);
            immediate : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component regfile
        port (
            clk : in std_logic;
            rst_n : in std_logic;
            RegWrite : in std_logic;
            rs1 : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rs2 : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rd : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            datain : in std_logic_vector (XLEN-1 downto 0);
            regA : out std_logic_vector (XLEN-1 downto 0);
            regB : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component branch_alu
        port (
            inputA : in std_logic_vector (XLEN-1 downto 0);
            inputB : in std_logic_vector (XLEN-1 downto 0);
            result : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component CSRfile
	    port(
	    	clk : in std_logic;
	    	rst_n : in std_logic;
	    	instr_word : in std_logic_vector(XLEN-1 downto 0);
	    	datain : in std_logic_vector (XLEN-1 downto 0);
	        CSRWen : in std_logic;
	    	instr_word_WB : in std_logic_vector(XLEN-1 downto 0);
	    	dataout : out std_logic_vector (XLEN-1 downto 0)
    	);
    end component;

    component alu
        port (
            inputA : in std_logic_vector (XLEN-1 downto 0);
            inputB : in std_logic_vector (XLEN-1 downto 0);
            ALUop : in std_logic_vector (4 downto 0);
            result : out std_logic_vector (XLEN-1 downto 0)
        );
    end component;

    component multALU
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
    end component;

    component dataForwarding
        port (
            clk : in std_logic;
            rs1 : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rs2 : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rd_EX : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rs1_ID : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rs2_ID : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            instruction_ID : in std_logic_vector(XLEN-1 downto 0);
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
            regA_branch : out  std_logic_vector (1 downto 0);
            regB_branch : out std_logic_vector (1 downto 0);
            bStall : out std_logic;
            stall : out std_logic
        );
    end component;

    component if_id
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
    end component;

    component id_ex is
        port (
            clk : in std_logic;
            rst_n : in std_logic;
            
            instruction_in : in std_logic_vector (XLEN-1 downto 0);
            instruction_out : out std_logic_vector (XLEN-1 downto 0);
            rd_out : out std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rs1_in : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rs1_out : out std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rs2_in : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rs2_out : out std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
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
            
            bNop : in std_logic;
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
    end component;

    component ex_mem
        port (
            clk : in std_logic;
            rst_n : in std_logic;

            instruction_in : in std_logic_vector (XLEN-1 downto 0);
            instruction_out : out std_logic_vector (XLEN-1 downto 0);
            byte_mask : out std_logic_vector (1 downto 0);
            sign_ext_n : out std_logic;
            pcplus4_in: in std_logic_vector (XLEN-1 downto 0);
            pcplus4_out : out std_logic_vector (XLEN-1 downto 0);
            rd_in : in std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
            rd_out : out std_logic_vector (LOG2_XRF_SIZE-1 downto 0);

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
    end component;

    component mem_wb
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
    end component;

    --IF stage
    signal d_pc_in : std_logic_vector(XLEN-1 downto 0);
    signal d_pc1_in : std_logic_vector(XLEN-1 downto 0);
    signal d_pc_out_IF : std_logic_vector(XLEN-1 downto 0);
    signal d_pcplus4_IF : std_logic_vector(XLEN-1 downto 0);
    signal d_instr_word_IF : std_logic_vector(XLEN-1 downto 0);

    --ID stage
    signal d_branch_result : std_logic_vector(XLEN-1 downto 0);
    
    signal d_instr_word_ID : std_logic_vector(XLEN-1 downto 0);
    signal d_funct3 : std_logic_vector (2 downto 0);
    
    signal d_rs1_ID : std_logic_vector (4 downto 0);
    signal d_rs2_ID : std_logic_vector (4 downto 0);
    signal d_regA_ID : std_logic_vector (XLEN-1 downto 0);
    signal d_regB_ID : std_logic_vector (XLEN-1 downto 0);
    signal d_regA_b_ID : std_logic_vector (XLEN-1 downto 0);
    signal d_regB_b_ID : std_logic_vector (XLEN-1 downto 0);
    signal d_immediate_ID : std_logic_vector (XLEN-1 downto 0);
    signal d_inputA_ID : std_logic_vector (XLEN-1 downto 0);

    signal d_pcplus4_ID : std_logic_vector(XLEN-1 downto 0);
    signal d_pc_out_ID: std_logic_vector(XLEN-1 downto 0);

    signal c_branch_out : std_logic;
    signal c_jump_ID : std_logic;
    signal c_lui_ID : std_logic;
    signal c_PCSrc_ID : std_logic;
    signal c_reg_write_ID : std_logic;
    signal c_alu_src1_ID : std_logic;
    signal c_alu_src2_ID : std_logic;
    signal c_alu_op_ID : std_logic_vector (4 downto 0);
    signal c_mem_write_ID : std_logic;
    signal c_mem_read_ID : std_logic;
    signal c_mem_to_reg_ID : std_logic;
    signal c_csrwen_ID : std_logic;
    signal c_csr_ID : std_logic;

    signal c_stall_ID : std_logic;
    signal c_stall_regular_ID : std_logic;
    signal c_stall_branch_ID : std_logic;
    signal c_nop_ID : std_logic;
    signal c_bnop_ID : std_logic;
    signal c_mext_ID : std_logic;

    --EX stage
    signal d_instr_word_EX : std_logic_vector(XLEN-1 downto 0);
    signal d_instr_word_mult_EX : std_logic_vector(XLEN-1 downto 0);
    signal d_instr_word_final_EX : std_logic_vector(XLEN-1 downto 0);
    signal d_rs1_EX : std_logic_vector (4 downto 0);
    signal d_rs2_EX : std_logic_vector (4 downto 0);
    signal d_rd_EX : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
    signal d_rd_mult_EX : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
    signal d_rd_final_EX : std_logic_vector (LOG2_XRF_SIZE-1 downto 0);
    signal d_regA_rf_EX : std_logic_vector (XLEN-1 downto 0);
    signal d_regB_rf_EX : std_logic_vector (XLEN-1 downto 0);    
    signal d_regA_EX : std_logic_vector (XLEN-1 downto 0);
    signal d_regB_EX : std_logic_vector (XLEN-1 downto 0);
    signal d_immediate_EX : std_logic_vector (XLEN-1 downto 0);

    signal d_pcplus4_EX : std_logic_vector(XLEN-1 downto 0);
    signal d_pc_out_EX: std_logic_vector(XLEN-1 downto 0);

    signal d_zero : std_logic_vector (XLEN-1 downto 0) := (others=>'0');
    signal d_lui_mux_out : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src1 : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_src2 : std_logic_vector (XLEN-1 downto 0);
    signal d_csr_EX: std_logic_vector(XLEN-1 downto 0);
    signal d_csrmux_out : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_result_EX : std_logic_vector (XLEN-1 downto 0);
    signal d_alu_main_result : std_logic_vector (XLEN-1 downto 0);
    signal d_multALU_result_EX : std_logic_vector (XLEN-1 downto 0);


    signal c_regA_EX : std_logic_vector (1 downto 0);
    signal c_regB_EX : std_logic_vector (1 downto 0);
    signal c_regA_mult_EX : std_logic_vector (1 downto 0);
    signal c_regB_mult_EX : std_logic_vector (1 downto 0);
    signal c_regA_branch_EX : std_logic_vector (1 downto 0);
    signal c_regB_branch_EX : std_logic_vector (1 downto 0);

    signal c_mstall_EX : std_logic_vector(1 downto 0);
    signal c_mnop_EX : std_logic;
    signal c_stall_df_EX : std_logic;
    signal c_stall_b_EX : std_logic;

    signal c_jump_EX : std_logic;
    signal c_lui_EX : std_logic;
    signal c_reg_write_EX : std_logic;
    signal c_alu_src1_EX : std_logic;
    signal c_alu_src2_EX : std_logic;
    signal c_alu_op_EX : std_logic_vector (4 downto 0);
    signal c_mem_write_EX : std_logic;
    signal c_mem_read_EX : std_logic;
    signal c_mem_to_reg_EX : std_logic;
    signal c_csrwen_EX : std_logic;
    signal c_csr_EX : std_logic;
    signal c_mext_EX : std_logic;

    --MEM stage
    signal d_instr_word_MEM : std_logic_vector(XLEN-1 downto 0);
    signal d_byte_mask : std_logic_vector (1 downto 0);
    signal d_sign_ext_n : std_logic;
    signal d_rd_MEM : std_logic_vector(LOG2_XRF_SIZE-1 downto 0);

    signal d_alu_result_MEM : std_logic_vector (XLEN-1 downto 0);
    signal d_regB_MEM : std_logic_vector (XLEN-1 downto 0);
    signal d_data_mem_out_MEM : std_logic_vector (XLEN-1 downto 0);

    signal d_pcplus4_MEM : std_logic_vector(XLEN-1 downto 0);

    signal c_jump_MEM : std_logic;
    signal c_reg_write_MEM : std_logic;
    signal c_mem_write_MEM : std_logic;
    signal c_mem_read_MEM : std_logic;
    signal c_mem_to_reg_MEM : std_logic;
    signal c_csrwen_MEM : std_logic;

    --WB stage
    signal c_jump_WB : std_logic;
    signal c_reg_write_WB : std_logic;
    signal c_mem_to_reg_WB : std_logic;
    signal c_csrwen_WB : std_logic;

    signal d_rd_WB : std_logic_vector(LOG2_XRF_SIZE-1 downto 0);
    signal d_instr_word_WB : std_logic_vector (XLEN-1 downto 0);

    signal d_pcplus4_WB : std_logic_vector(XLEN-1 downto 0);
    signal d_alu_result_WB : std_logic_vector (XLEN-1 downto 0);
    signal d_data_mem_out_WB : std_logic_vector (XLEN-1 downto 0);

    signal d_mem_mux_out : std_logic_vector (XLEN-1 downto 0);
    signal d_reg_file_datain_WB : std_logic_vector (XLEN-1 downto 0);
    


begin

    pc_inst : pc port map (clk => clk, rst_n => rst_n, datain => d_pc_in, dataout => d_pc_out_IF);

    limb_inst : lmb port map (proc_addr => d_pc_out_IF, proc_data_send => (others=>'0'), proc_data_receive => d_instr_word_IF,
                              proc_byte_mask => "10", proc_sign_ext_n => '1', proc_mem_write => '0',
                              proc_mem_read => '1', mem_addr => imem_addr, mem_datain => imem_datain, 
                              mem_dataout => imem_dataout, mem_wen => imem_wen, mem_ben => imem_ben);

    add4_inst : add4 port map (datain => d_pc_out_IF, result => d_pcplus4_IF);
    
    pc_mux : mux2to1 port map (sel => c_PCSrc_ID, input0 => d_pcplus4_IF, input1 => d_branch_result, output => d_pc1_in);
    pc2_mux : mux2to1 port map (sel => c_stall_ID, input0 => d_pc1_in, input1 => d_pc_out_IF, output => d_pc_in);
    
    IF_ID_reg : IF_ID port map (clk => clk, rst_n => rst_n, instruction_in => d_instr_word_IF, instruction_out => d_instr_word_ID, 
                                funct3 => d_funct3, rs1 => d_rs1_ID, rs2 => d_rs2_ID, pcplus4_in => d_pcplus4_IF,pcplus4_out => d_pcplus4_ID,
                                pc_in => d_pc_out_IF, pc_out => d_pc_out_ID, PCSrc => c_PCSrc_ID, Stall => c_stall_ID );

    control_inst : control port map (instruction => d_instr_word_ID, BranchCond => c_branch_out, MStall => c_mstall_EX, MNop => c_mnop_EX,
                                    dfStall=> c_stall_df_EX, bStall => c_stall_b_EX, Jump => c_jump_ID, Lui => c_lui_ID, PCSrc => c_PCSrc_ID,
                                    RegWrite => c_reg_write_ID, ALUSrc1 => c_alu_src1_ID, ALUSrc2 => c_alu_src2_ID, ALUOp => c_alu_op_ID, 
                                    MemWrite => c_mem_write_ID, MemRead => c_mem_read_ID, MemToReg => c_mem_to_reg_ID, CSRWen => c_csrwen_ID, 
                                    CSR => c_csr_ID, Stall => c_stall_ID, regularStall => c_stall_regular_ID, branchStall => c_stall_branch_ID,
                                    Nop => c_nop_ID, MExt => c_mext_ID );
    
    regA_b_mux : mux3to1 port map (sel => c_regA_branch_EX, input00 => d_regA_ID, input01 => d_alu_result_MEM, input10 => d_reg_file_datain_WB, output => d_regA_b_ID);
    regB_b_mux : mux3to1 port map (sel => c_regB_branch_EX, input00 => d_regB_ID, input01 => d_alu_result_MEM, input10 => d_reg_file_datain_WB, output => d_regB_b_ID);
    

    brcmp_inst : branch_cmp port map (inputA => d_regA_b_ID, inputB => d_regB_b_ID, cond => d_funct3, result => c_branch_out);

    immgen_inst : immgen port map (instruction => d_instr_word_ID, immediate => d_immediate_ID);

    RF_inst : regfile port map (clk => clk, rst_n => rst_n, RegWrite => c_reg_write_WB, rs1 => d_rs1_ID, rs2 => d_rs2_ID, 
                                rd => d_rd_WB, datain => d_reg_file_datain_WB, regA => d_regA_ID, regB => d_regB_ID);
    
    branch_mux : mux2to1 port map (sel => c_alu_src1_ID, input0 =>d_regA_b_ID , input1 => d_pc_out_ID , output => d_inputA_ID);
    branch_alu_inst : branch_alu port map (inputA => d_inputA_ID, inputB => d_immediate_ID, result => d_branch_result); 

    ID_EX_reg : id_ex port map (clk => clk, rst_n => rst_n, instruction_in => d_instr_word_ID, instruction_out => d_instr_word_EX, rd_out => d_rd_EX,
                                rs1_in => d_rs1_ID, rs1_out => d_rs1_EX, rs2_in => d_rs2_ID, rs2_out => d_rs2_EX,
                                regA_in => d_regA_ID, regB_in => d_regB_ID, regA_out => d_regA_rf_EX, regB_out => d_regB_rf_EX, immediate_in => d_immediate_ID, 
                                immediate_out => d_immediate_EX, pcplus4_in => d_pcplus4_ID, pcplus4_out => d_pcplus4_EX, pc_in => d_pc_out_ID, 
                                pc_out => d_pc_out_EX, bNop => c_bnop_ID, Stall => c_stall_regular_ID, Jump_in => c_jump_ID, Jump_out => c_jump_EX, Lui_in => c_lui_ID, 
                                Lui_out => c_lui_EX, RegWrite_in => c_reg_write_ID, RegWrite_out => c_reg_write_EX, ALUSrc1_in => c_alu_src1_ID, ALUSrc1_out => c_alu_src1_EX,
                                ALUSrc2_in => c_alu_src2_ID, ALUSrc2_out => c_alu_src2_EX, ALUOp_in => c_alu_op_ID, ALUOp_out => c_alu_op_EX,
                                MemWrite_in => c_mem_write_ID, MemWrite_out => c_mem_write_EX, MemRead_in => c_mem_read_ID, MemRead_out => c_mem_read_EX,
                                MemToReg_in => c_mem_to_reg_ID,MemToReg_out => c_mem_to_reg_EX, CSRWen_in => c_csrwen_ID, CSRWen_out => c_csrwen_EX,
                                CSR_in => c_csr_ID , CSR_out => c_csr_EX, MExt_in => c_mext_ID, MExt_out => c_mext_EX);
	
    regA_mux : mux3to1 port map (sel => c_regA_EX, input00 => d_regA_rf_EX, input01 => d_alu_result_MEM, input10 => d_reg_file_datain_WB, output => d_regA_EX);
    lui_mux : mux2to1 port map (sel => c_lui_EX, input0 => d_pc_out_EX, input1 => d_zero, output => d_lui_mux_out);
    alu_src1_mux : mux2to1 port map (sel => c_alu_src1_EX, input0 => d_regA_EX, input1 => d_lui_mux_out, output => d_alu_src1);
    
    regB_mux : mux3to1 port map (sel => c_regB_EX, input00 => d_regB_rf_EX, input01 => d_alu_result_MEM, input10 => d_reg_file_datain_WB, output => d_regB_EX);
    alu_src2_mux : mux2to1 port map (sel => c_alu_src2_EX, input0 => d_regB_EX, input1 => d_immediate_EX, output => d_alu_src2);
    CSRMux: mux2to1 port map (sel=>c_csr_EX, input0=>d_alu_src2, input1=>d_csr_EX, output=>d_csrmux_out);
    
    CSRfile_inst: CSRfile port map (clk=>clk, rst_n=>rst_n, instr_word => d_instr_word_EX, datain => d_mem_mux_out, CSRWEn => c_csrwen_WB, instr_word_WB =>d_instr_word_WB, dataout=>d_csr_EX);
    
    alu_inst : alu port map (inputA => d_alu_src1, inputB =>d_csrmux_out, ALUop => c_alu_op_EX, result => d_alu_main_result);
    multALU_inst: multALU port map (clk => clk, MExt => c_mext_EX, ALUOp => c_alu_op_EX, inputA=>d_alu_src1, inputB =>d_csrmux_out, instruction_in => d_instr_word_EX,
                                    instruction_out => d_instr_word_mult_EX, rd_in => d_rd_EX, rd_out => d_rd_mult_EX, regA => c_regA_mult_EX, regB =>c_regB_mult_EX, stall => c_stall_df_EX,
                                    alu_result_MEM => d_alu_result_MEM, reg_file_WB => d_reg_file_datain_WB, result => d_multALU_result_EX, MStall => c_mstall_EX, MNop => c_mnop_EX);
    alu_mux : mux2to1 port map (sel => c_mext_EX, input0 => d_alu_main_result, input1 => d_multALU_result_EX, output => d_alu_result_EX);
    instr_mux : mux2to1 port map (sel => c_mext_EX, input0 => d_instr_word_EX, input1 => d_instr_word_mult_EX, output => d_instr_word_final_EX);
    rd_mux : mux2to1_5b port map (sel => c_mext_EX, input0 => d_rd_EX, input1 => d_rd_mult_EX, output => d_rd_final_EX);

    dataForwarding_inst : dataForwarding port map (clk => clk, rs1=> d_rs1_EX, rs2=>d_rs2_EX, rd_EX => d_rd_EX, rs1_ID => d_rs1_ID, rs2_ID =>d_rs2_ID, instruction_ID => d_instr_word_ID,
                                                    instruction => d_instr_word_EX, instruction_mult => d_instr_word_mult_EX, MExt => c_mext_EX, rd_mult_EX => d_rd_mult_EX, rd_MEM => d_rd_MEM,
                                                    MemToReg_MEM => c_mem_to_reg_MEM, Jump_MEM => c_jump_MEM, RegWrite_MEM => c_reg_write_MEM, rd_WB => d_rd_WB, RegWrite_WB => c_reg_write_WB, 
                                                    regA => c_regA_EX, regB => c_regB_EX, regA_mult => c_regA_mult_EX, regB_mult =>c_regB_mult_EX, regA_branch => c_regA_branch_EX, regB_branch => c_regB_branch_EX,
                                                    bStall => c_stall_b_EX, stall => c_stall_df_EX);
    
    EX_MEM_reg : ex_mem port map (clk => clk, rst_n => rst_n, instruction_in => d_instr_word_final_EX, instruction_out => d_instr_word_MEM, byte_mask => d_byte_mask,
                                    sign_ext_n => d_sign_ext_n, pcplus4_in => d_pcplus4_EX, pcplus4_out => d_pcplus4_MEM, Nop => c_nop_ID, rd_in => d_rd_final_EX,
                                    rd_out => d_rd_MEM, alu_in => d_alu_result_EX, alu_out => d_alu_result_MEM, regB_in => d_regB_EX, regB_out => d_regB_MEM,
                                    Jump_in => c_jump_EX, Jump_out => c_jump_MEM, RegWrite_in => c_reg_write_EX, RegWrite_out => c_reg_write_MEM,
                                    MemWrite_in => c_mem_write_EX, MemWrite_out => c_mem_write_MEM, MemRead_in => c_mem_read_EX, MemRead_out => c_mem_read_MEM,
                                    MemToReg_in => c_mem_to_reg_EX, MemToReg_out => c_mem_to_reg_MEM, CSRWen_in => c_csrwen_EX, CSRWen_out => c_csrwen_MEM);

    ldmb_inst : lmb port map (proc_addr => d_alu_result_MEM, proc_data_send => d_regB_MEM,
                               proc_data_receive => d_data_mem_out_MEM, proc_byte_mask => d_byte_mask,
                               proc_sign_ext_n => d_sign_ext_n, proc_mem_write => c_mem_write_MEM, proc_mem_read => c_mem_read_MEM,
                               mem_addr => dmem_addr, mem_datain => dmem_datain, mem_dataout => dmem_dataout,
                               mem_wen => dmem_wen, mem_ben => dmem_ben);

    MEM_WB_reg : mem_wb port map (clk => clk, rst_n => rst_n, instruction_in =>d_instr_word_MEM, instruction_out => d_instr_word_WB,
                                    pcplus4_in => d_pcplus4_MEM, pcplus4_out => d_pcplus4_WB, alu_in => d_alu_result_MEM, 
                                    alu_out => d_alu_result_WB, mem_in => d_data_mem_out_MEM, mem_out => d_data_mem_out_WB, rd_in => d_rd_MEM,
                                    rd_out => d_rd_WB, Jump_in => c_jump_MEM, Jump_out => c_jump_WB, RegWrite_in => c_reg_write_MEM,
                                    RegWrite_out => c_reg_write_WB, MemToReg_in => c_mem_to_reg_MEM, MemToReg_out => c_mem_to_reg_WB,
                                    CSRWen_in => c_csrwen_MEM, CSRWen_out => c_csrwen_WB );

    mem_mux : mux2to1 port map (sel => c_mem_to_reg_WB, input0 => d_alu_result_WB, input1 => d_data_mem_out_WB, output => d_mem_mux_out);
    write_back_mux : mux2to1 port map (sel => c_jump_WB, input0 => d_mem_mux_out, input1 => d_pcplus4_WB, output => d_reg_file_datain_WB);


end architecture;