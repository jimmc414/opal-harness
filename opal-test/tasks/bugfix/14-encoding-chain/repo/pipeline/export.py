def write_output(lines, output_path):
    with open(output_path, 'w', encoding='ascii') as f:
        for line in lines:
            f.write(line + '\n')
