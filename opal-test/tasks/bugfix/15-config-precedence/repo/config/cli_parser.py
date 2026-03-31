def parse_cli_args(argv=None):
    if argv is None:
        return {}
    result = {}
    i = 0
    while i < len(argv):
        if argv[i] == '--port' and i + 1 < len(argv):
            result['port'] = int(argv[i + 1])
            i += 2
        elif argv[i] == '--debug':
            result['debug'] = True
            i += 1
        elif argv[i] == '--log-level' and i + 1 < len(argv):
            result['log_level'] = argv[i + 1]
            i += 2
        elif argv[i] == '--db-host' and i + 1 < len(argv):
            result['db_host'] = argv[i + 1]
            i += 2
        elif argv[i] == '--workers' and i + 1 < len(argv):
            result['workers'] = int(argv[i + 1])
            i += 2
        else:
            i += 1
    return result
