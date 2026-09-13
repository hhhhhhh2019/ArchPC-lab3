;;def count_leading_zeros(n: int) -> int:
;;  """Count the number of leading zeros in the binary representation of an integer.
;;
;;  Args:
;;  n (int): The integer to count leading zeros for.
;;
;;           Returns:
;;  int: The number of leading zeros.
;;  """
;;  if n == 0:
;;    return 32
;;  count = 0
;;  for i in range(31, -1, -1):
;;    if (n >> i) & 1 == 0:
;;      count += 1
;;    else:
;;      break
;;  return count

.data
result: .word 0
n: .word 0
i: .word 31
one: .word 1

.text
.org 0x100
_start:
  load_addr 0x80
  store n

  bnez non_zero
  load_imm 32
  store_addr 0x84
  halt

non_zero:
  load n
  shiftr i
  and one

  bnez break

  load result
  add one
  store result

  load i
  sub one
  store i
  bgez non_zero
break:
  load result
  store_addr 0x84
halt
