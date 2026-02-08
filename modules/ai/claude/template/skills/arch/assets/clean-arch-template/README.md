# Clean Architecture Template

This template provides a starting directory structure for Clean Architecture projects.

## Structure

```
domain/              # Enterprise Business Rules (innermost layer)
├── entities/        # Core business objects
├── value_objects/   # Immutable domain concepts
└── services/        # Domain services

application/         # Application Business Rules
├── use_cases/       # Application-specific workflows
├── interfaces/      # Abstractions for infrastructure
└── dtos/           # Data transfer objects

infrastructure/      # Interface Adapters
├── persistence/     # Database implementations
├── web/            # HTTP controllers, presenters
└── external/       # External service adapters

presentation/        # Frameworks & Drivers (outermost layer)
├── api/            # Web framework setup (FastAPI, Flask, etc.)
└── cli/            # CLI framework setup

tests/              # Test structure mirrors source
├── domain/
├── application/
└── infrastructure/
```

## Usage

1. Copy this template to your project directory
2. Add your domain entities in `domain/entities/`
3. Define use cases in `application/use_cases/`
4. Implement infrastructure in `infrastructure/`
5. Wire everything in `presentation/`

## Dependency Rule

Dependencies must point inward only:
- Domain depends on nothing
- Application depends on Domain
- Infrastructure depends on Application and Domain
- Presentation depends on all layers

See `references/clean-architecture.md` for detailed guidance.
