;;def infix_to_rpn(input: str) -> tuple[str | list[int], str]:
;;    """Convert an infix expression into Reverse Polish Notation.
;;
;;    The recommended algorithm is the shunting-yard algorithm: numbers go
;;    directly to the output, operators are pushed to a stack and popped
;;    from it according to their priority.
;;
;;    Examples:
;;    - "1 + 2 * 3" -> "1 2 3 * +"
;;    - "(1 + 2) * 3" -> "1 2 + 3 *"
;;
;;    - Allowed tokens: non-negative decimal numbers, `+`, `-`, `*`, `/`,
;;      parentheses and spaces.
;;    - Priority: `*` and `/` are higher than `+` and `-`, operators with
;;      the same priority are left associative.
;;    - Output tokens are separated by exactly one space.
;;    - Result string should be represented as a correct C string.
;;    - Buffer size for the result -- `0x40`, starts from `0x00`.
;;    - End of input -- new line.
;;    - Unknown character or unbalanced parentheses: return -1.
;;
;;    Python example args:
;;        input (str): The input string till new line.
;;
;;    Returns:
;;        tuple: A tuple containing the RPN string and the remaining input.
;;    """
;;    line, rest = read_line(input, 0x40)
;;
;;    if line is None:
;;        return [overflow_error_value], rest
;;
;;    priority = {"+": 1, "-": 1, "*": 2, "/": 2}
;;
;;    result = ""
;;    ops = []
;;    i = 0
;;
;;    while i < len(line):
;;        char = line[i]
;;
;;        if char == " ":
;;            i += 1
;;
;;        elif "0" <= char <= "9":
;;            j = i
;;            while j < len(line) and "0" <= line[j] <= "9":
;;                j += 1
;;
;;            result += line[i:j] + " "
;;            i = j
;;
;;        elif char in priority:
;;            while ops and ops[-1] != "(" and priority[ops[-1]] >= priority[char]:
;;                result += ops.pop() + " "
;;
;;            ops.append(char)
;;            i += 1
;;
;;        elif char == "(":
;;            ops.append(char)
;;            i += 1
;;
;;        elif char == ")":
;;            while ops and ops[-1] != "(":
;;                result += ops.pop() + " "
;;
;;            if not ops:
;;                return [-1], rest
;;
;;            ops.pop()
;;            i += 1
;;
;;        else:
;;            return [-1], rest
;;
;;    while ops:
;;        op = ops.pop()
;;
;;        if op == "(":
;;            return [-1], rest
;;
;;        result += op + " "
;;
;;    # The last space is extra: in the buffer it is replaced by `\0`.
;;    result = result[:-1]
;;
;;    if len(result) + 1 > 0x40:
;;        return [overflow_error_value], rest
;;
;;    return cstr(result, 0x40)[0], rest
;;
;;
;;assert infix_to_rpn('1 + 2\n') == ('1 2 +', '')
;;assert infix_to_rpn('1 + 2 * 3\n') == ('1 2 3 * +', '')
;;assert infix_to_rpn('(1 + 2) * 3\n') == ('1 2 + 3 *', '')
;;assert infix_to_rpn('10 - 2 - 3\n') == ('10 2 - 3 -', '')

.data
.org 0
input_buf:  .byte 0

.data
.org 0x40
result_buf: .byte 0
        
.data
.org 0x80
input:  .word 0
output: .word 0
max_len:    .word 0x40
result_len: .word 0
ops_len:    .word 0
ops_buf:    .byte 0

    ;; A7 - sp
    ;; A6 - fp
    ;; регистры D* должны быть восстановлены при выходе из фунцкии
    ;; т.к. в A* можно только писать, их сохранить нельзя
    ;; аргументы для функций передаются через стек в обратном порядке(на верху стека - первый арумент)
    ;; результат также кладеться в стек после аргументов

.text
.org 0xb0
raise_overflow: 
    move.l 0x84, D0
    movea.l D0, A0
    move.l 0xcccccccc, (A0)
    halt

raise_error:   
    move.l 0x84, D0
    movea.l D0, A0
    move.l -1, (A0)
    halt 
    
; void read_input(int size)
read_input:
    link A6, -4
    move.l D0, -4(A6)

    move.l input, D0
    movea.l D0, A0

    move.l input_buf, D0
    movea.l D0, A1

    move.l 8(A6), D0

read_input_loop:
    cmp.l 0, D0
    beq raise_overflow

    move.b (A0), (A1)+
    sub.l 1, D0

    cmp.b 10, -1(A1)
    bne read_input_loop

read_input_loop_break:   
    move.l -4(A6), D0
    unlk A6
    rts

; intxo get_priority(char)
get_priority:   
    link A6, -4

    move.l D0, -4(A6)

    move.b 8(A6), D0

    cmp.b '+', D0
    beq get_priority_1
    cmp.b '-', D0
    beq get_priority_1
    cmp.b '*', D0
    beq get_priority_2
    cmp.b '/', D0
    beq get_priority_2

    clr.l D0
    jmp get_priority_exit

get_priority_1:
    move.l 1, D0
    jmp get_priority_exit

get_priority_2:
    move.l 2, D0

get_priority_exit:  
    move.l D0, 9(A6)

    move.l -4(A6), D0
    unlk A6
    rts
    
; void consume_input()
consume_input:
    link A6, -24

    move.l D0, -4(A6)
    move.l D1, -8(A6)
    move.l D2, -12(A6)
    move.l D3, -16(A6)
    move.l D4, -20(A6)
    move.l D5, -24(A6)

    move.l max_len, D0
    movea.l D0, A0
    move.l (A0), D5

    move.l result_len, D0
    movea.l D0, A0
    move.l (A0), D1

    move.l ops_len, D0
    movea.l D0, A0
    move.l (A0), D2

    move.l input_buf, D0
    movea.l D0, A0

    move.l result_buf, D0
    movea.l D0, A1

    move.l ops_buf, D0
    movea.l D0, A2
    
    move.b (A0)+, D0

consume_input_loop:
consume_input_loop_newline:
    cmp.b 10, D0
    beq consume_input_loop_break
    
consume_input_loop_space:
    cmp.b ' ', D0
    bne consume_input_loop_0_9

    move.b (A0)+, D0
    jmp consume_input_loop
    
consume_input_loop_0_9:
    cmp.b '0', D0
    blt consume_input_loop_ops
    cmp.b '9', D0
    bgt consume_input_loop_ops
    
consume_input_loop_0_9_loop:
    cmp.b '0', D0
    blt consume_input_loop_0_9_break
    cmp.b '9', D0
    bgt consume_input_loop_0_9_break
    cmp.b 10, D0
    beq consume_input_loop_0_9_break

    move.b D0, (A1, D1)
    add.l 1, D1

    cmp.l D5, D1
    beq raise_overflow
    
    move.b (A0)+, D0

    jmp consume_input_loop_0_9_loop
    
consume_input_loop_0_9_break:
    move.b ' ', (A1, D1)
    add.l 1, D1
    jmp consume_input_loop
    
consume_input_loop_ops:
    cmp.b '+', D0
    beq consume_input_loop_ops_prepare
    cmp.b '-', D0
    beq consume_input_loop_ops_prepare
    cmp.b '*', D0
    beq consume_input_loop_ops_prepare
    cmp.b '/', D0
    beq consume_input_loop_ops_prepare
    jmp consume_input_loop_lpar

consume_input_loop_ops_prepare:
    link A6, -5
    move.b D0, 0(A7)
    jsr get_priority
    move.l 1(A7), D4
    unlk A6

consume_input_loop_ops_loop:        
    cmp.b 0, D2
    beq consume_input_loop_ops_loop_break
    cmp.b '(', -1(A2, D2)
    beq consume_input_loop_ops_loop_break
    link A6, -5
    move.b -1(A2, D2), 0(A7)
    jsr get_priority
    move.l 1(A7), D3
    unlk A6
    cmp.l D4, D3
    blt consume_input_loop_ops_loop_break

    sub.l 1, D2
    move.b (A2, D2), (A1, D1)
    add.l 1, D1
    cmp.l D5, D1
    bge raise_overflow
    move.b ' ', (A1, D1)
    add.l 1, D1
    cmp.l D5, D1
    bge raise_overflow
    
    jmp consume_input_loop_ops_loop
    
consume_input_loop_ops_loop_break:
    move.b D0, (A2, D2)
    add.l 1, D2

    move.b (A0)+, D0
    jmp consume_input_loop
    
consume_input_loop_lpar:
    cmp.b '(', D0
    bne consume_input_loop_rpar
    
    move.b D0, (A2, D2)
    add.l 1, D2
    move.b (A0)+, D0
    jmp consume_input_loop
    
consume_input_loop_rpar:
    cmp.b ')', D0
    bne raise_error

consume_input_loop_rpar_loop:
    cmp.l 0, D2
    beq consume_input_loop_rpar_loop_break
    cmp.b '(', -1(A2, D2)
    beq consume_input_loop_rpar_loop_break

    sub.l 1, D2
    move.b (A2, D2), (A1, D1)
    add.l 1, D1
    cmp.l D5, D1
    bge raise_overflow
    move.b ' ', (A1, D1)
    add.l 1, D1
    cmp.l D5, D1
    bge raise_overflow
    
    jmp consume_input_loop_rpar_loop

consume_input_loop_rpar_loop_break:
    cmp.l 0, D2
    beq raise_error
    move.b (A0)+, D0
    sub.l 1, D2
    jmp consume_input_loop
    
consume_input_loop_break:
    move.l result_len, D0
    movea.l D0, A0
    move.l D1, (A0)

    move.l ops_len, D0
    movea.l D0, A0
    move.l D2, (A0)

    move.l -4(A6), D0
    move.l -8(A6), D1
    move.l -12(A6), D2
    move.l -16(A6), D3
    move.l -20(A6), D4

    unlk A6
    rts

; void append_ops()
append_ops:
    link A6, -12
    move.l D0, -4(A6)
    move.l D1, -8(A6)
    move.l D2, -12(A6)
    move.l D3, -16(A6)
    move.l D4, -20(A6)

    move.l result_len, D0
    movea.l D0, A0
    move.l (A0), D1

    move.l ops_len, D0
    movea.l D0, A0
    move.l (A0), D2

    move.l result_buf, D0
    movea.l D0, A1

    move.l ops_buf, D0
    movea.l D0, A2

append_ops_loop:
    cmp.l 0, D2
    beq append_ops_loop_break

    move.b -1(A2, D2), D0
    sub.l 1, D2

    cmp.b '(', D0
    beq raise_error

    move.b D0, (A1, D1)
    add.l 1, D1
    cmp.l D5, D1
    beq raise_overflow
    
    move.b ' ', (A1, D1)
    add.l 1, D1
    cmp.l D5, D1
    beq raise_overflow

    jmp append_ops_loop

append_ops_loop_break:
    move.b 0, -1(A1, D1)
    
    move.l -12(A6), D2
    move.l -8(A6), D1
    move.l -4(A6), D0
    unlk A6
    rts
    
; void infix_to_rpn()
infix_to_rpn:
    jsr consume_input
    jsr append_ops
    rts

; void print_result()
print_result:
    link A6, -4

    move.l result_buf, D0
    movea.l D0, A0

    move.l output, D0
    movea.l D0, A1

print_result_loop:
    cmp.b 0, (A0)
    beq print_result_loop_break
    move.b (A0)+, (A1)

    jmp print_result_loop

print_result_loop_break:    
    unlk A6
    rts
    
_start:
    move.l 0x1000, D0
    movea.l D0, A7

    move.l max_len, D0
    movea.l D0, A0

    link A6, -4
    move.l (A0), 0(A7)
    jsr read_input
    unlk A6

    jsr infix_to_rpn
    jsr print_result
    
    halt
    
