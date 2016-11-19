`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "scoreboard_monitor_callback.sv"
`include "scoreboard_driver_callback.sv"

class Environment;
  mailbox gen2drv[];
  event drv2gen[];
  virtual Port_ifc.Driver port_ifc_d[];
  virtual Port_ifc.Monitor port_ifc_m[];
  Generator gen[];
  Driver drv[];
  Monitor mon[];
  Scoreboard scoreboard;
  
  extern function new(virtual Port_ifc.Driver port_ifc_d[0:3],
      virtual Port_ifc.Monitor port_ifc_m[0:3]);
  extern function void build();
  extern task run();
endclass : Environment

function Environment::new(virtual Port_ifc.Driver port_ifc_d[0:3],
    virtual Port_ifc.Monitor port_ifc_m[0:3]);
  this.port_ifc_d = new[4];
  foreach (port_ifc_d[i]) this.port_ifc_d[i] = port_ifc_d[i];
  this.port_ifc_m = new[4];
  foreach (port_ifc_m[i]) this.port_ifc_m[i] = port_ifc_m[i];
endfunction

function void Environment::build();
  gen = new[4];
  drv = new[4];
  gen2drv = new[4];
  drv2gen = new[4];

  foreach (gen[i]) begin
    gen2drv[i] = new();
    gen[i] = new(gen2drv[i], drv2gen[i]);
    drv[i] = new(gen2drv[i], drv2gen[i], port_ifc_d[i], i);
  end

  mon = new[4];
  foreach (mon[i]) begin
    mon[i] = new(port_ifc_m[i], i);
  end

  scoreboard = new();

  // Connect monitors to scoreboard.
  begin
    ScoreboardMonitorCallback smc = new(scoreboard);
    foreach(mon[i]) mon[i].callback_queue.push_back(smc);
  end

  // Connect drivers to scoreboard.
  begin
    ScoreboardDriverCallback sdc = new(scoreboard);
    foreach(drv[i]) drv[i].callback_queue.push_back(sdc);
  end

endfunction : build

task Environment::run();
  int num_gen_running = 4;

  foreach (gen[i]) begin
    int j = i;
    fork
      begin
        gen[j].run();
        num_gen_running--;
      end
      drv[j].run();
    join_none
  end

  foreach (mon[i]) begin
    int j = i;
    fork 
      mon[j].run();
    join_none
  end

  fork : timeout_block
    wait (num_gen_running == 0);
    begin 
      repeat(1_000_000) @(port_ifc_d[0].cbd);
      $display("Error: generators timed out.");
    end
  join_any
  disable timeout_block;

  repeat(1_000) @(port_ifc_d[0].cbd);
endtask : run

`endif
