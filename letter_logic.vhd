library ieee;
use ieee.std_logic_1164.all;

entity letter_logic is
  port (
    sw      : in  std_logic_vector(2 downto 0);
    pattern : out std_logic_vector(3 downto 0);
    len     : out std_logic_vector(2 downto 0)
  );
end entity letter_logic;

architecture rtl of letter_logic is
begin

  with sw select
    pattern <= "0100" when "000",  -- A
               "1000" when "001",  -- B
               "1010" when "010",  -- C
               "1000" when "011",  -- D
               "0000" when "100",  -- E
               "0010" when "101",  -- F
               "1100" when "110",  -- G
               "0000" when "111",  -- H
               "0000" when others;

  with sw select
    len <= "010" when "000",  -- A: 2 simbolos
           "100" when "001",  -- B: 4
           "100" when "010",  -- C: 4
           "011" when "011",  -- D: 3
           "001" when "100",  -- E: 1
           "100" when "101",  -- F: 4
           "011" when "110",  -- G: 3
           "100" when "111",  -- H: 4
           "001" when others;

end architecture rtl;