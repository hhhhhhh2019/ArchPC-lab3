module control_unit(input wire         clk,
					input wire         reset,
					output wire [29:0] mem_address_,
					input wire [31:0]  mem_in,
					output reg [31:0]  mem_out,
					output wire        mem_read_,
					output wire        mem_write_);
   reg [46:0] rom[1023:0];
   reg [9:0]    mc;

   initial begin
      `include "microcode.vh"
   end

   reg [31:0]  T, S, R, A, B, buffer;
   reg [31:0]  pc, dsp, rsp;
   reg [7:0]   cmd;

   reg [31:0]  bus_input;
   reg [31:0]  bus_output;

   wire [1:0]  m_type = rom[mc][1:0];

   wire [9:0]  m_goto_addr;
   wire [2:0]  m_goto_mux_reg;
   wire [31:0] m_goto_mask;
   assign {m_goto_addr, m_goto_mux_reg, m_goto_mask} = rom[mc][46:2];

   reg [31:0] m_goto_cond_reg;
   wire       m_goto_cond = (m_goto_cond_reg & m_goto_mask) == 0;

   always @(*) begin
	  case (m_goto_mux_reg)
		3'b000:  m_goto_cond_reg = cmd;
		3'b001:  m_goto_cond_reg = A;
		3'b010:  m_goto_cond_reg = buffer;
		3'b011:  m_goto_cond_reg = T;
		3'b100:  m_goto_cond_reg = B;
		3'b101:  m_goto_cond_reg = pc;
		3'b110:  m_goto_cond_reg = R;
		3'b111:  m_goto_cond_reg = S;
	  endcase
   end

   wire [1:0] m_offset_pc;
   wire [1:0] m_offset_dsp;
   wire [1:0] m_offset_rsp;
   assign {m_offset_pc, m_offset_dsp, m_offset_rsp} = rom[mc][7:2];


   wire [1:0] m_alu_mux_input1;
   wire [1:0] m_alu_mux_input2;
   wire [2:0] m_alu_mux_operation;

   wire [2:0] m_bus_mux_input;
   wire [2:0] m_bus_mux_shift;
   wire       m_bus_shift_right;
   wire [1:0] m_bus_mux_or;
   wire [2:0] m_bus_mux_mask;
   wire [2:0] m_bus_mux_output;

   assign {m_alu_mux_input1, m_alu_mux_input2, m_alu_mux_operation, m_bus_mux_input, m_bus_mux_shift, m_bus_shift_right, m_bus_mux_or, m_bus_mux_mask, m_bus_mux_output} = rom[mc][23:2];

   reg [1:0]  bus_shift;
   reg [31:0] bus_mask;
   reg [31:0] bus_or;

   reg [31:0] ALU_input1;
   reg [31:0] ALU_input2;
   reg [31:0] ALU;

   always @(*) begin
      case (m_alu_mux_input1)
        2'b00: ALU_input1 = T;
        2'b01: ALU_input1 = A;
        2'b10: ALU_input1 = R;
      endcase

      case (m_alu_mux_input2)
        2'b00: ALU_input2 = S;
        2'b01: ALU_input2 = 1;
        2'b10: ALU_input2 = -1;
      endcase

      case (m_alu_mux_operation)
        3'b000: ALU = ALU_input1 + ALU_input2;
        3'b001: ALU = ALU_input1 & ALU_input2;
        3'b010: ALU = ALU_input1 ^ ALU_input2;
        3'b011: ALU =~ALU_input1;
        3'b100: ALU = ALU_input1 << 1;
        3'b101: ALU = ALU_input1 >> 1;
      endcase

	  case (m_bus_mux_input)
        default: bus_input = 'b0;
		3'b001: bus_input = mem_in;
		3'b010: bus_input = buffer;
		3'b011: bus_input = T;
        3'b100: bus_input = ALU;
		3'b110: bus_input = R;
		3'b111: bus_input = S;
	  endcase

	  case (m_bus_mux_shift)
		default: bus_shift = 'b0;
		3'b001: bus_shift = A[1:0];
		3'b010: bus_shift = buffer[1:0];
		3'b100: bus_shift = B[1:0];
		3'b101: bus_shift = pc[1:0];
	  endcase

	  case (m_bus_mux_or)
		default: bus_or = 'b0;
		2'b01: bus_or = mem_in;
		2'b10: bus_or = buffer;
		2'b11: bus_or = T;
	  endcase

	  case (m_bus_mux_mask)
		default: bus_mask = 32'hffffffff;
		3'b001: bus_mask = 32'hffffffff >> buffer[1:0]*8;
		3'b010: bus_mask = 32'hffffffff >> A[1:0]*8;
		3'b011: bus_mask = 32'hffffffff >> B[1:0]*8;
		3'b100: bus_mask = 32'hffffffff << (4-buffer[1:0])*8;
		3'b101: bus_mask = 32'hffffffff << (4-A[1:0])*8;
		3'b110: bus_mask = 32'hffffffff << (4-B[1:0])*8;
	  endcase

	  if (m_bus_shift_right)
		case (bus_shift)
		  2'b00: bus_output = 'b0;
		  2'b01: bus_output = bus_input >> 24;
		  2'b10: bus_output = bus_input >> 16;
		  2'b11: bus_output = bus_input >> 8;
		endcase
	  else
		case (bus_shift)
		  2'b00: bus_output = bus_input;
		  2'b01: bus_output = bus_input << 8;
		  2'b10: bus_output = bus_input << 16;
		  2'b11: bus_output = bus_input << 24;
		endcase
   end


   wire [2:0] m_mem_mux_addr;
   reg [29:0] mem_address;
   wire       m_mem_address_plus_4;

   wire       mem_read, mem_write;


   assign mem_address_ = mem_address;
   assign mem_read_ = mem_read & rom[mc][1:0] == 2'b11;
   assign mem_write_ = mem_write & rom[mc][1:0] == 2'b11;
   assign {m_mem_mux_addr, mem_read, mem_write, m_mem_address_plus_4} = rom[mc][7:2];


   always @(posedge clk or posedge reset) begin
	  if (reset) begin
		 mc <= 'b0;
		 T <= 'b1;
		 S <= 'b10;
		 R <= 'b11;
		 A <= 'b100;
		 B <= 'b101;
		 buffer <= 'b0;
		 pc  <= 32'h0000;
		 dsp <= 32'h1000;
		 rsp <= 32'h2000;
	  end else begin
		 mc <= mc + 1;

		 case (m_type)
		   2'b00: // goto
			 if (m_goto_cond) mc <= m_goto_addr;
		   2'b01: begin // inc/dec
			  pc <= pc + (m_offset_pc == 2'b10 ? 32'd4 : (m_offset_pc == 2'b01 ? 32'd1 : 32'd0));
			  dsp <= dsp + (m_offset_dsp == 2'b01 ? 32'd4 : (m_offset_dsp == 2'b10 ? -32'd4 : 32'd0));
			  rsp <= rsp + (m_offset_rsp == 2'b01 ? 32'd4 : (m_offset_rsp == 2'b10 ? -32'd4 : 32'd0));
		   end
		   2'b10: begin // move registers + ALU
			  case (m_bus_mux_output)
				3'b000: cmd <= bus_output[31:24];
				3'b001: A <= bus_output | (bus_or & bus_mask);
				3'b010: buffer <= bus_output | (bus_or & bus_mask);
				3'b011: T <= bus_output | (bus_or & bus_mask);
				3'b100: B <= bus_output | (bus_or & bus_mask);
				3'b101: mem_out <= bus_output | (bus_or & bus_mask);
				3'b110: R <= bus_output | (bus_or & bus_mask);
				3'b111: S <= bus_output | (bus_or & bus_mask);
			  endcase
		   end
		   2'b11: begin // memory
			  case (m_mem_mux_addr)
				3'b000: mem_address <= rsp[31:2];
				3'b001: mem_address <= A[31:2];
				3'b010: mem_address <= buffer[31:2];
				3'b011: mem_address <= dsp[31:2];
				3'b100: mem_address <= B[31:2];
				3'b101: mem_address <= pc[31:2];
			  endcase

              if (m_mem_address_plus_4)
                mem_address <= mem_address + 4;
		   end
		 endcase
	  end
   end
endmodule
