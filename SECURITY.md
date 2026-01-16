# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email security concerns to the project maintainers (see repository contacts)
3. Include as much detail as possible:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt within 48 hours
- **Assessment**: We will assess the vulnerability and determine its severity
- **Timeline**: We aim to provide a fix within 90 days for critical issues
- **Disclosure**: We will coordinate disclosure timing with you

### Scope

The following are in scope for security reports:

- Session server (Rust WebSocket server)
- Jellyfin plugin (C# backend)
- Web client (JavaScript)
- Authentication/JWT handling
- Docker configurations

### Out of Scope

- Jellyfin core vulnerabilities (report to Jellyfin project)
- Third-party dependencies (report to respective maintainers)
- Social engineering attacks
- Physical attacks

## Security Best Practices

When deploying OpenWatchParty:

1. **Always use HTTPS/WSS** in production
2. **Set a strong JWT_SECRET** (minimum 32 characters)
3. **Keep Jellyfin updated** to the latest version
4. **Use network isolation** - don't expose session server directly to internet
5. **Review Docker security** - run containers as non-root (default)

## Known Limitations

- JWT tokens cannot be revoked before expiration
- Room passwords are transmitted in plaintext over WebSocket (use WSS)
- No built-in rate limiting for room creation (handled by server limits)

See [Security Documentation](docs/operations/security.md) for detailed security guidance.
