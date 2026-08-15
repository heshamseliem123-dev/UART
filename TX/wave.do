onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -divider "Clock & Reset"
add wave -noupdate /tb_uart_tx/CLK
add wave -noupdate /tb_uart_tx/RST

add wave -divider "Inputs"
add wave -noupdate /tb_uart_tx/DATA_VALID
add wave -noupdate -radix hexadecimal /tb_uart_tx/P_DATA
add wave -noupdate /tb_uart_tx/PAR_EN
add wave -noupdate /tb_uart_tx/PAR_TYP

add wave -divider "Outputs"
add wave -noupdate /tb_uart_tx/TX_OUT
add wave -noupdate /tb_uart_tx/Busy

add wave -divider "Internal (DUT) - FSM & datapath"
add wave -noupdate /tb_uart_tx/DUT/u_fsm/state
add wave -noupdate /tb_uart_tx/DUT/mux_sel
add wave -noupdate /tb_uart_tx/DUT/load
add wave -noupdate /tb_uart_tx/DUT/ser_en
add wave -noupdate /tb_uart_tx/DUT/ser_data
add wave -noupdate /tb_uart_tx/DUT/ser_done
add wave -noupdate /tb_uart_tx/DUT/par_bit
add wave -noupdate -radix hexadecimal /tb_uart_tx/DUT/data_snapshot

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
update
WaveRestoreZoom {0 ns} {350 ns}
