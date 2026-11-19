library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_morse_top is
end entity tb_morse_top;

architecture sim of tb_morse_top is

  constant T_CLK : time    := 20 ns;  -- reloj de 50 MHz
  constant TICKS : integer := 5;      -- ciclos de reloj por "0.5 s" simulado

  constant MODE_HOLD    : integer := 0;  -- KEY1 mantenido toda la letra
  constant MODE_PULSE   : integer := 1;  -- pulsacion corta
  constant MODE_DISTURB : integer := 2;  -- pulsacion corta + perturbacion

  signal CLK  : std_logic := '0';
  signal SW   : std_logic_vector(2 downto 0) := "000";
  signal KEY  : std_logic_vector(1 downto 0) := "10";  -- KEY0=0 (reset), KEY1=1 (suelto)
  signal LEDR : std_logic_vector(0 downto 0);
  signal done : boolean := false;

  -- Morse esperado: '.' punto, '-' raya, ' ' = sin simbolo
  type morse_table_t is array (0 to 7) of string(1 to 4);
  constant MORSE   : morse_table_t := (".-  ", "-...", "-.-.", "-.. ", ".   ", "..-.", "--. ", "....");
  constant LETTERS : string(1 to 8) := "ABCDEFGH";

begin

  -- Generador de reloj
  clk_gen : process
  begin
    while not done loop
      CLK <= '0'; wait for T_CLK / 2;
      CLK <= '1'; wait for T_CLK / 2;
    end loop;
    wait;
  end process clk_gen;

  -- Dispositivo bajo prueba (con tiempo reducido)
  dut : entity work.morse_top
    generic map (CLK_COUNT => TICKS)
    port map (
      CLOCK_50 => CLK,
      SW       => SW,
      KEY      => KEY,
      LEDR     => LEDR
    );

  -- Vigilante: si la simulacion se cuelga, falla en lugar de quedarse esperando
  watchdog : process
  begin
    wait until done for 2 ms;
    if not done then
      report "WATCHDOG: la simulacion no termino a tiempo" severity failure;
    end if;
    wait;
  end process watchdog;

  -- Estimulos y verificacion
  stim : process

    variable errors : integer := 0;

    procedure fail(msg : in string) is
    begin
      report "FALLO: " & msg severity error;
      errors := errors + 1;
    end procedure;

    -- Mide cuantos ciclos dura el nivel actual de LEDR(0).
    -- Se llama justo en un flanco de bajada donde LEDR(0) = lvl.
    procedure run_len(lvl : in std_logic; cyc : out integer) is
      variable c : integer := 1;
    begin
      loop
        wait until falling_edge(CLK);
        exit when LEDR(0) /= lvl;
        c := c + 1;
        exit when c > 10 * TICKS;  -- limite: ninguna fase dura tanto
      end loop;
      cyc := c;
    end procedure run_len;

    procedure check_letter(code : in integer; mode : in integer) is
      variable cyc : integer;
      variable i   : integer;
      variable sym : string(1 to 4);
      variable tag : string(1 to 1);
    begin
      sym := MORSE(code);
      SW <= std_logic_vector(to_unsigned(code, 3));
      wait for 5 * T_CLK;                      -- deja pasar los sincronizadores
      KEY(1) <= '0';                           -- presiona KEY1
      if mode /= MODE_HOLD then
        wait for 2 * T_CLK;
        KEY(1) <= '1';                         -- pulsacion corta
      end if;

      wait until LEDR(0) = '1' for 100 * T_CLK;
      if LEDR(0) /= '1' then
        fail("el LED nunca encendio para la letra " & LETTERS(code + 1));
        KEY(1) <= '1';
        return;
      end if;

      if mode = MODE_DISTURB then
        -- a mitad de la letra: cambia SW y vuelve a presionar KEY1
        SW     <= transport "111" after 2 * T_CLK;
        KEY(1) <= transport '0'   after 2 * T_CLK;
        KEY(1) <= transport '1'   after 5 * T_CLK;
      end if;

      wait until falling_edge(CLK);
      i := 1;
      while i <= 4 and sym(i) /= ' ' loop
        -- simbolo encendido
        run_len('1', cyc);
        if sym(i) = '.' then
          if cyc /= 1 * TICKS then
            fail("letra " & LETTERS(code + 1) & ", simbolo " & integer'image(i) &
                 ": punto dura " & integer'image(cyc) & " ciclos (esperado " &
                 integer'image(1 * TICKS) & ")");
          end if;
        else
          if cyc /= 3 * TICKS then
            fail("letra " & LETTERS(code + 1) & ", simbolo " & integer'image(i) &
                 ": raya dura " & integer'image(cyc) & " ciclos (esperado " &
                 integer'image(3 * TICKS) & ")");
          end if;
        end if;
        -- pausa entre simbolos
        if i < 4 and sym(i + 1) /= ' ' then
          run_len('0', cyc);
          if cyc /= TICKS then
            fail("letra " & LETTERS(code + 1) & ", pausa " & integer'image(i) &
                 " dura " & integer'image(cyc) & " ciclos (esperado " &
                 integer'image(TICKS) & ")");
          end if;
        end if;
        i := i + 1;
      end loop;

      -- Terminada la letra, el LED debe quedar apagado (no se repite)
      for k in 1 to 20 * TICKS loop
        wait until falling_edge(CLK);
        if LEDR(0) /= '0' then
          fail("la letra " & LETTERS(code + 1) & " se repitio o el LED quedo encendido de mas");
          exit;
        end if;
      end loop;

      KEY(1) <= '1';
      wait for 5 * T_CLK;
      report "Letra " & LETTERS(code + 1) & " [" & MORSE(code) & "] verificada (modo " &
             integer'image(mode) & ")" severity note;
    end procedure check_letter;

  begin
    -- Reset inicial (KEY0 = 0)
    wait for 3 * T_CLK;
    KEY(0) <= '1';
    wait for 5 * T_CLK;
    if LEDR(0) /= '0' then
      fail("el LED debe estar apagado despues del reset");
    end if;

    -- Prueba 1: KEY1 mantenido presionado
    for c in 0 to 7 loop
      check_letter(c, MODE_HOLD);
    end loop;
    report "Prueba 1 terminada (KEY1 mantenido)" severity note;

    -- Prueba 2: pulsacion corta
    for c in 0 to 7 loop
      check_letter(c, MODE_PULSE);
    end loop;
    report "Prueba 2 terminada (pulsacion corta)" severity note;

    -- Prueba 3: perturbacion a mitad de la letra
    check_letter(1, MODE_DISTURB);  -- B
    check_letter(3, MODE_DISTURB);  -- D
    report "Prueba 3 terminada (perturbacion)" severity note;

    -- Prueba 4: reset asincrono a mitad de una letra
    SW <= "001";  -- B
    wait for 5 * T_CLK;
    KEY(1) <= '0'; wait for 2 * T_CLK; KEY(1) <= '1';
    wait until LEDR(0) = '1' for 100 * T_CLK;
    wait for 2 * T_CLK;
    KEY(0) <= '0';                           -- reset en medio de la raya
    wait for 1 ns;
    if LEDR(0) /= '0' then
      fail("el reset asincrono no apago el LED de inmediato");
    end if;
    wait for 3 * T_CLK;
    KEY(0) <= '1';
    for k in 1 to 20 * TICKS loop
      wait until falling_edge(CLK);
      if LEDR(0) /= '0' then
        fail("el LED se encendio despues del reset sin presionar KEY1");
        exit;
      end if;
    end loop;
    check_letter(4, MODE_PULSE);             -- E funciona despues del reset
    report "Prueba 4 terminada (reset asincrono)" severity note;

    -- Resultado final
    if errors = 0 then
      report "PRUEBA EXITOSA: todas las verificaciones pasaron" severity note;
    else
      report "PRUEBA FALLIDA: " & integer'image(errors) & " error(es)" severity failure;
    end if;
    done <= true;
    wait;
  end process stim;

end architecture sim;