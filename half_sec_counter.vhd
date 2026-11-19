library ieee;
use ieee.std_logic_1164.all;

entity half_sec_counter is
  generic (
    CLK_COUNT : positive := 25_000_000
  );
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    clr     : in  std_logic;
    tick    : out std_logic
  );
end entity half_sec_counter;

architecture rtl of half_sec_counter is
  signal cnt : integer range 0 to CLK_COUNT - 1;
begin

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      cnt <= 0;
    elsif rising_edge(clk) then
      if clr = '1' or cnt = CLK_COUNT - 1 then
        cnt <= 0;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  tick <= '1' when cnt = CLK_COUNT - 1 else '0';

end architecture rtl;