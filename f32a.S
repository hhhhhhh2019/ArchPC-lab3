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

.text

step:
  \\ [sp] = result, [sp+1] = base
  a! \\ A = result
  0

  \\ A = result, [sp] = 0, [sp+1] = base

  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  +*
  \\ A,T = A * S + T (A,T = result * base + 0)

  dup
  if step_good \\ check, if result is not exceed i32 range
  dup \\ if base negative, T maybe = -1
  inv
  if step_good

  0xcccccccc
  !p 0x84
  halt

step_good:
  \\ A = result, T = 0, S = base
  drop
  a
  ;

_start:
  @p 0x80
  @p 0x80

  dup
  -if exp_non_neg

  \\ if exp < 0
  -1
  !p 0x84
halt

exp_non_neg:
  >r \\ move exp to return stack
  1 \\ sp: result, sp+1: base
loop:
  next continue \\ loop while exp-- != 0
  exit ;
continue:
  step
  loop ;

exit:
  !p 0x84
  halt
