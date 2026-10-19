module f32a_processor(input wire clk,
					  input wire reset);
   wire [29:0] mem_address;
   wire [31:0] mem_to_cu;
   wire [31:0] cu_to_mem;
   wire        mem_read;
   wire        mem_write;

   ram ram0(.clk(clk),
			.address(mem_address),
			.in(cu_to_mem),
			.out(mem_to_cu),
			.read(mem_read),
			.write(mem_write));

   control_unit cu(.clk(clk),
				   .reset(reset),
                   .mem_address_(mem_address),
                   .mem_in(mem_to_cu),
                   .mem_out(cu_to_mem),
                   .mem_read_(mem_read),
                   .mem_write_(mem_write));
endmodule
