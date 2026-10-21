module control_unit(input wire        clk,
                    input wire        reset,
                    output reg [29:0] mem_address,
                    input wire [31:0] mem_in,
                    output reg [31:0] mem_out,
                    output wire       mem_read,
                    output wire       mem_write);
   reg [9:0] mc;

   wire [1:0] m_type;

   wire [9:0] m_goto_addr;
   wire [2:0] m_goto_mux_reg;
   wire [31:0] m_goto_mask;

   wire [1:0]  m_offset_pc;
   wire [1:0]  m_offset_dsp;
   wire [1:0]  m_offset_rsp;

   wire [1:0]  m_alu_mux_input1;
   wire [1:0]  m_alu_mux_input2;
   wire [2:0]  m_alu_mux_operation;

   wire [2:0]  m_bus_mux_input;
   wire [2:0]  m_bus_mux_shift;
   wire        m_bus_shift_right;
   wire [1:0]  m_bus_mux_or;
   wire [2:0]  m_bus_mux_mask;
   wire [2:0]  m_bus_mux_output;

   wire        m_a31_t0;
   wire        m_set_eam;
   wire        m_reset_carry;

   wire [2:0]  m_mem_mux_addr;
   wire        m_mem_address_plus_4;

   wire        m_mem_read;
   wire        m_mem_write;

   rom_microcode rom_microcode(.addr(mc),
                               .m_type(m_type),
                               .m_goto_addr(m_goto_addr),
                               .m_goto_mux_reg(m_goto_mux_reg),
                               .m_goto_mask(m_goto_mask),
                               .m_offset_pc(m_offset_pc),
                               .m_offset_dsp(m_offset_dsp),
                               .m_offset_rsp(m_offset_rsp),
                               .m_alu_mux_input1(m_alu_mux_input1),
                               .m_alu_mux_input2(m_alu_mux_input2),
                               .m_alu_mux_operation(m_alu_mux_operation),
                               .m_bus_mux_input(m_bus_mux_input),
                               .m_bus_mux_shift(m_bus_mux_shift),
                               .m_bus_shift_right(m_bus_shift_right),
                               .m_bus_mux_or(m_bus_mux_or),
                               .m_bus_mux_mask(m_bus_mux_mask),
                               .m_bus_mux_output(m_bus_mux_output),
                               .m_a31_t0(m_a31_t0),
                               .m_set_eam(m_set_eam),
                               .m_reset_carry(m_reset_carry),
                               .m_mem_mux_addr(m_mem_mux_addr),
                               .m_mem_address_plus_4(m_mem_address_plus_4),
                               .m_mem_read(m_mem_read),
                               .m_mem_write(m_mem_write));

   reg [31:0]  T, S, R, A, B, buffer;
   reg [31:0]  pc, dsp, rsp;
   reg [7:0]   cmd;
   reg         carry, eam;


   reg [31:0]  goto_cond_reg;
   wire        goto_cond = (goto_cond_reg & m_goto_mask) == 0;

   always @(*) begin
	  case (m_goto_mux_reg)
		3'b000:  goto_cond_reg = {24'b0, cmd};
		3'b001:  goto_cond_reg = A;
		3'b010:  goto_cond_reg = buffer;
		3'b011:  goto_cond_reg = T;
		3'b100:  goto_cond_reg = B;
		3'b101:  goto_cond_reg = pc;
		3'b110:  goto_cond_reg = R;
		3'b111:  goto_cond_reg = S;
	  endcase
   end


   reg [1:0]  bus_shift;
   reg [31:0] bus_mask;
   reg [31:0] bus_or;

   reg [31:0] ALU_input1;
   reg [31:0] ALU_input2;
   reg [31:0] ALU_result;
   wire       ALU_carry;

   alu alu(.a(ALU_input1),
           .b(ALU_input2),
           .operation(m_alu_mux_operation),
           .carry_in(carry),
           .carry_out(ALU_carry),
           .result(ALU_result),
           .eam(eam));

   reg [31:0] bus_input;
   reg [31:0] bus_output;

   always @(*) begin
      case (m_alu_mux_input1)
        2'b00: ALU_input1 = T;
        2'b01: ALU_input1 = A;
        2'b10: ALU_input1 = R;
        default: ALU_input1 = 'b0;
      endcase

      case (m_alu_mux_input2)
        2'b00: ALU_input2 = S;
        2'b01: ALU_input2 = 1;
        2'b10: ALU_input2 = -1;
        default: ALU_input2 = 'b0;
      endcase

      case (m_bus_mux_input)
        default: bus_input = 'b0;
		3'b001: bus_input = mem_in;
		3'b010: bus_input = buffer;
		3'b011: bus_input = T;
        3'b100: bus_input = ALU_result;
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


   assign mem_read = m_mem_read & m_type == 2'b11;
   assign mem_write = m_mem_write & m_type == 2'b11;


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
         carry <= 1'b0;
         eam <= 1'b0;
      end else begin
         mc <= mc + 1;

		 case (m_type)
		   2'b00: // goto
			 if (goto_cond) mc <= m_goto_addr;
		   2'b01: begin // inc/dec
			  pc <= pc + (m_offset_pc == 2'b10 ? 32'd4 : (m_offset_pc == 2'b01 ? 32'd1 : 32'd0));
			  dsp <= dsp + (m_offset_dsp == 2'b01 ? 32'd4 : (m_offset_dsp == 2'b10 ? -32'd4 : 32'd0));
			  rsp <= rsp + (m_offset_rsp == 2'b01 ? 32'd4 : (m_offset_rsp == 2'b10 ? -32'd4 : 32'd0));
		   end
		   2'b10: begin // move registers + ALU
			  if (m_a31_t0)
                A[31] <= T[0];
              else if (m_set_eam)
                eam <= T[0];
              else if (m_reset_carry)
                carry <= 1'b0;
              else case (m_bus_mux_output)
				     3'b000: cmd <= bus_output[31:24];
				     3'b001: A <= bus_output | (bus_or & bus_mask);
				     3'b010: buffer <= bus_output | (bus_or & bus_mask);
				     3'b011: T <= bus_output | (bus_or & bus_mask);
				     3'b100: B <= bus_output | (bus_or & bus_mask);
				     3'b101: mem_out <= bus_output | (bus_or & bus_mask);
				     3'b110: R <= bus_output | (bus_or & bus_mask);
				     3'b111: S <= bus_output | (bus_or & bus_mask);
			       endcase

              if (m_alu_mux_operation == 3'b000 && m_bus_mux_input == 3'b100)
                carry <= ALU_carry;
		   end
		   2'b11: begin // memory
			  case (m_mem_mux_addr)
				3'b000: mem_address <= rsp[31:2];
				3'b001: mem_address <= A[31:2];
				3'b010: mem_address <= buffer[31:2];
				3'b011: mem_address <= dsp[31:2];
				3'b100: mem_address <= B[31:2];
				3'b101: mem_address <= pc[31:2];
                default: mem_address <= 'b0;
			  endcase

              if (m_mem_address_plus_4)
                mem_address <= mem_address + 1;
		   end
		 endcase
      end
   end
endmodule

module rom_microcode(input wire [9:0]   addr,

                     output wire [1:0]  m_type,

                     output wire [9:0]  m_goto_addr,
                     output wire [2:0]  m_goto_mux_reg,
                     output wire [31:0] m_goto_mask,

                     output wire [1:0]  m_offset_pc,
                     output wire [1:0]  m_offset_dsp,
                     output wire [1:0]  m_offset_rsp,

                     output wire [1:0]  m_alu_mux_input1,
                     output wire [1:0]  m_alu_mux_input2,
                     output wire [2:0]  m_alu_mux_operation,

                     output wire [2:0]  m_bus_mux_input,
                     output wire [2:0]  m_bus_mux_shift,
                     output wire        m_bus_shift_right,
                     output wire [1:0]  m_bus_mux_or,
                     output wire [2:0]  m_bus_mux_mask,
                     output wire [2:0]  m_bus_mux_output,

                     output wire        m_a31_t0,
                     output wire        m_set_eam,
                     output wire        m_reset_carry,

                     output wire [2:0]  m_mem_mux_addr,
                     output wire        m_mem_address_plus_4,

                     output wire        m_mem_read,
                     output wire        m_mem_write);
   reg [46:0] rom[1023:0];

   initial begin
`include "microcode.vh"
   end

   assign m_type = rom[addr][1:0];
   assign {m_goto_addr, m_goto_mux_reg, m_goto_mask} = rom[addr][46:2];
   assign {m_offset_pc, m_offset_dsp, m_offset_rsp} = rom[addr][7:2];
   assign {m_a31_t0, m_set_eam, m_reset_carry, m_alu_mux_input1, m_alu_mux_input2, m_alu_mux_operation, m_bus_mux_input, m_bus_mux_shift, m_bus_shift_right, m_bus_mux_or, m_bus_mux_mask, m_bus_mux_output} = rom[addr][26:2];
   assign {m_mem_mux_addr, m_mem_read, m_mem_write, m_mem_address_plus_4} = rom[addr][7:2];
endmodule

module alu(input wire [31:0] a,
           input wire [31:0] b,
           input wire [2:0]  operation,
           input wire        eam,
           output reg [31:0] result,
           input wire        carry_in,
           output reg        carry_out);
   always @(*) begin
      result = 'b0;
      carry_out = 'b0;

      case (operation)
        3'b000: if (eam)
          {carry_out, result} = a + b + carry_in;
        else
          {carry_out, result} = a + b;
        3'b001: result = a & b;
        3'b010: result = a ^ b;
        3'b011: result = ~a;
        3'b100: result = a << 1;
        3'b101: result = a >> 1;
        default: result = 'b0;
      endcase
   end
endmodule
