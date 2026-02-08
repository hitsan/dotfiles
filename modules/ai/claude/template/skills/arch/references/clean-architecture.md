# Clean Architecture

## Layer Structure

Clean Architecture consists of concentric layers with dependencies pointing inward:

**Layer 1 (Innermost - Core):** Enterprise Business Rules
- Contains: Entities, Domain Logic, Value Objects
- Dependencies: None (completely independent)

**Layer 2:** Application Business Rules
- Contains: Use Cases, Application Services
- Dependencies: Layer 1 only

**Layer 3:** Interface Adapters
- Contains: Controllers, Presenters, Gateways, Repository Implementations
- Dependencies: Layers 1 and 2

**Layer 4 (Outermost):** Frameworks & Drivers
- Contains: Web Frameworks, Databases, UI, External APIs
- Dependencies: All inner layers

**Dependency Rule:** Outer layers depend on inner layers, never the reverse.
- Layer 4 may depend on → Layer 3, 2, 1
- Layer 3 may depend on → Layer 2, 1
- Layer 2 may depend on → Layer 1
- Layer 1 depends on → Nothing

## Layers and Responsibilities

### 1. Domain (Enterprise Business Rules)
**What it contains:**
- Entities: Core business objects
- Value Objects: Immutable domain concepts
- Domain Events: Business-significant occurrences
- Domain Services: Business logic that doesn't fit in entities

**Rules:**
- No dependencies on outer layers
- No framework dependencies
- Pure business logic only
- Technology-agnostic

**Example:**
```
domain/
├── entities/
│   ├── user.py
│   └── order.py
├── value_objects/
│   ├── email.py
│   └── money.py
└── services/
    └── pricing_service.py
```

### 2. Application (Use Cases)
**What it contains:**
- Use Cases: Application-specific business rules
- Input/Output DTOs: Data transfer objects
- Repository Interfaces: Abstract data access
- Service Interfaces: External service contracts

**Rules:**
- Depends only on Domain layer
- Orchestrates domain objects
- Defines interfaces for outer layers
- No implementation details

**Example:**
```
application/
├── use_cases/
│   ├── create_user.py
│   └── place_order.py
├── interfaces/
│   ├── user_repository.py
│   └── email_service.py
└── dtos/
    ├── user_dto.py
    └── order_dto.py
```

### 3. Infrastructure (Interface Adapters)
**What it contains:**
- Controllers: HTTP/CLI/GUI handlers
- Presenters: Format data for output
- Repository Implementations: Data access
- External Service Adapters: API clients

**Rules:**
- Depends on Application and Domain
- Implements interfaces defined in Application
- Converts data between layers
- Contains adapter patterns

**Example:**
```
infrastructure/
├── web/
│   ├── controllers/
│   └── presenters/
├── persistence/
│   ├── user_repository_impl.py
│   └── database.py
└── external/
    └── email_service_impl.py
```

### 4. Presentation (Frameworks & Drivers)
**What it contains:**
- Web frameworks (FastAPI, Flask, etc.)
- Database engines (PostgreSQL, MongoDB, etc.)
- UI frameworks (React, Vue, etc.)
- External APIs and tools

**Rules:**
- Outermost layer
- Glue code that ties everything together
- Main application entry point
- Framework-specific configuration

**Example:**
```
presentation/
├── api/
│   ├── main.py (FastAPI app)
│   └── routes/
├── cli/
│   └── main.py (CLI entry point)
└── config/
    └── settings.py
```

## Dependency Inversion

### Problem: Use case needs to save data
❌ **Wrong:** Use case depends on concrete repository
```python
# use_case.py
from infrastructure.postgres_repository import PostgresUserRepository

class CreateUser:
    def __init__(self):
        self.repo = PostgresUserRepository()  # ← Hard dependency
```

✅ **Correct:** Use case depends on interface
```python
# application/use_cases/create_user.py
from application.interfaces.user_repository import UserRepository

class CreateUser:
    def __init__(self, repo: UserRepository):  # ← Depend on abstraction
        self.repo = repo

# infrastructure/persistence/postgres_repository.py
from application.interfaces.user_repository import UserRepository

class PostgresUserRepository(UserRepository):  # ← Implements interface
    def save(self, user): ...
```

## Directory Structure Example

```
project/
├── domain/
│   ├── __init__.py
│   ├── entities/
│   ├── value_objects/
│   └── services/
├── application/
│   ├── __init__.py
│   ├── use_cases/
│   ├── interfaces/
│   └── dtos/
├── infrastructure/
│   ├── __init__.py
│   ├── persistence/
│   ├── web/
│   └── external/
├── presentation/
│   ├── __init__.py
│   ├── api/
│   └── cli/
├── tests/
│   ├── domain/
│   ├── application/
│   └── infrastructure/
└── main.py
```

## Implementation Guidelines

### Start with Domain
1. Model core entities and value objects
2. Define domain services for cross-entity logic
3. Write domain tests (no mocks needed)

### Define Use Cases
1. Identify application workflows
2. Create use case classes
3. Define required interfaces (repositories, services)
4. Write use case tests (mock infrastructure)

### Implement Infrastructure
1. Implement repository interfaces
2. Build controllers and presenters
3. Wire dependencies using DI container
4. Write integration tests

### Assemble in Presentation
1. Configure framework
2. Set up dependency injection
3. Define routes/commands
4. Application entry point

## Common Mistakes

### ❌ Anemic Domain Model
Entities with only getters/setters, all logic in use cases
```python
class User:
    def __init__(self, email):
        self.email = email  # No validation, no behavior
```

### ✅ Rich Domain Model
Entities with behavior and invariants
```python
class User:
    def __init__(self, email: Email):  # Value object ensures validity
        self._email = email

    def change_email(self, new_email: Email):
        # Domain logic for email change
        if self._email == new_email:
            raise ValueError("Email is the same")
        self._email = new_email
```

### ❌ Use Case Knows About HTTP
```python
class CreateUser:
    def execute(self, request: HttpRequest):  # ← HTTP in use case
        email = request.json['email']
```

### ✅ Use Case Gets DTO
```python
class CreateUser:
    def execute(self, dto: CreateUserDTO):  # ← Clean DTO
        email = Email(dto.email)
```

### ❌ Domain Depends on Framework
```python
from sqlalchemy import Column, String

class User(Base):  # ← SQLAlchemy in domain
    email = Column(String)
```

### ✅ Domain Is Framework-Free
```python
class User:
    def __init__(self, email: Email):
        self._email = email

# Infrastructure maps domain to ORM separately
```

## Testing Strategy

### Domain Tests (Unit)
- Test business logic in isolation
- No mocks, no infrastructure
- Fast and deterministic

### Use Case Tests (Unit)
- Mock infrastructure dependencies
- Test application workflows
- Verify use case orchestration

### Integration Tests
- Test infrastructure implementations
- Test database operations
- Test external service adapters

### End-to-End Tests
- Test full user workflows
- Test through presentation layer
- Validate entire system

## When to Relax the Rules

- **Small projects:** May collapse Application + Domain into one layer
- **Simple CRUD:** May skip use cases for basic operations
- **Read models:** Can bypass domain for queries (CQRS)
- **Performance:** May optimize hot paths with infrastructure knowledge

The goal is maintainability and testability, not architectural purity.
