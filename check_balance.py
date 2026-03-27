
import sys

def check_balance(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    stack = []
    pairs = {')': '(', '}': '{', ']': '['}
    lines = content.split('\n')
    
    for i, line in enumerate(lines):
        for char in line:
            if char in '({[':
                stack.append((char, i + 1))
            elif char in ')}]':
                if not stack:
                    print(f"Extra closing {char} on line {i+1}")
                    return
                top_char, top_line = stack.pop()
                if top_char != pairs[char]:
                    print(f"Mismatched {char} on line {i+1} (opened {top_char} on line {top_line})")
                    return
    
    if stack:
        for char, line in stack:
            print(f"Unclosed {char} from line {line}")
    else:
        print("Balanced")

if __name__ == "__main__":
    check_balance(sys.argv[1])
