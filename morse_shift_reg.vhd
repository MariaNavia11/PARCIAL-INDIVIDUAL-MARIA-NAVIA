library ieee;
use ieee.std_logic_1164.all;

entity morse_shift_reg is
  port (
    clk      : in  std_logic;
    reset_n  : in  std_logic;
    load     : in  std_logic;
    shift_en : in  std_logic;
    data     : in  std_logic_vector(3 downto 0);
    msb      : out std_logic
  );
end entity morse_shift_reg;

architecture rtl of morse_shift_reg is
  signal q : std_logic_vector(3 downto 0);
begin

  process (clk, reset_n)
  begin
    if reset_n = '0' then
      q <= (others => '0');
    elsif rising_edge(clk) then
      if load = '1' then
        q <= data;
      elsif shift_en = '1' then
        q <= q(2 downto 0) & '0';
      end if;
    end if;
  end process;

  msb <= q(3);

end architecture rtl;