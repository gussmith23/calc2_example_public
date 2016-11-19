Make sure you compile the calculator separately from the testbench. I.e.,
compile the Verilog separately from the SystemVerilog:

```bash
vlog *.v
vlog *.sv
```

Then, run the testbench:

```bash
vsim -c top -do "run -all"
```
