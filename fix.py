import os
import re

def fix_terraform():
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.tf'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if ';' in content or re.search(r'\{[^\n]+\}', content):
                    # Replace semicolons with newlines
                    content = content.replace(';', '\n')
                    
                    # Force multiline for all blocks to avoid single-line block errors
                    content = re.sub(r'\{\s*', '{\n', content)
                    content = re.sub(r'\s*\}', '\n}', content)
                    
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(content)

if __name__ == '__main__':
    fix_terraform()
