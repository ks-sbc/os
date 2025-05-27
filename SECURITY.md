# Security Policy

## KSBC OS Security Principles

KSBC OS prioritizes operational security for revolutionary organizations facing state repression. Our security model assumes adversarial conditions from the start.

### Core Security Features (inherited from Tails)

- All network traffic routed through Tor
- Amnesic system - no traces left on host computer
- Encrypted persistent storage for organizational data
- AppArmor mandatory access control
- Hardened kernel and system configuration

### DRUIDS Security Architecture

1. **Distributed Resilience**
   - No central servers or single points of failure
   - Every node maintains complete organizational DNA
   - Cryptographic signatures prevent history falsification

2. **Information Compartmentalization**
   - Three-tier access model: public, candidate, cadre
   - Sensitive data encrypted at rest
   - Network isolation between security levels

3. **Operational Security**
   - Assumes hostile network environment
   - Protects against correlation attacks
   - Resists forensic analysis

## Reporting Security Vulnerabilities

### For KSBC OS/DRUIDS-specific issues:

1. **DO NOT** create public issues for security vulnerabilities
2. Submit security reports through encrypted channels only
3. Use our PGP key (to be published) for sensitive communications
4. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact assessment
   - Suggested mitigation if available

### For Tails-inherited vulnerabilities:

Report upstream to Tails project:
- Email: tails-security@boum.org
- PGP: https://tails.net/tails-bugs.key

## Security Considerations for Contributors

1. **Commit Signing**
   - Sign all commits with GPG
   - Verify signatures on critical code

2. **Code Review**
   - All security-critical changes require review
   - No single person can merge security code

3. **Dependencies**
   - Minimize external dependencies
   - Audit all new dependencies for security
   - Pin dependency versions for reproducibility

4. **Testing**
   - Security features must include tests
   - Run full test suite before security releases

## Threat Model

KSBC OS assumes the following adversaries:

1. **State-level actors** with significant resources
2. **Network adversaries** capable of traffic analysis
3. **Physical adversaries** with device access
4. **Infiltrators** attempting to compromise organizational security

Our security measures are designed to protect against these threats while maintaining usability for organizing work.

## Security Maintenance

- Regular security audits of DRUIDS components
- Timely updates from upstream Tails
- Proactive monitoring of security advisories
- Rapid response to reported vulnerabilities

Remember: Security is not just technology - it's a practice. The best security architecture cannot protect against poor operational security practices.