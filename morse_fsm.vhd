library ieee;
use ieee.std_logic_1164.all;

entity morse_fsm is
  port (
    clk      : in  std_logic;
    reset_n  : in  std_logic;  -- reset asincrono, activo en bajo (KEY0)
    start    : in  std_logic;  -- pulso de 1 ciclo al presionar KEY1
    tick     : in  std_logic;  -- pulso de 1 ciclo cada 0.5 s
    s        : in  std_logic;  -- MSB del registro: 0 = punto, 1 = raya
    last     : in  std_logic;  -- el simbolo actual es el ultimo (contador = 1)
    led      : out std_logic;  -- salida hacia LEDR0
    load     : out std_logic;  -- carga registro y contador (letra)
    shift_en : out std_logic;  -- desplaza el registro Morse
    dec_en   : out std_logic;  -- decrementa el contador de longitud
    clr_tick : out std_logic   -- pone en cero el contador de 0.5 s
  );
end entity morse_fsm;

architecture behavior of morse_fsm is

  type state_type is (IDLE, DOT, D1, D2, D3, SHIFT, GAP);
  signal y_Q : state_type;  -- estado presente
  signal Y_D : state_type;  -- estado siguiente

begin

  -- --------------------------------------------------------------------------
  -- Proceso 1: memoria de estado (reset asincrono, activo en bajo)
  -- --------------------------------------------------------------------------
  p_state_reg : process (clk, reset_n)
  begin
    if reset_n = '0' then
      y_Q <= IDLE;
    elsif rising_edge(clk) then
      y_Q <= Y_D;
    end if;
  end process p_state_reg;

  -- --------------------------------------------------------------------------
  -- Proceso 2: transicion de estados (tabla de estados)
  -- --------------------------------------------------------------------------
  p_next_state : process (y_Q, start, tick, s, last)
  begin
    Y_D <= y_Q;  -- por defecto se queda en el mismo estado

    case y_Q is

      when IDLE =>
        if start = '1' then
          if s = '0' then
            Y_D <= DOT;
          else
            Y_D <= D1;
          end if;
        end if;

      when DOT =>
        if tick = '1' then
          Y_D <= SHIFT;
        end if;

      when D1 =>
        if tick = '1' then
          Y_D <= D2;
        end if;

      when D2 =>
        if tick = '1' then
          Y_D <= D3;
        end if;

      when D3 =>
        if tick = '1' then
          Y_D <= SHIFT;
        end if;

      when SHIFT =>
        if last = '1' then
          Y_D <= IDLE;
        else
          Y_D <= GAP;
        end if;

      when GAP =>
        if tick = '1' then
          if s = '0' then
            Y_D <= DOT;
          else
            Y_D <= D1;
          end if;
        end if;

      when others =>
        Y_D <= IDLE;

    end case;
  end process p_next_state;

  -- --------------------------------------------------------------------------
  -- Proceso 3: logica de salida (Moore: depende solo del estado presente)
  -- --------------------------------------------------------------------------
  p_output : process (y_Q)
  begin
    -- valores por defecto
    led      <= '0';
    load     <= '0';
    shift_en <= '0';
    dec_en   <= '0';
    clr_tick <= '0';

    case y_Q is

      when IDLE =>
        load     <= '1';
        clr_tick <= '1';

      when DOT | D1 | D2 | D3 =>
        led <= '1';

      when SHIFT =>
        shift_en <= '1';
        dec_en   <= '1';

      when GAP =>
        null;

      when others =>
        null;

    end case;
  end process p_output;

end architecture behavior;