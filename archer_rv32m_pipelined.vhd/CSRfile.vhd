library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.archer_pkg.all;

entity CSRfile is
    port (
        clk : in std_logic;
        rst_n : in std_logic;
        instr_word : in std_logic_vector(XLEN-1 downto 0);
        datain : in std_logic_vector (XLEN-1 downto 0);
        CSRWen : in std_logic;
	    instr_word_WB : in std_logic_vector(XLEN-1 downto 0);
        dataout : out std_logic_vector (XLEN-1 downto 0)
    );
end CSRfile;

architecture rtl of CSRfile is
    type reg_file is array (0 to 3) of std_logic_vector (XLEN-1 downto 0);
    signal storage : reg_file :=(X"00000001",others => (others =>'0'));
    signal CSR_addr : std_logic_vector(11 downto 0):= instr_word(XLEN-1 downto 20);
    signal CSR_addr_WB : std_logic_vector(11 downto 0):= instr_word_WB(XLEN-1 downto 20);
    signal addr4_in: std_logic_vector (1 downto 0) :="00";
    signal opcode : std_logic_vector(6 downto 0) := instr_word(6 downto 0);
    signal funct3 : std_logic_vector(2 downto 0) :=instr_word(14 downto 12);


begin
    process (clk,rst_n)
	variable csr_cycle_count_lower : unsigned(XLEN-1 downto 0) := (others => '0');
	variable csr_cycle_count_upper : unsigned(XLEN-1 downto 0) := (others => '0'); 
	variable csr_instr_count_lower : unsigned(XLEN-1 downto 0) := (others => '0');
	variable csr_instr_count_upper : unsigned(XLEN-1 downto 0) := (others => '0'); 
    begin
	-- process to count clk
	if (rst_n='0') then
		csr_cycle_count_lower := (others =>'0');
       	csr_cycle_count_upper := (others =>'0');	
	elsif rising_edge(clk) then
        if (storage(0) = X"FFFFFFFF") then
      		csr_cycle_count_upper := unsigned(storage(1)) + 1;
        end if;
        csr_cycle_count_lower := unsigned(storage(0)) + 1;
    end if;
    if (rising_edge(clk)) then			
      	storage(0)<=std_logic_vector(csr_cycle_count_lower);
 		storage(1)<=std_logic_vector(csr_cycle_count_upper);
    end if;
      	
    --process to count instret
    if (rst_n='0') then
		csr_instr_count_lower := (others =>'0');
       	csr_instr_count_upper := (others =>'0');	
	elsif (rising_edge(clk) and (instr_word_WB=X"00000013" or instr_word_WB=X"00000000")) then
        csr_instr_count_upper := unsigned(storage(3));
        csr_instr_count_lower := unsigned(storage(2));
    elsif (rising_edge(clk) and (instr_word_WB(0)='0' or instr_word_WB(0)='1')) then
        if (storage(2) = X"FFFFFFFF") then
      		csr_instr_count_upper := unsigned(storage(3)) + 1;
        end if;
        csr_instr_count_lower := unsigned(storage(2)) + 1;
    end if;	
    if (rising_edge(clk)) then 
        storage(2)<=std_logic_vector(csr_instr_count_lower);
 		storage(3)<=std_logic_vector(csr_instr_count_upper);
	end if;

    if (CSR_addr_WB =X"C00") then
        addr4_in <= "00";
    elsif (CSR_addr_WB = X"C02") then
        addr4_in <= "10";
    elsif (CSR_addr_WB = X"C80") then
        addr4_in <= "01";
    else addr4_in <= "11";
    end if;

 	-- Writing back to CSRfile
	if (CSRWen ='1') and falling_edge(clk) then
    	storage(to_integer(unsigned(addr4_in))) <= datain;
   	end if;
    end process;
    
    --process to read from storage
    process (clk, rst_n, CSR_addr)
	variable addr4: std_logic_vector (1 downto 0) :="00";
    begin

    if (CSR_addr = X"C00") then
        addr4 := "00";
    elsif (CSR_addr = X"C02") then
        addr4 := "10";
    elsif (CSR_addr = X"C80") then
        addr4 := "01";
    else addr4 := "11";
    end if;

	    dataout <= storage (to_integer(unsigned(addr4)));	
    end process;
    
end architecture;
