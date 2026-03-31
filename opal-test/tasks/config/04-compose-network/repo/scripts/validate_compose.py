import sys

try:
    import yaml
except ImportError:
    yaml = None


def validate_compose(filepath):
    with open(filepath) as f:
        content = f.read()

    if yaml:
        data = yaml.safe_load(content)
    else:
        data = _simple_parse(content)

    results = {}
    services = data.get('services', {})
    results['service_count'] = len(services)
    results['has_networks'] = 'networks' in data

    for name, svc in services.items():
        if isinstance(svc, dict) and 'depends_on' in svc:
            results[f'{name}_has_depends'] = True

    for name, svc in services.items():
        if isinstance(svc, dict):
            env = svc.get('environment', [])
            if isinstance(env, list):
                for e in env:
                    if isinstance(e, str):
                        results[f'{name}_env'] = e

    return results


def _simple_parse(content):
    import re
    data = {'services': {}}
    current_service = None
    in_services = False
    for line in content.split('\n'):
        if line.strip() == 'services:':
            in_services = True
            continue
        if in_services:
            svc_match = re.match(r'^  (\w[\w-]*):$', line)
            if svc_match:
                current_service = svc_match.group(1)
                data['services'][current_service] = {'environment': []}
                continue
        if current_service and line.strip().startswith('- ') and '=' in line:
            env_val = line.strip().lstrip('- ').strip()
            if 'environment' not in data['services'][current_service]:
                data['services'][current_service]['environment'] = []
            data['services'][current_service]['environment'].append(env_val)
        dep_match = re.match(r'^\s+depends_on:', line)
        if dep_match and current_service:
            data['services'][current_service]['depends_on'] = True
    if 'networks:' in content:
        data['networks'] = True
    return data


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "docker-compose.yml"
    results = validate_compose(path)
    for k, v in sorted(results.items()):
        print(f"{k}: {v}")
