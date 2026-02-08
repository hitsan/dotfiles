# Vertical Slice Architecture

## Core Concept

**Principle:** Organize code by feature/use case, not by technical layer.

**Traditional Layers (Horizontal):**
- Controllers (all features)
- Services (all features)
- Repositories (all features)
- Database (all features)

Change a feature → touch multiple layers across the codebase

**Vertical Slices:**
- Slice 1: Create User (contains all layers for this feature)
- Slice 2: List Users (contains all layers for this feature)
- Slice 3: Update User (contains all layers for this feature)

Change a feature → change only one slice

**Key Difference:** Horizontal organization separates by technical concern, vertical organization groups by business feature.

## What Is a Slice?

A slice contains **everything needed for a single feature or use case:**
- Request handling
- Validation
- Business logic
- Data access
- Response formatting

**Each slice is self-contained and independent.**

## Slice Structure

### Basic Slice Pattern
```
features/
├── create_user/
│   ├── handler.py        # Entry point (HTTP/CLI/etc.)
│   ├── validator.py      # Input validation
│   ├── command.py        # Business logic
│   ├── repository.py     # Data access
│   └── dto.py           # Data transfer objects
└── get_user/
    ├── handler.py
    ├── query.py
    └── dto.py
```

### Alternative: Grouped by Entity
```
features/
├── users/
│   ├── create/
│   │   ├── handler.py
│   │   ├── command.py
│   │   └── dto.py
│   ├── list/
│   │   ├── handler.py
│   │   ├── query.py
│   │   └── dto.py
│   └── update/
│       ├── handler.py
│       ├── command.py
│       └── dto.py
└── orders/
    ├── place/
    └── cancel/
```

## Handling Shared Code

### The Rule: Duplication First, Abstraction Later

❌ **Wrong:** Premature abstraction
```
shared/
├── validators/
├── repositories/
└── services/
```
Creates coupling between slices.

✅ **Right:** Copy code initially
```
features/
├── create_user/
│   └── email_validator.py   # Duplicated
└── update_user/
    └── email_validator.py   # Duplicated
```

✅ **Right:** Extract when duplicated 3+ times
```
shared/
└── domain/
    └── email.py             # Value object used by multiple slices

features/
├── create_user/
│   └── command.py           # Uses shared/domain/email.py
└── update_user/
    └── command.py           # Uses shared/domain/email.py
```

### Shared Code Categories

| Type | When to Share | Where to Put |
|------|---------------|--------------|
| **Domain Models** | Core business concepts | `shared/domain/` |
| **Infrastructure** | Database, auth, logging | `shared/infrastructure/` |
| **Utilities** | Generic helpers | `shared/utils/` |
| **Feature Logic** | Never (duplicate first) | Keep in slice |

## Directory Structure Example

### Simple Project
```
project/
├── features/
│   ├── __init__.py
│   ├── create_user/
│   │   ├── __init__.py
│   │   ├── handler.py
│   │   ├── command.py
│   │   └── repository.py
│   ├── get_user/
│   │   ├── handler.py
│   │   ├── query.py
│   │   └── repository.py
│   └── list_users/
│       ├── handler.py
│       └── query.py
├── shared/
│   ├── domain/
│   │   └── user.py
│   └── infrastructure/
│       └── database.py
├── api/
│   └── main.py              # Wire up handlers
└── tests/
    └── features/
        ├── test_create_user.py
        └── test_get_user.py
```

### Complex Project
```
project/
├── features/
│   ├── users/
│   │   ├── create/
│   │   ├── update/
│   │   ├── delete/
│   │   └── shared/         # Shared within users domain
│   │       └── user_exists_validator.py
│   ├── orders/
│   │   ├── place/
│   │   ├── cancel/
│   │   └── shared/
│   └── payments/
│       ├── process/
│       └── refund/
├── shared/
│   ├── domain/             # Cross-domain models
│   ├── infrastructure/     # Technical infrastructure
│   └── kernel/             # Framework, DI, etc.
└── api/
    └── main.py
```

## CQRS Integration

Vertical Slice naturally fits CQRS (Command Query Responsibility Segregation):

### Commands (Write Operations)
```
features/
├── create_user/
│   ├── command.py          # CreateUserCommand
│   ├── handler.py          # CreateUserHandler
│   └── validator.py        # Complex validation
└── update_user/
    ├── command.py
    └── handler.py
```

### Queries (Read Operations)
```
features/
├── get_user/
│   ├── query.py            # GetUserQuery
│   └── handler.py          # GetUserHandler (may use different DB)
└── list_users/
    ├── query.py
    └── handler.py
```

**Benefits:**
- Commands can use write-optimized DB (normalized)
- Queries can use read-optimized DB (denormalized, cache)
- Independent scaling and optimization

## Implementation Workflow

### 1. Identify Slice Boundaries
Group by **user-facing features**, not technical layers:
- "Create a new user account"
- "Update user profile"
- "List all users"

### 2. Implement Slice Vertically
Build the entire feature top-to-bottom:
```
1. Handler (HTTP/CLI)
2. Validation
3. Business logic
4. Data access
5. Response
```

### 3. Test Slice Independently
Each slice has its own tests:
```python
# tests/features/test_create_user.py
def test_create_user_success():
    result = CreateUserHandler().handle(CreateUserCommand(...))
    assert result.is_success
```

### 4. Extract Shared Code When Needed
When you duplicate code 3+ times:
1. Extract to `shared/`
2. Update slices to use shared code
3. Test slices still work independently

## Communication Between Slices

### ❌ Direct Coupling
```python
# features/order/place/handler.py
from features.user.get.query import GetUserQuery  # ← Bad

def place_order(user_id):
    user = GetUserQuery().execute(user_id)  # Direct dependency
```

### ✅ Shared Domain or Events
```python
# features/order/place/handler.py
from shared.domain.user import UserRepository  # ← Shared infrastructure

def place_order(user_id):
    user = UserRepository().get(user_id)

# OR use domain events
from shared.events import UserCreatedEvent

def on_user_created(event: UserCreatedEvent):
    # React to event
```

### ✅ Mediator Pattern
```python
# features/order/place/handler.py
from shared.mediator import Mediator

def place_order(user_id):
    user = Mediator.send(GetUserQuery(user_id))  # Indirect via mediator
```

## Common Patterns

### Request-Handler Pattern
```python
# features/create_user/handler.py
class CreateUserRequest:
    email: str
    name: str

class CreateUserHandler:
    def handle(self, request: CreateUserRequest) -> CreateUserResponse:
        # All logic in one place
        validator.validate(request)
        user = User(email=request.email, name=request.name)
        repository.save(user)
        return CreateUserResponse(user)
```

### Pipeline Pattern
```python
# features/create_user/pipeline.py
class CreateUserPipeline:
    def execute(self, request):
        return (
            request
            |> validate
            |> create_user
            |> save_to_db
            |> send_email
            |> format_response
        )
```

## Migration from Layered Architecture

### Step 1: Identify Features
Map existing code to features/use cases.

### Step 2: Create Slices
For each feature, create a slice directory.

### Step 3: Copy Code into Slices
Copy controller, service, repository code into slice.
```
Before:
├── controllers/user_controller.py
├── services/user_service.py
└── repositories/user_repository.py

After:
└── features/create_user/
    ├── handler.py          # From controller
    ├── service.py          # From service
    └── repository.py       # From repository
```

### Step 4: Remove Unnecessary Abstractions
Inline or simplify code that was over-abstracted.

### Step 5: Test Each Slice
Ensure each slice works independently.

## Anti-Patterns

### ❌ Nano-Slices
Too many tiny slices (one per HTTP endpoint):
```
features/
├── get_user_by_id/
├── get_user_by_email/
└── get_user_by_name/
```
**Fix:** Group related queries into one slice.

### ❌ Shared Everything
```
shared/
├── services/
├── validators/
├── repositories/
└── helpers/
```
Defeats the purpose. Keep shared code minimal.

### ❌ Cross-Slice Dependencies
```python
from features.users.create import CreateUserCommand  # ← Coupling
```
**Fix:** Use shared domain or events.

### ❌ God Slices
One slice doing too much:
```
features/
└── user_management/  # 10,000 lines
```
**Fix:** Split into smaller, focused slices.

## Testing Strategy

### Slice-Level Tests (Primary)
Test the entire slice as a unit:
```python
def test_create_user_slice():
    # Arrange
    request = CreateUserRequest(email="test@example.com")

    # Act
    response = CreateUserHandler().handle(request)

    # Assert
    assert response.is_success
    assert database.has_user("test@example.com")
```

### Integration Tests
Test slice with real infrastructure:
```python
def test_create_user_integration():
    response = api_client.post("/users", json={"email": "..."})
    assert response.status_code == 201
```

### Unit Tests (Optional)
Only for complex business logic within a slice.

## Benefits Recap

- **Easy to locate code:** All code for a feature is in one place
- **Independent changes:** Modify one feature without affecting others
- **Simpler testing:** Test entire feature as a unit
- **Easier onboarding:** New developers can work on one slice
- **Flexible architecture:** Each slice can use different patterns
- **Reduced coupling:** Features don't depend on each other

## When NOT to Use Vertical Slice

- Complex shared domain logic across features → Use Clean Architecture
- Need strong architectural boundaries → Use Layered Architecture
- Team values consistency over independence → Use traditional patterns
