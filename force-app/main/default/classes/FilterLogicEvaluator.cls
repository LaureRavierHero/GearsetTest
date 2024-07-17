public with sharing class FilterLogicEvaluator {
    public class FilterLogicEvaluatorException extends Exception {}
    /* expects input in the form of (1 OR (0 AND 1)) AND 0 
    Where 1 signifies truth and 0 signifies falsehood. Parses tokens and returns 
    in Reverse Polish Notation for parsing:
    (0 AND 1) OR (1 AND 0) becomes 0 1 AND 1 0 AND OR */
    private static List<String> tokenize(String input) {
        List<String> tokens = new List<String>();
        Integer len = input.length();

        while (len > 0) {
            if (input.startsWith('0') || input.startsWith('1') || input.startsWith('(') || input.startsWith(')')) {
                tokens.add(input.substring(0, 1));
                input = input.substring(1);
            }
            else if (input.startsWith('AND')) {
                tokens.add('AND');
                input = input.substring(3);
            }
            else if (input.startsWith('OR')) {
                tokens.add('OR');
                input = input.substring(2);
            }
            else {
                throw new FilterLogicEvaluatorException('Invalid input for tokenize: ' + input);
            }
            len = input.length();
        }
        return tokens;
    }

    private static List<String> infixToRPN(String input) {
        List<String> tokens = tokenize(input);
        List<String> outputQueue = new List<String>();
        List<String> operatorStack = new List<String>(); // LIFO

        while (tokens.size() != 0) { 
            String token = tokens.remove(0);
            // If it's a value, put it on the output queue
            if (token == '0' || token == '1') {
                outputQueue.add(token);
            }
            else if (token == 'OR' || token == 'AND') {   
                while (operatorStack.size() > 0 && operatorStack[operatorStack.size() - 1] != '(') {
                    outputQueue.add(operatorStack.remove(operatorStack.size() - 1));
                }
                operatorStack.add(token);
            }
            else if (token == '(') {
                operatorStack.add(token);
            }
            else { // has to be right parenthesis
                System.assert(operatorStack.size() != 0, 'Mismatched parentheses in logic');
                while (operatorStack[operatorStack.size() - 1] != '(') {
                    outputQueue.add(operatorStack.remove(operatorStack.size() - 1));
                    System.assert(operatorStack.size() != 0, 'Mismatched parentheses in logic');
                }
                // Discard the left parenthesis that's left on top
                System.assert(operatorStack[operatorStack.size() - 1] == '(', 'Mismatched parentheses in logic');
                operatorStack.remove(operatorStack.size() - 1);
            }
        }

        while (operatorStack.size() != 0) {
            outputQueue.add(operatorStack.remove(operatorStack.size() - 1));
        }

        return outputQueue;
    }

    /* Expects a string describing logic to evaluate (aka reduce to either true or false) in the following format:
    '((1 AND 0) OR (0 AND 0)) OR 0' where 0 means false and 1 means true.
    */
    public static Boolean evaluate(String input) {
        String sanitizedInput = input.replaceAll('(\\s)', '');
        List<String> rpn = infixToRPN(sanitizedInput);

        List<String> stack = new List<String>();

        for (String token: rpn) {
            if (token == 'AND' || token == 'OR') {
                String l = stack.remove(stack.size() - 1);
                String r = stack.remove(stack.size() - 1);

                if (token == 'AND') {
                    if (l == '1' && r == '1') {
                        stack.add('1');
                    }
                    else {
                        stack.add('0');
                    }
                }
                else {
                    if (l == '1' || r == '1') {
                        stack.add('1');
                    }
                    else {
                        stack.add('0');
                    }
                }
            }
            else {
                stack.add(token);
            }
        }

        return stack[0] == '1';
    }
}