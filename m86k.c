int get_priority(char ch) {
	if (ch == '+' || ch == '-')
		return 1;
	if (ch == '*' || ch == '/')
		return 2;
	return 0;
}

void infix_to_rpn(char* input) {
	char* result[40];
	int result_size = 0;

	char ops[];
	int ops_size = 0;
	
	for (int i = 0; i < 0x40;) {
		if (input[i] == '\n')
			break;

		if (input[i] == ' ') {
			i++;
			continue;
		}

		if ('0' <= input[i] && input[i] <= '9') {
			while ('0' <= input[i] && input[i] <= '9' && i < 0x40 && input[i] != '\n') {
				result[result_size++] = input[i++];

				if (result_size == 0x40) overflow();
			}

			// TODO: result += " "

			continue;
		}

		if (input[i] == '+' || input[i] == '-' || input[i] == '*' || input[i] == '/') {
			while (ops_len != 0 && top(ops) != '(' && get_priority(top(ops)) >= get_priority(input[i])) {
				result[result_size++] = pop(ops);
				if (result_size == 0x40) overflow();
				result[result_size++] = ' ';
				if (result_size == 0x40) overflow();
			}

			push(ops, input[i]);
			i++;
			continue;
		}

		if (input[i] == '(') {
			push(ops, inputs[i]);
			i++;
			continue;
		}

		if (inputs[i] == ')') {
			while (ops_len != 0 && top(ops) != '(') {
				result[result_size++] = pop(ops);
				if (result_size == 0x40) overflow();
				result[result_size++] = ' ';
				if (result_size == 0x40) overflow();
			}

			if (ops_len == 0) {
				overflow();
			}

			pop(ops);
			i++;
			continue;
		}

		overflow();
	}

  while (ops_size != 0) {
    char op = pop(ops);

    if (op == '(')
      overflow();

    result[result_size++] = op;
    if (result_size == 0x40) overflow();
    result[result_size++] = ' ';
    if (result_size == 0x40) overflow();
  }

  for (int i = 0; i < result_size; i++)
    putc(result[i]);
}

void _start() {
	char* input[0x40];
	read_line(input, 0x40);
	infix_to_rpn(input);
}
