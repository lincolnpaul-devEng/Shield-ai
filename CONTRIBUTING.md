# Contributing to Shield AI

Thank you for your interest in contributing to Shield AI! We welcome contributions from the community and are grateful for your help in making Shield AI better.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)
- [Documentation](#documentation)

## Code of Conduct
This project adheres to our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to conduct@shieldai.com.

## How to Contribute

### Types of Contributions
- **Bug fixes**: Fix bugs or issues in the codebase
- **Features**: Add new functionality or improve existing features
- **Documentation**: Improve documentation, tutorials, or examples
- **Testing**: Add or improve tests
- **Code review**: Review and provide feedback on pull requests

### Getting Started
1. Fork the repository on GitHub
2. Clone your fork locally
3. Create a new branch for your changes
4. Make your changes
5. Test your changes thoroughly
6. Submit a pull request

## Development Setup

### Prerequisites
- Python 3.10+
- Flutter SDK 3.x
- Git
- Android Studio/Xcode (for mobile development)

### Backend Setup
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env  # Configure your environment
python run.py
```

### Frontend Setup
```bash
cd mobile
flutter pub get
flutter run -d chrome  # For web development
```

### Testing
```bash
# Backend tests
cd backend && pytest

# Frontend tests
cd mobile && flutter test
```

## Submitting Changes

### Pull Request Process
1. **Create a branch**: `git checkout -b feature/your-feature-name`
2. **Make changes**: Implement your feature or fix
3. **Write tests**: Add tests for new functionality
4. **Update documentation**: Update docs if needed
5. **Commit changes**: Use clear, descriptive commit messages
6. **Push to your fork**: `git push origin feature/your-feature-name`
7. **Create PR**: Open a pull request on GitHub

### Commit Message Guidelines
Use clear, descriptive commit messages:
```
feat: add M-Pesa STK Push integration
fix: resolve HTTP request finalization bug
docs: update API documentation
test: add unit tests for fraud detection
```

### Pull Request Requirements
- **Title**: Clear, descriptive title
- **Description**: Detailed explanation of changes
- **Tests**: Include tests for new functionality
- **Documentation**: Update docs if needed
- **Breaking changes**: Clearly mark breaking changes

## Reporting Issues

### Bug Reports
When reporting bugs, please include:
- **Description**: Clear description of the issue
- **Steps to reproduce**: Step-by-step instructions
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: OS, browser, device, versions
- **Screenshots**: If applicable

### Feature Requests
For feature requests, please include:
- **Description**: Clear description of the feature
- **Use case**: Why this feature would be useful
- **Implementation ideas**: If you have any suggestions

## Documentation

### Code Documentation
- Use clear, descriptive variable and function names
- Add docstrings/comments for complex logic
- Update README and docs for significant changes

### API Documentation
- Document new API endpoints
- Update existing documentation
- Include examples and use cases

## Development Guidelines

### Code Style
- **Python**: Follow PEP 8 guidelines
- **Dart**: Follow Flutter/Dart style guidelines
- **Consistency**: Maintain consistency with existing codebase

### Testing
- Write unit tests for new functionality
- Write integration tests for API changes
- Ensure all tests pass before submitting

### Security
- Never commit sensitive information (API keys, passwords)
- Use environment variables for configuration
- Follow security best practices

## Licensing
By contributing to Shield AI, you agree that your contributions will be licensed under the same license as the project (see [LICENSE](LICENSE)).

## Recognition
Contributors will be recognized in the [AUTHORS](AUTHORS) file and mentioned in release notes.

## Contact
- **Issues**: [GitHub Issues](https://github.com/lincolnpaul-devEng/Shield-ai/issues)
- **Discussions**: [GitHub Discussions](https://github.com/lincolnpaul-devEng/Shield-ai/discussions)
- **Email**: contributors@shieldai.com

Thank you for contributing to Shield AI! 🚀

---

**Last Updated:** November 2025