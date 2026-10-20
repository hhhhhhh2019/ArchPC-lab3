use strict;
use warnings;
# use English;
use feature 'switch';

my %labels;
my $pc = 0;
my @microcode_lines;

my %registers_index = (
	A => 1,
	ALU => 4,
	B => 4,
	buffer => 2,
	cmd => 0,
	dsp => 3,
	mem_in => 1,
	mem_out => 5,
	pc => 5,
	R => 6,
	rsp => 0,
	S => 7,
	T => 3
    );

while (my $line = <>) {
	$line =~ s/^\s+|\s+$|\s*#.*$//g;
	next if $line =~ /^\s*$/;

	if ($line =~ /^([\w\?\d]+):$/) {
		$labels{$1} = $pc;
		next;
	}

	push @microcode_lines, $line;
	$pc += 1;
}

foreach my $pc (0 .. $#microcode_lines) {
	my $line = $microcode_lines[$pc];

	given ($line) {
		when (/goto/) {
			parse_goto($line, $pc);
		}
		when (/\+=|\-=/) {
			parse_inc_dec($line, $pc);
		}
        when (/mem_address|mem_read|mem_write/) {
            parse_memory($line, $pc);
        }
        when (/\<\-/) {
            parse_move_and_alu($line, $pc);
        }
		default {
			# die "Cannot parse: ", $line;
		}
	}
}

sub parse_goto {
	my $goto_regex = qr/goto\s+(?<target>[\w\?\d]+)/;
	my $if_regex = qr/
	   if \s+
	   (?<register>\w+)
	   (?:
		\[
			(?<high>\d+)
			(?: : (?<low>\d+) )?
		\]
	   )?
	   \s+==\s+0
	/x;

	my ($line, $pc) = @_;

	my $m_goto_addr = 0;
	my $m_goto_mux_reg = 0;
	my $m_goto_mask = 0;

	if ($line =~ $goto_regex) {
        if (!defined $labels{$+{target}}) {
            die $+{target} . " not defiend";
        }
        $m_goto_addr = $labels{$+{target}};
	}

	if ($line =~ $if_regex) {
		$m_goto_mux_reg = $registers_index{$+{register}};

		if (defined $+{high}) {
			$m_goto_mask = (1 << $+{high});

			if (defined $+{low}) {
				$m_goto_mask = ($m_goto_mask << 1) - (1 << $+{low});
			}
		} else {
			$m_goto_mask = 0xffffffff;
		}
	}

	print "rom[$pc] = {10'd$m_goto_addr, 2'd$m_goto_mux_reg, 32'd$m_goto_mask, 2'b00}; // $line\n";
}

sub parse_inc_dec {
	my ($line, $pc) = @_;

	my $m_offset_pc = 0;
	my $m_offset_dsp = 0;
	my $m_offset_rsp = 0;

	if ($line =~ /pc\s+\+=\s+1/) {
		$m_offset_pc = 1;
	}

	if ($line =~ /pc\s+\+=\s+4/) {
		$m_offset_pc = 2;
	}

	if ($line =~ /dsp\s+\+=\s+4/) {
		$m_offset_dsp = 1;
	}

	if ($line =~ /dsp\s+\-=\s+4/) {
		$m_offset_dsp = 2;
	}

	if ($line =~ /rsp\s+\+=\s+4/) {
		$m_offset_rsp = 1;
	}

	if ($line =~ /rsp\s+\-=\s+4/) {
		$m_offset_rsp = 2;
	}

	print "rom[$pc] = {2'd$m_offset_pc, 2'd$m_offset_dsp, 2'd$m_offset_rsp, 2'b01}; // $line\n";
}

sub parse_move_and_alu {
	my ($line, $pc) = @_;
    my $line_saved = $line;

	my $m_alu_mux_input1 = 0;
	my $m_alu_mux_input2 = 0;
	my $m_alu_mux_operation = 0;

	my $m_bus_mux_input = 0;
	my $m_bus_mux_shift = 0;
	my $m_bus_shift_right = 0;
	my $m_bus_mux_or = 0;
	my $m_bus_mux_mask = 0;
	my $m_bus_mux_output = 0;

	if ($line =~ /ALU\s+\<\-\s+T/)   { $m_alu_mux_input1 = 0; }
	if ($line =~ /ALU\s+\<\-\s+A/)   { $m_alu_mux_input1 = 1; }
	if ($line =~ /ALU\s+\<\-\s+R/)   { $m_alu_mux_input1 = 2; }
	if ($line =~ /ALU\s+\<\-\s+S/)   { $m_alu_mux_input2 = 0; }
	if ($line =~ /ALU\s+\<\-\s+1/)   { $m_alu_mux_input2 = 1; }
	if ($line =~ /ALU\s+\<\-\s+\-1/) { $m_alu_mux_input2 = 2; }

	if ($line =~ /\+/)   { $m_alu_mux_operation = 0; }
	if ($line =~ /\&/)   { $m_alu_mux_operation = 1; }
	if ($line =~ /\^/)   { $m_alu_mux_operation = 2; }
	if ($line =~ /\~/)   { $m_alu_mux_operation = 3; }
	if ($line =~ /\<\</) { $m_alu_mux_operation = 4; }
	if ($line =~ /\>\>/) { $m_alu_mux_operation = 5; }

    # out <- inp
    # out <- inp <<    offset[1:0] *8
    # out <- inp >> (4-offset[1:0])*8
    # out <- inp <<    offset[1:0] *8 | or
    # out <- inp >> (4-offset[1:0])*8 | or
    # out <- inp << (4-offset[1:0])*8 | or & 0xffffffff >>    mask_offset[1:0] *8
    # out <- inp >>    offset[1:0] *8 | or & 0xffffffff << (4-mask_offset[1:0])*8

    if ($line =~ s/^(?<result>\w+)\s+\<\-\s+(?<input>\w+)\s+//) {
        $m_bus_mux_output = $registers_index{$+{result}};
        $m_bus_mux_input = $registers_index{$+{input}};

        if ($line =~ s/<<\s+(?<offset>\w+)\s*\[1:0\]\*8\s*//) {
            $m_bus_mux_shift = $registers_index{$+{offset}};
        } elsif ($line =~ s/>>\s+\(4\-(?<offset>\w+)\s*\[1:0\]\)\*8\s*//) {
            $m_bus_mux_shift = $registers_index{$+{offset}};
            $m_bus_shift_right = 1;
        }

        if ($line =~ s/\|\s+(?<or>\w+)\s*//) {
            $m_bus_mux_or = $registers_index{$+{or}};
        }

        if ($line =~ s/\&\s+0xffffffff\s+\>\>\s+(?<mask_offset>\w+)\[1:0\]\s*\*8//) {
            $m_bus_mux_mask =  $registers_index{$+{mask_offset}};
        }
    }

	print "rom[$pc] = {2'd$m_alu_mux_input1, 2'd$m_alu_mux_input2, 3'd$m_alu_mux_operation, 3'd$m_bus_mux_input, 3'd$m_bus_mux_shift, 1'b$m_bus_shift_right, 2'd$m_bus_mux_or, 3'd$m_bus_mux_mask, 3'd$m_bus_mux_output, 2'b10}; // $line_saved\n"
}

sub parse_memory {
    my ($line, $pc) = @_;

    my $m_mem_mux_addr = 7;
    my $mem_read = 0;
    my $mem_write = 0;
    my $m_mem_address_plus_4 = 0;

    if ($line =~ /mem_address\s+\<\-\s+(?<reg>\w+)\[31:2\]/) {
        $m_mem_mux_addr = $registers_index{$+{reg}};
    }

    if ($line =~ /\+\s*4/) {
        $m_mem_address_plus_4 = 1;
    }

    if ($line =~ /mem_read/) {
        $mem_read = 1;
    }

    if ($line =~ /mem_write/) {
        $mem_write = 1;
    }

    print "rom[$pc] = {3'd$m_mem_mux_addr, 1'b$mem_read, 1'b$mem_write, 1'b$m_mem_address_plus_4, 2'b11}; // $line\n";
}
