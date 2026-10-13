# PARCIAL-INDIVIDUAL-MARIA-NAVIA
Parcial final de Maria Fernanda Navia Urbano
# Laboratorio 7 – Parte IV: Codificador Morse con FSM (VHDL)

**Autor:** MARIA FERNANDA NAVA URBANO  
**Curso:** DISEÑO DE CIRCUITOS DIGITALES CON VHDL 
**Herramientas:** Quartus II 13.1 Web Edition y ModelSim-Altera Starter Edition 10.1d

## 1. Descripción

Codificador Morse para las letras A–H implementado con una máquina de estados finitos (FSM) en VHDL.

- `SW[2:0]` selecciona la letra (000 = A, 001 = B, ..., 111 = H).
- `KEY1` inicia la transmisión.
- `KEY0` es el reset asíncrono (activo en bajo, como todos los KEY de la placa DE).
- `LEDR0` muestra el código Morse: punto = 0.5 s encendido, raya = 1.5 s encendido y pausa de 0.5 s apagado entre símbolos (la guía no define la pausa; se eligió 0.5 s).

## 2. Estructura del repositorio

```
src/   Código VHDL del diseño (6 archivos)
tb/    Testbench y script de ModelSim
docs/  Diagrama de la FSM y capturas de evidencia
```

## 3. Diseño

### 3.1 Diagrama de la FSM

FSM tipo Moore de 7 estados.

![Diagrama de la FSM](docs/diagrama_fsm.png)

| Estado | LEDR0 | Otras salidas | Descripción |
|---|---|---|---|
| IDLE | 0 | load=1, clr_tick=1 | Espera `start`. Carga la letra seleccionada. |
| DOT | 1 | – | Punto: 1 tick (0.5 s). |
| D1, D2, D3 | 1 | – | Raya: 3 ticks (1.5 s). |
| SHIFT | 0 | shift_en=1, dec_en=1 | 1 ciclo: desplaza el registro y decrementa el contador. |
| GAP | 0 | – | Pausa de 1 tick (0.5 s) entre símbolos. |

La FSM está escrita con **tres procesos**: memoria de estado, lógica de transición de estados y lógica de salida (`src/morse_fsm.vhd`).

### 3.2 Módulos

| Archivo | Función |
|---|---|
| `morse_top.vhd` | Módulo superior: sincroniza entradas, detecta el flanco de KEY1 y conecta todos los bloques. |
| `morse_fsm.vhd` | FSM de 3 procesos. |
| `letter_logic.vhd` | Convierte SW[2:0] en el patrón Morse (0 = punto, 1 = raya) y su longitud. |
| `morse_shift_reg.vhd` | Registro de desplazamiento de 4 bits con el patrón. |
| `morse_length_counter.vhd` | Cuenta los símbolos restantes y genera `last`. |
| `half_sec_counter.vhd` | Genera `tick` cada 0.5 s (25 000 000 ciclos a 50 MHz). |

### 3.3 Decisiones de diseño

- `start` es un pulso de un ciclo en el flanco de presión de KEY1, por lo que mantener el botón presionado no repite la letra.
- SW y KEY1 pasan por sincronizadores de dos flip-flops, porque son asíncronos respecto al reloj.
- La carga de la letra se bloquea en el ciclo en que llega `start`, para que el primer símbolo y el patrón cargado correspondan siempre a la misma letra.
- El contador de 0.5 s se pone en cero en IDLE para que el primer símbolo dure exactamente 0.5 s.

## 4. Testbench

`tb/tb_morse_top.vhd` es un testbench autoverificable. Usa `CLK_COUNT = 5` en lugar de 25 000 000 para que la simulación sea rápida, y mide la duración en ciclos de cada punto (1 tick), raya (3 ticks) y pausa (1 tick). Pruebas:

1. Las 8 letras A–H con KEY1 mantenido presionado (la letra no debe repetirse).
2. Las 8 letras con pulsación corta de KEY1.
3. Perturbación: SW y KEY1 cambian a mitad de una letra (deben ignorarse).
4. Reset asíncrono (KEY0) a mitad de una letra, y una letra nueva después.

### Cómo simular

En ModelSim: `File > Change Directory` a una carpeta con los 6 archivos de `src/` y los de `tb/`, y en el Transcript ejecutar:

```
do run_sim.do
```

### Resultados

Letras verificadas:

![Transcript: letras verificadas](docs/transcript_letras.png)

Resultado final:

![Transcript: prueba exitosa](docs/transcript_exito.png)

Formas de onda de la letra A (punto y raya):

![Formas de onda letra A](docs/waveform_letra_A.png)

## 5. Síntesis en Quartus

Compilación completa sin errores (0 errores, 11 advertencias):

![Reporte de compilación](docs/compilation_report.png)

Circuito sintetizado (RTL Viewer):

![RTL Viewer](docs/rtl_viewer.png)

Máquina de estados reconocida por Quartus (7 estados; Quartus la codificó en One-Hot):

![State Machine Viewer](docs/state_machine_viewer.png)

## 6. Limitaciones

- **No se realizó la prueba en la FPGA**, por no disponer de la placa. El diseño se verificó mediante simulación (testbench autoverificable en ModelSim) y síntesis en Quartus.
- Las asignaciones de pines dependen de la placa y no se incluyen.
