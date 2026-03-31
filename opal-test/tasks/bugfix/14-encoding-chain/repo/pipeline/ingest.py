def read_file(filepath):
    with open(filepath, encoding='utf-8') as f:
        lines = f.readlines()
    return [line.rstrip('\n') for line in lines]
