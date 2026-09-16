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
input: .byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

    ;; A7 - sp
    ;; A6 - fp
    ;; регистры D* должны быть восстановлены при выходе из фунцкии
    ;; т.к. в A* можно только писать, их сохранить нельзя
    ;; аргументы для функций передаются через стек в обратном порядке(на верху стека - первый арумент)
    ;; результат также кладеться в стек после аргументов
  
.text
_start:
    move.l 0x1000, D0
    movea.l D0, A7

    ;; read_line(input, 0x40)
    link A6, -8  
    move.l 0x40, 4(A7)
    move.l input, 0(A7)
    jsr read_line
    unlk A6

    link A6, -4
    move.l input, 0(A7)
    jsr infix_to_rpn
    unlk A6
    
    halt

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
    
;; void read_line(char* input, int size)
read_line:
    link A6, -8

    move.l D0, -4(A6)
    move.l D1, -8(A6)

    move.l 0x80, D0
    movea.l D0, A0              ; A0 = 0x80
    
    move.l 8(A6), D0
    movea.l D0, A1              ; A1 = input

    move.l 12(A6), D0           ; D0 = size

read_line_loop:
    cmp.l 0, D0
    beq raise_overflow
    
    move.b (A0), D1
    move.b D1, (A1)+

    cmp.b 10, D1
    beq read_line_break

    sub.l 1, D0
    jmp read_line_loop

read_line_break:
    
    move.l -8(A6), D1
    move.l -4(A6), D0
    
    unlk A6
    rts

;; void infix_to_rpn(char* input)
infix_to_rpn:
    ;; D7 - result_size
    ;; D6 - ops_size
    ;; D5 - temp
    ;; | result | ops | regs | a6’
    ;;  ^                     ^
    ;; a7                     a6
    link A6, -120                ; 64(result) + 24(ops) + 8*4(D*)

    move.l D0, -4(A6)
    move.l D1, -8(A6)
    move.l D2, -12(A6)
    move.l D3, -16(A6)
    move.l D4, -20(A6)
    move.l D5, -24(A6)
    move.l D6, -28(A6)
    move.l D7, -32(A6)

    clr.l D7
    clr.l D6

    ;; for (int i = 0; i < 0x40;)
    move.l 0, D5                ; i
    move.l 8(A6), D0
    movea.l D0, A0              ; A0 = input
infix_to_rpn_step_loop:
    cmp.l 0x40, D5
    bge infix_to_rpn_step_loop_break
    
    move.b (A0, D5), D0         ; D0 = input[i]
    
    ;; if (input[i] == ’\n’) break;
    cmp.b 10, D0
    beq infix_to_rpn_step_loop_break

    ;; if (input[i] == ’ ’) { i++; continue; }
    cmp.b 32, D0
    bne infix_to_rpn_step_loop_0_9
    add.l 1, D5
    jmp infix_to_rpn_step_loop

infix_to_rpn_step_loop_0_9:
    ;; if ('0' <= input[i] && input[i] <= '9')
    cmp.b 48, D0
    blt infix_to_rpn_step_loop_op
    cmp.b 57, D0
    bgt infix_to_rpn_step_loop_op

infix_to_rpn_step_loop_0_9_loop:
    ;; while ('0' <= input[i] && input[i] <= '9' && i < 0x40 && input[i] != '\n')
    cmp.b 48, D0
    blt infix_to_rpn_step_loop_0_9_loop_break
    cmp.b 57, D0
    bgt infix_to_rpn_step_loop_0_9_loop_break
    cmp.l 0x40, D5
    bge infix_to_rpn_step_loop_0_9_loop_break
    cmp.b 10, D0
    beq infix_to_rpn_step_loop_0_9_loop_break

    move.b D0, 0(A7, D7)        ; sp + result_size
    add.l 1, D7
    add.l 1, D5

    cmp.l 0x40, D7
    beq raise_overflow

    move.b (A0, D5), D0         ; D0 = input[i]

    jmp infix_to_rpn_step_loop_0_9_loop

infix_to_rpn_step_loop_0_9_loop_break:
    move.b 32, 0(A7, D7)        ; sp + result_size
    add.l 1, D7
    jmp infix_to_rpn_step_loop
    
infix_to_rpn_step_loop_op:
    ;; if (input[i] == '+' || input[i] == '-' || input[i] == '*' || input[i] == '/')
    cmp.b 43, D0
    beq infix_to_rpn_step_loop_op_loop_prepare
    cmp.b 45, D0
    beq infix_to_rpn_step_loop_op_loop_prepare
    cmp.b 42, D0
    beq infix_to_rpn_step_loop_op_loop_prepare
    cmp.b 47, D0
    bne infix_to_rpn_step_loop_lpar

infix_to_rpn_step_loop_op_loop_prepare:
    link A6, -5
    move.b D0, 0(A7)
    jsr get_priority
    move.l 1(A7), D1            ; D1 = get_priority(input[i])
    unlk A6
    
infix_to_rpn_step_loop_op_loop:
    ;; while (ops_len != 0 && top(ops) != '(' && get_priority(top(ops)) >= get_priority(input[i]))
    cmp.l 0, D6
    beq infix_to_rpn_step_loop_op_loop_break
    cmp.b 40, 63(A7, D6)        ; sp + 64(result) + ops_size - 1
    beq infix_to_rpn_step_loop_op_loop_break

    move.b 63(A7, D6), D2
    link A6, -5
    move.b D2, 0(A7)
    jsr get_priority
    move.l 1(A7), D2            ; D2 = get_priority(ops[ops_size-1])
    unlk A6

    cmp.l D1, D2
    blt infix_to_rpn_step_loop_op_loop_break

    move.b 63(A7, D6), 0(A7, D7)
    sub.l 1, D6
    add.l 1, D7

    cmp.l 0x40, D7
    beq raise_overflow
    
    move.b 32, -120(A6, D7) 
    add.l 1, D7

    cmp.l 0x40, D7
    beq raise_overflow

    jmp infix_to_rpn_step_loop_op_loop
    
infix_to_rpn_step_loop_op_loop_break:
    move.b D0, 64(A7, D6)       ; sp + 64(result) + ops_size
    add.l 1, D6
    add.l 1, D5
    jmp infix_to_rpn_step_loop
    
infix_to_rpn_step_loop_lpar:
    cmp.b 40, D0
    bne infix_to_rpn_step_loop_rpar
    
    move.b D0, 64(A7, D6)       ; sp + 64(result) + ops_size
    add.l 1, D6
    add.l 1, D5
    jmp infix_to_rpn_step_loop
    
infix_to_rpn_step_loop_rpar:
    cmp.b 41, D0
    bne raise_error

infix_to_rpn_step_loop_rpar_loop:
    cmp.l 0, D6
    beq infix_to_rpn_step_loop_rpar_loop_break
    cmp.b 40, 63(A7, D6)
    beq infix_to_rpn_step_loop_rpar_loop_break

    move.b 63(A7, D6), 0(A7, D7)
    add.l 1, D7
    sub.l 1, D6
    
    move.b 32, 0(A7, D7)
    add.l 1, D7

    jmp infix_to_rpn_step_loop_rpar_loop

infix_to_rpn_step_loop_rpar_loop_break:
    cmp.l 0, D6
    beq raise_error

    sub.l 1, D6
    add.l 1, D5

    jmp infix_to_rpn_step_loop

infix_to_rpn_step_loop_break:

infix_to_rpn_ops_loop:
    cmp.l 0, D6
    beq infix_to_rpn_ops_loop_break

    move.b 63(A7, D6), D1       ; sp + 64(result) + ops_size - 1

    cmp.b 40, D1                ; ’(’
    beq raise_error
    
    move.b D1, 0(A7, D7)        ; sp + result_size
    sub.l 1, D6
    add.l 1, D7
    
    move.b 32, 0(A7, D7)        ; sp + result_size
    add.l 1, D7

    jmp infix_to_rpn_ops_loop
    
infix_to_rpn_ops_loop_break:

    clr.l D0
    movea.l D0, A0

    sub.l 1, D7
    
infix_to_rpn_send_loop:
    cmp.l D7, D0
    bge infix_to_rpn_send_loop_break

    move.b 0(A7, D0), 0x84(A0)
    add.l 1, D0

    jmp infix_to_rpn_send_loop

infix_to_rpn_send_loop_break:

    move.l  -4(A6), D0
    move.l  -8(A6), D1
    move.l -12(A6), D2
    move.l -16(A6), D3
    move.l -20(A6), D4
    move.l -24(A6), D5
    move.l -28(A6), D6
    move.l -32(A6), D7

    unlk A6
    rts

    ;; int get_priority(char ch) {
    ;; 	if (ch == '+' || ch == '-')
    ;; 		return 1;
    ;; 	if (ch == '*' || ch == '/')
    ;; 		return 2;
    ;; 	return 0;
    ;; }
get_priority:   
    link A6, -4

    move.l D0, -4(A6)

    move.b 8(A6), D0

    cmp.b 43, D0
    beq get_priority_1
    cmp.b 45, D0
    beq get_priority_1
    cmp.b 42, D0
    beq get_priority_2
    cmp.b 47, D0
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
