library ieee;
use ieee.std_logic_1164.all;

entity morse_top is
  generic (
    CLK_COUNT : positive := 25_000_000  -- 0.5 s a 50 MHz
  );
  port (
    CLOCK_50 : in  std_logic;
    SW       : in  std_logic_vector(2 downto 0);
    KEY      : in  std_logic_vector(1 downto 0);
    LEDR     : out std_logic_vector(0 downto 0)
  );
end entity morse_top;

architecture rtl of morse_top is

  signal reset_n : std_logic;

  -- sincronizadores
  signal sw_s1, sw_s2 : std_logic_vector(2 downto 0);
  signal k1_s1, k1_s2, k1_s3 : std_logic;
  signal start : std_logic;

  -- datos de la letra
  signal pattern    : std_logic_vector(3 downto 0);
  signal letter_len : std_logic_vector(2 downto 0);

  -- senales de control
  signal tick, s, last : std_logic;
  signal led, load, load_en, shift_en, dec_en, clr_tick : std_logic;

begin

  reset_n <= KEY(0);

  -- Sincronizadores de entradas y detector de flanco de KEY1
  p_sync : process (CLOCK_50, reset_n)
  begin
    if reset_n = '0' then
      sw_s1 <= (others => '0');
      sw_s2 <= (others => '0');
      k1_s1 <= '0';
      k1_s2 <= '0';
      k1_s3 <= '0';
    elsif rising_edge(CLOCK_50) then
      sw_s1 <= SW;
      sw_s2 <= sw_s1;
      k1_s1 <= not KEY(1);  -- '1' = KEY1 presionado
      k1_s2 <= k1_s1;
      k1_s3 <= k1_s2;
    end if;
  end process p_sync;

  start   <= k1_s2 and (not k1_s3);  -- pulso en el flanco de presion
  load_en <= load and (not start);   -- no recargar en el ciclo de start

  u_letter : entity work.letter_logic
    port map (
      sw      => sw_s2,
      pattern => pattern,
      len     => letter_len
    );

  u_shift : entity work.morse_shift_reg
    port map (
      clk      => CLOCK_50,
      reset_n  => reset_n,
      load     => load_en,
      shift_en => shift_en,
      data     => pattern,
      msb      => s
    );

  u_len : entity work.morse_length_counter
    port map (
      clk     => CLOCK_50,
      reset_n => reset_n,
      load    => load_en,
      dec_en  => dec_en,
      data    => letter_len,
      last    => last
    );

  u_half : entity work.half_sec_counter
    generic map (CLK_COUNT => CLK_COUNT)
    port map (
      clk     => CLOCK_50,
      reset_n => reset_n,
      clr     => clr_tick,
      tick    => tick
    );

  u_fsm : entity work.morse_fsm
    port map (
      clk      => CLOCK_50,
      reset_n  => reset_n,
      start    => start,
      tick     => tick,
      s        => s,
      last     => last,
      led      => led,
      load     => load,
      shift_en => shift_en,
      dec_en   => dec_en,
      clr_tick => clr_tick
    );

  LEDR(0) <= led;

end architecture rtl;