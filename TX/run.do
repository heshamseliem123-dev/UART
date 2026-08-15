# 1. (Re)create a clean work library
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# 2. Compile every RTL + testbench file listed in sourcefile.txt
vlog -f sourcefile.txt

# 3. Load the TESTBENCH as the top (note: lowercase, matches the
#    module name inside tb_uart_tx.v exactly)
vsim -voptargs="+acc" work.tb_uart_tx

# 4. Load the saved wave layout
do wave.do

# 5. Run to completion
run -all
