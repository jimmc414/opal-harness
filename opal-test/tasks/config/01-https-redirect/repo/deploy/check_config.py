import re
import sys


def check_nginx_config(filepath):
    with open(filepath) as f:
        content = f.read()

    results = {
        "has_ssl_listen": bool(re.search(r'listen\s+443\s+ssl', content)),
        "has_ssl_cert": bool(re.search(r'ssl_certificate\s+', content)),
        "has_ssl_key": bool(re.search(r'ssl_certificate_key\s+', content)),
        "has_redirect": bool(re.search(r'return\s+301\s+https', content)),
        "has_http_server": bool(re.search(r'listen\s+80', content)),
    }
    return results


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "config/nginx.conf"
    results = check_nginx_config(path)
    for key, value in results.items():
        print(f"{key}: {value}")
