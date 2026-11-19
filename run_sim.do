# Script de ModelSim: compila, simula y muestra las formas de onda.
# Uso: en ModelSim, File > Change Directory (carpeta con los .vhd) y luego:
#      do run_sim.do
quit -sim
if {[file exists work]} { vdel -lib work -all }
vlib work
vcom -93 letter_logic.vhd morse_shift_reg.vhd morse_length_counter.vhd half_sec_counter.vhd morse_fsm.vhd morse_top.vhd tb_morse_top.vhd
vsim -t 1ns work.tb_morse_top
add wave -divider {Entradas}
add wave -label CLOCK_50 /tb_morse_top/CLK
add wave -label KEY0_reset /tb_morse_top/KEY(0)
add wave -label KEY1_start /tb_morse_top/KEY(1)
add wave -label SW /tb_morse_top/SW
add wave -divider {FSM}
add wave -label estado /tb_morse_top/dut/u_fsm/y_Q
add wave -label start /tb_morse_top/dut/start
add wave -label tick /tb_morse_top/dut/tick
add wave -label s_msb /tb_morse_top/dut/s
add wave -label last /tb_morse_top/dut/last
add wave -divider {Salida}
add wave -label LEDR0 /tb_morse_top/LEDR(0)
run -all
wave zoom full