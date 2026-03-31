def normalize(lines):
    result = []
    for line in lines:
        cleaned = line.strip()
        if cleaned:
            normalized = cleaned.encode('ascii', errors='ignore').decode('ascii')
            result.append(normalized.lower())
    return result
