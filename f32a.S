\\def power(base: int, exp: int) -> list[int]:
\\    """Compute base raised to the power of a non-negative exponent.
\\
\\    - exp < 0: return -1
\\    - Overflow (result outside int32 range): return 0xCCCCCCCC
\\
\\    Args:
\\        base (int): The base value.
\\        exp (int): The non-negative exponent.
\\
\\    Returns:
\\        list: A one-element list with the result.
\\    """
\\    if exp < 0:
\\        return [-1]
\\    result = 1
\\    for _ in range(exp):
\\        result *= base
\\        if result > max_int32 or result < min_int32:
\\            return [overflow_error_value]
\\    return [result]
\\
\\
\\assert power(2, 10) == [1024]
\\assert power(3, 5) == [243]
\\assert power(5, 0) == [1]
\\assert power(0, 5) == [0]

  .data
input_addr: .word  0x80
output_addr:  .word  0x84
overflow_value: .word 0xcccccccc
int_max_plus_1: .word  0x80000000
mul_steps_count_minus_1:  .word 31

  .text
exit:
  @p output_addr
  a!
  !
  halt

overflow:
  @p overflow_value
  exit ;

  \\ a b -> a*b
multiply:
  a!
  0
  
  @p mul_steps_count_minus_1
  >r
multiply_loop:
  +*
  next multiply_loop
  
  if multiply_exit
  overflow ;
multiply_exit:
  drop
  a
  
  ;

power:
  1
  \\ stack: base, exp, resul

  over
  if power_exit
  
power_loop:
  over \\ base, exp, result, exp
  1
  and
  if mul_base

mul_result: \\ result *= base
  >r \\ base, exp | result
  over \\ base, exp, base | result
  r> \\ base, exp, base, result
  multiply \\ base, exp, base*result

mul_base: \\ base *= base
  >r
  2/
  r>
  over
  if power_exit
  
  >r >r \\ base | exp, result
  dup \\ base base | exp, result
  multiply \\ base*base | exp, result
  r> r>

  power_loop ;
  
power_exit:
  a!
  ;
  
  
  .text
  .org 0x88
  
_start:
  @p input_addr
  a!

  @ \\ base
  @ \\ exp

  dup
  if exp_zero
  dup
  -if exp_positive
  
exp_negative: 
  -1
  exit ;

exp_zero:
  1
  exit ;

exp_positive:
  over
  -if base_positive

base_negative:
  >r
  inv
  1 +
  r>

  dup
  1 and

  if base_negative_exp_even
  
base_negative_exp_odd:  
  power
  a

  inv
  1 +
  
  exit ;
  
base_negative_exp_even: 
  power
  a
  exit ;

base_positive:
  power
  a

  dup
  @p int_max_plus_1
  +
  -if overflow
  
  exit ;
