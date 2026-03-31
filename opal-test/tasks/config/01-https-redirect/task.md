# config-01-https-redirect

## Source

Synthetic task based on a common nginx deployment configuration scenario.

## Problem

A Python Flask web application is served behind nginx, but the nginx configuration only listens on port 80 (HTTP) with no HTTPS support. The application needs to serve traffic over HTTPS and redirect all HTTP requests to HTTPS.

The current `config/nginx.conf` has a single server block that listens on port 80 and proxies requests to the Flask app at `127.0.0.1:5000`. There is no SSL/TLS configuration and no redirect from HTTP to HTTPS.

## Acceptance Criteria

- `config/nginx.conf` has an HTTPS server block listening on port 443 with SSL enabled
- `config/nginx.conf` includes `ssl_certificate` and `ssl_certificate_key` directives pointing to certificate files
- The port-80 server block redirects to HTTPS using `return 301 https://...`
- The HTTPS server block proxies requests to the Flask app at `127.0.0.1:5000`
- The HTTPS server block includes `proxy_set_header` directives for both `Host` and `X-Real-IP`
- All existing application tests pass without modification

## Constraints

- Do not modify the Flask application code in `app/`
- Do not modify the existing tests
- SSL certificate paths can use placeholder paths (e.g., `/etc/ssl/certs/server.crt`)
- The `server_name` should remain `example.com`
