module ram #(parameter INIT = "ram.hex"
			 )(input wire        clk,
			   input wire [29:0] address,
			   input wire [31:0] in,
			   output reg [31:0] out,
			   input wire        write,
			   input wire        read);
   reg [31:0] mem[0:(1<<11)-1];
   
   initial $readmemh(INIT, mem);
   
   always @(posedge clk) begin
      if (write) mem[address] <= in;
      if (read)  out          <= mem[address];
   end
endmodule
