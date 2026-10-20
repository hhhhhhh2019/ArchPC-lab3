`timescale 1ns / 1ps

module cpu_simulation;
   reg clk;
   reg reset;
   
   f32a_processor uut (.clk(clk),
					   .reset(reset));

   always #5 clk = ~clk;

   initial begin
      $dumpfile("simulation.vcd");
      $dumpvars(0, cpu_simulation);

      clk = 0;
      reset = 1;
	  
      #20;
      reset = 0;

      #5000;

      $display("Симуляция окончена. Открывайте файл в GTKWave!");
      $finish;
   end
endmodule
