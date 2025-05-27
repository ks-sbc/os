# Contributing to KSBC OS

Thank you for your interest in contributing to KSBC OS! This project aims to build revolutionary organizational infrastructure through technology.

## Before You Start

1. Read [DRUIDS.md](./DRUIDS.md) to understand our architectural principles
2. Review [SECURITY.md](./SECURITY.md) for security considerations
3. Check existing issues and discussions

## Development Principles

### Form Governs Function
Technology shapes consciousness. When contributing, consider how your changes guide user behavior toward collective action and proper organizational practices.

### No Single Point of Failure  
Every feature must work in a distributed manner without central authorities or servers.

### Complete History
All changes must be traceable to their origin and reasoning. Document your decisions.

### Embedded Discipline
Make correct organizational practices easier than incorrect ones through design.

## Getting Started

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR-USERNAME/os.git
   cd os
   ```

2. **Set Up Development Environment**
   - Use the Vagrant build environment for consistency
   - See `/vagrant/` for setup instructions

3. **Create a Feature Branch**
   ```bash
   git checkout -b XXXX-feature-name
   ```
   Where XXXX is the issue number

## Making Changes

### Code Style
- Python: Follow PEP 8, use type hints, 88 char lines
- Ruby: Follow RuboCop rules, 2-space indent, 88 char lines
- Shell: POSIX compatible when possible
- See [CLAUDE.md](./CLAUDE.md) for detailed guidelines

### Testing
- Run the full test suite: `./run_test_suite`
- Add tests for new functionality
- Ensure all tests pass before submitting

### Documentation
- Update relevant CLAUDE.md files
- Add inline comments for complex logic
- Update user documentation if needed

## Submitting Changes

1. **Sign Your Commits**
   ```bash
   git commit -S -m "Description of change"
   ```

2. **Push to Your Fork**
   ```bash
   git push origin XXXX-feature-name
   ```

3. **Create Pull Request**
   - Use the PR template
   - Link to relevant issues
   - Describe security implications

## Review Process

1. Automated security checks must pass
2. Code review by maintainers
3. Security team review for sensitive changes
4. Documentation team review if needed

## Security

- Never commit secrets, keys, or credentials
- Report vulnerabilities privately (see SECURITY.md)
- Consider security implications of all changes

## Community

- Be respectful and constructive
- Focus on building revolutionary infrastructure
- Help others learn and contribute

## Questions?

- Check existing documentation
- Ask in GitHub Discussions
- Review similar code in the codebase

Remember: We're building tools for revolutionary continuity. Every contribution should strengthen organizational resilience and capacity.