# Vertical Slice Architecture Template

This template provides a starting directory structure for Vertical Slice Architecture projects.

## Structure

```
features/                   # All features organized by use case
├── example_feature/        # Example feature slice
│   ├── handler.py         # Entry point (HTTP/CLI/etc.)
│   ├── command.py         # Business logic
│   ├── repository.py      # Data access
│   └── dto.py            # Data transfer objects
└── shared/                # Shared code (minimal)
    ├── domain/            # Cross-feature domain models
    └── infrastructure/    # Database, auth, etc.
```

## Usage

1. Copy this template to your project directory
2. Create a new directory under `features/` for each use case
3. Implement the entire feature vertically in its directory
4. Only move code to `shared/` when duplicated 3+ times

## Feature Organization Options

### Option 1: By Use Case (Recommended for CQRS)
```
features/
├── create_user/
├── update_user/
└── get_user/
```

### Option 2: Grouped by Entity
```
features/
├── users/
│   ├── create/
│   ├── update/
│   └── get/
└── orders/
    ├── place/
    └── cancel/
```

## Principles

- **Duplication First:** Copy code initially, extract to `shared/` later
- **Independence:** Features should not depend on each other
- **Vertical:** Each feature contains all layers (handler → logic → data)

See `references/vertical-slice.md` for detailed guidance.
