from config.defaults import get_defaults
from config.file_loader import load_from_file
from config.env_loader import load_from_env
from config.cli_parser import parse_cli_args


def load_config(config_file=None, cli_argv=None):
    config = get_defaults()

    env_values = load_from_env()

    for key in ("port", "debug"):
        if key in env_values:
            config[key] = env_values[key]

    if config_file:
        file_values = load_from_file(config_file)
        config.update(file_values)

    for key in ("log_level", "db_host", "workers"):
        if key in env_values:
            config[key] = env_values[key]

    cli_values = parse_cli_args(cli_argv)
    config.update(cli_values)

    return config
