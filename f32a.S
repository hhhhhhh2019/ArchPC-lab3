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
\\    if exp == 0:
\\        return 1
\\    result = base
\\    exp -= 1
\\
\\    current_exp = 1
\\
\\    while current_exp << 1 <= exp:
\\        result *= result
\\        if result > max_int32 or result < min_int32:
\\            return [overflow_error_value]
\\        current_exp <<= 1
\\
\\    for _ in range(exp - current_exp):
\\        result *= base
\\        if result > max_int32 or result < min_int32:
\\            return [overflow_error_value]
\\    
\\    return [result]
\\
\\
\\assert power(2, 10) == [1024]
\\assert power(3, 5) == [243]
\\assert power(5, 0) == [1]
\\assert power(0, 5) == [0]

step:
    ;

big_step:
    ;
    
.text
_start:
    @p 0x80 \\ base
    @p 0x80 \\ exp

    
        
    dup
    if exp_zero \\ if exp == 0

    -1
    + \\ exp -= 1

    

    halt

exp_zero:
    1
    !p 0x84
    halt
