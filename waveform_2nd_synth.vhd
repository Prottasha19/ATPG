library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.parameter.all;

entity waveform_gen is
  port(
    clk,rst,start,mode,data_in : in std_logic;
    sync_rst_ram_addr : in std_logic;
    period_multiplier:in std_logic_vector(counter_sleep_width-1 downto 0);
    data_out: out std_logic_vector(bit_width_data-1 downto 0);
    sleep_reg: out std_logic_vector(counter_sleep_width-1 downto 0);
    ---------------------------------------------------------------------------
    SERIAL_IN, SCAN_EN, TESTMODE: in std_logic;                           --     Modified for TST
    SERIAL_OUT: out std_logic    
    );
  end entity;

architecture behaviour of waveform_gen is
  signal gated_clk,sleep_inv: std_logic;
  signal gated_clk2,sleep2_inv: std_logic;
  signal re_ram,we_ram,oe_ram,enable_reg_file,sleep,sleep2,enable_shift_reg: std_logic;
  signal addr_ram: std_logic_vector(size_ram_addr-1 downto 0);
  signal data_shift_reg,ram_out,ram_out_dft:std_logic_vector(bit_width_data-1 downto 0);
  -----------------------------------------------------------------------------
  signal RAMBO, RAMBO_out : std_logic_vector(bit_width_data-1 downto 0);  --     Modified for TST
  signal intEnRAM : std_logic;

begin


  sleep_inv <= not sleep;
  sleep2_inv <= not sleep2;

 clk_gate1:CLKGATETST_X1               -- TEST CLOCK GATE
port map(
    CK => clk,
    E => sleep_inv,
    GCK => gated_clk,
    SE => TESTMODE
    );

clk_gate2:CLKGATETST_X1               -- TEST CLOCK GATE
port map(
    CK => clk,
    E => sleep2_inv,
    GCK => gated_clk2,
    SE => TESTMODE
    );  

  controller_main:fsm
  port map(
      clk=> gated_clk,
      rst=>rst,
      start=>start,
      mode=>mode,
      re_ram=>re_ram,
      we_ram=>we_ram,
      oe_ram=>oe_ram,
      enable_shift_reg => enable_shift_reg
    );

  controller_sleep0:controller_sleep
  port map(
      clk=>clk,
      rst=>rst,
      re_ram => re_ram,
      we_ram => we_ram,
      addr_ram => addr_ram,
      sync_rst_ram_counter=> sync_rst_ram_addr,
      sleep_time=>period_multiplier,
      sleep=>sleep,
      sleep2=> sleep2,
      enable_reg_file => enable_reg_file,
      sleep_reg => sleep_reg
    );

  shift_reg_data_in:shift_reg
  port map(
    clk=>gated_clk,
    rst=>rst,
    data_in=>data_in,
    ena=>enable_shift_reg,
    data_out=>data_shift_reg
    );

ram_block:SRAM64x8_1rw
  port map(
    CE=>gated_clk,
    WEB=>we_ram,
    REB=>re_ram,
    OEB=>intEnRAM,                      --     Modified for TST
    A=>addr_ram,
    I=> data_shift_reg,
    O=> ram_out
    );   

  output_register:reg_file
  port map(
    clk=>gated_clk2,
    rst => rst,
    ena => enable_reg_file,
    data_in => RAMBO_out,               --      Modified for TST      
    data_out => data_out
    ); 

  -----------------------------------------------------------------------------
  -- Added for TST
  -----------------------------------------------------------------------------

xor_reg:process(clk,rst) is
  begin
    if rst='0' then
      RAMBO <= (others => '0');
    elsif clk='1' and clk'event then
      RAMBO <= ((addr_ram & we_ram & re_ram) xor data_shift_reg);
    end if;
  end process xor_reg;

mux2:process(RAMBO ,ram_out, TESTMODE) is
  begin
    if TESTMODE='1' then
      RAMBO_out <= RAMBO;
    else
      RAMBO_out <= ram_out;
    end if;
  end process mux2;

mux1:process(oe_ram, TESTMODE) is
  begin
    if TESTMODE='1' then
      intEnRAM <= '0';
    else
      intEnRAM <= oe_ram;
    end if;
  end process mux1;


end architecture;
