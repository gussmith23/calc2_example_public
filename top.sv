`include "port_ifc.sv"

program automatic test (Port_ifc.Driver port_ifc_d[0:3],
                        Port_ifc.Monitor port_ifc_m[0:3],
                        output logic reset);
  `include "environment.sv"
  Environment env;

  initial begin
    
    // First, reset the device.
    reset <= 1;
    repeat(7) @(port_ifc_d[0].cbd);
    reset <= 0;

    // Now, set up and run the environment.
    env = new(port_ifc_d, port_ifc_m);
    env.build();
    env.run();
  end
endprogram

module top;

  logic clk;
  logic scan_out, scan_in, reset;

  initial clk <= 0;
  always #5 clk <= ~clk;

  Port_ifc port_ifc_m[4](clk);
  Port_ifc port_ifc_d[4](clk);

  calc2_top calc(
      port_ifc_m[0].data_out, port_ifc_m[1].data_out, port_ifc_m[2].data_out, port_ifc_m[3].data_out,
      port_ifc_m[0].resp_out, port_ifc_m[1].resp_out, port_ifc_m[2].resp_out, port_ifc_m[3].resp_out,
      port_ifc_m[0].tag_out, port_ifc_m[1].tag_out, port_ifc_m[2].tag_out, port_ifc_m[3].tag_out,
      scan_out,
      // Note: the design has three clocks, but we'll just connect them all to one clock
      // for now.
      clk, clk, clk,
      port_ifc_d[0].cmd_in, port_ifc_d[0].data_in, port_ifc_d[0].tag_in, 
      port_ifc_d[1].cmd_in, port_ifc_d[1].data_in, port_ifc_d[1].tag_in, 
      port_ifc_d[2].cmd_in, port_ifc_d[2].data_in, port_ifc_d[2].tag_in, 
      port_ifc_d[3].cmd_in, port_ifc_d[3].data_in, port_ifc_d[3].tag_in, 
      reset, 
      scan_in);

  test test1(port_ifc_d, port_ifc_m, reset);
endmodule
