library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity morse_length_counter is
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    load    : in  std_logic;
    dec_en  : in  std_logic;
    data    : in  std_logic_vector(2 downto 0);
    last    : out std_logic
  );
end entity morse_length_counter;

architecture rtl of morse_length_counter is
  signal cnt : unsigned(2 downto 0);
begin

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      cnt <= (others => '0');
    elsif rising_edge(clk) then
      if load = '1' then
        cnt <= unsigned(data);
      elsif dec_en = '1' and cnt /= 0 then
        cnt <= cnt - 1;
      end if;
    end if;
  end process;

  last <= '1' when cnt = 1 else '0';

end architecture rtl;