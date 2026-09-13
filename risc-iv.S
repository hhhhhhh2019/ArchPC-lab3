;; def upper_case_cstr(s: str) -> tuple[str | list[int], str]:
;;     """Convert a C string to upper case.
;; 
;;     - Result string should be represented as a correct C string.
;;     - Buffer size for the message -- `0x20`, starts from `0x00`.
;;     - End of input -- new line.
;;     - Initial buffer values -- `_`.
;; 
;;     Python example args:
;;         s (str): The input C string.
;; 
;;     Returns:
;;         tuple: A tuple containing the upper case string and an empty string.
;;     """
;;     line, rest = read_line(s, 0x20)
;;     if line is None:
;;         return [overflow_error_value], rest
;;     return cstr(line.upper(), 0x20)[0], rest
;; 
;; 
;; assert upper_case_cstr('Hello\n') == ('HELLO', '')
;; # and mem[0..31]: 48 45 4c 4c 4f 00 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f
;; assert upper_case_cstr('world\n') == ('WORLD', '')
;; # and mem[0..31]: 57 4f 52 4c 44 00 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f 5f

.data
.org 0
result: .byte 0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0x5f,0

;; глобальные регистры:
;; s1 - содржит 10(\n в ascii)
;; s2 - 96 ('a' - 1. -1 т.к. тут есть только проверка на <=)
;; s3 - 122 ('z')
;; s4 - 32 ('a'-'A')
;; gp - указатель на последний символ в результирующей строке


.text
.org 0x100
recursion:
  sw fp, -4(sp)
  sw ra, -8(sp)
  mv fp, sp
  addi sp, sp, -8

  lb t0, 0(gp)
  beqz t0, fail

  lb t0, 0x80(zero)
  beq t0, s1, rec_exit

  bgt t0, s3, save_char ;; char > 'z'
  ble t0, s2, save_char ;; char < 'a'

  sub t0, t0, s4
save_char:
  sb t0, 0(gp)
  ;sb t0, 0x84(zero)
  addi gp, gp, 1

  jal ra, recursion

rec_exit:
  mv sp, fp
  lw fp, -4(sp)
  lw ra, -8(sp)
jr ra

_start:
  addi sp, zero, 8188

  addi s1, zero, 10  ;; '\n'
  addi s2, zero, 96  ;; 'a' - 1
  addi s3, zero, 122 ;; 'z'
  addi s4, zero, 32  ;; 'A'-'a'
  mv gp, zero

  jal ra, recursion

  sb zero, 0(gp)

  mv gp, zero
print_loop:
  lb t0, 0(gp)
  beqz t0, exit

  sb t0, 0x84(zero)
  addi gp, gp, 1
  j print_loop

exit:
halt

fail:
  lui t0, %hi(0xcccccccc)
  addi t0, t0, %lo(0xcccccccc)

  sw t0, 0x84(zero)
halt
