# Architecture Selection Guide

## Pattern Comparison

| Pattern | Primary Focus | Best For | Complexity | Scalability |
|---------|--------------|----------|------------|-------------|
| **Clean Architecture** | Separation of concerns by layers | Business logic-heavy apps, long-term maintainability | High | High |
| **Vertical Slice Architecture** | Feature cohesion | Feature-driven development, rapid iteration | Low-Medium | Medium-High |
| **Flux** | Unidirectional data flow | UI state management, complex user interactions | Medium | Medium |

## Selection Criteria

### Choose Clean Architecture when:
- Business logic is complex and needs to be tested independently
- Multiple interfaces (Web, CLI, API) share the same domain logic
- Long-term maintainability is critical
- Team is comfortable with abstraction layers
- Changing frameworks/databases is a concern

**Avoid when:**
- Rapid prototyping is the priority
- Application is primarily CRUD with minimal business logic
- Team is small and values simplicity over structure

### Choose Vertical Slice Architecture when:
- Features are relatively independent
- Fast iteration and feature delivery are priorities
- Team wants to minimize cross-cutting concerns
- Each feature may have different technical requirements
- Onboarding new developers to specific features is important

**Avoid when:**
- Shared business logic is extensive
- Consistency across features is more important than feature independence
- Team prefers strong architectural boundaries

### Choose Flux when:
- Managing complex UI state and interactions
- Multiple components need to react to the same state changes
- State updates need to be predictable and traceable
- Time-travel debugging or state persistence is valuable
- Application is frontend-heavy (SPA, TUI with complex state)

**Avoid when:**
- Application state is simple and local
- Server-side rendering with minimal client state
- Performance overhead of immutability is a concern

## Combining Patterns

### Clean Architecture + Flux
**Use case:** Complex application with rich UI and business logic

- Clean Architecture for backend/domain layers
- Flux for frontend/presentation layer state management
- Communication: Domain use cases dispatch Flux actions

**Example:** E-commerce platform with complex checkout flow and inventory management

```
Domain Layer (Clean Arch)
    ↓ Use Cases
UI Layer (Flux)
    Store → View → Actions → Store
```

### Vertical Slice + Flux
**Use case:** Feature-driven app with complex UI state per feature

- Vertical Slice for feature organization
- Flux within each slice for UI state management
- Each slice has its own Flux store/actions

**Example:** Dashboard application where each widget is an independent feature

```
Feature Slice A
    ├── UI (Flux)
    ├── Logic
    └── Data Access

Feature Slice B
    ├── UI (Flux)
    ├── Logic
    └── Data Access
```

### Clean Architecture + Vertical Slice (Hybrid)
**Use case:** Shared domain logic with feature-specific implementation

- Core domain logic in Clean Architecture layers
- Feature slices for application-specific concerns
- Slices depend on shared domain layer

**Example:** Multi-tenant SaaS with shared business rules but tenant-specific features

```
Shared Domain (Clean Arch)
    ↓
Feature Slices
    ├── Tenant A Features
    ├── Tenant B Features
    └── Common Features
```

### All Three (Advanced)
**Use case:** Large-scale application with diverse requirements

- Clean Architecture for core business logic
- Vertical Slice for feature organization
- Flux for UI state in complex features

**Structure:**
```
Domain Core (Clean Arch)
    ↓
Feature Slices
    ├── Feature A
    │   ├── Domain Logic
    │   └── UI (Flux)
    └── Feature B
        ├── Domain Logic
        └── UI (Simple)
```

## Decision Tree

**Question 1: What is the primary concern?**

**Option A: Business Logic Complexity**
- If HIGH → Choose **Clean Architecture**
  - Follow-up: Also need feature independence?
    - If YES → Add **Vertical Slice** on top of Clean Architecture

**Option B: Feature Independence**
- If HIGH → Choose **Vertical Slice Architecture**
  - Follow-up: Complex domain logic shared across features?
    - If YES → Add **Clean Architecture** core
  - Follow-up: Complex UI state management needed?
    - If YES → Add **Flux** per slice

**Option C: UI State Complexity**
- If HIGH → Choose **Flux**
  - Follow-up: Complex business logic beyond UI state?
    - If YES → Add **Clean Architecture** for domain layer
  - Follow-up: Application is feature-driven?
    - If YES → Add **Vertical Slice** organization

## Migration Paths

### From Monolith to Clean Architecture
1. Identify core business logic
2. Extract to domain layer
3. Create use case layer
4. Adapt existing code as infrastructure

### From Layered to Vertical Slice
1. Identify feature boundaries
2. Group related layers into slices
3. Duplicate shared code initially
4. Extract truly shared logic later

### Adding Flux to Existing Architecture
1. Identify complex state management areas
2. Introduce Flux incrementally per feature/component
3. Keep simple state local
4. Migrate complex state to Flux store

## Anti-Patterns

- **Over-engineering:** Don't apply Clean Architecture to simple CRUD apps
- **Slice explosion:** Too many tiny slices creates maintenance burden
- **Global Flux store:** Not all state belongs in Flux; keep local state local
- **Pattern mixing without purpose:** Combine patterns to solve problems, not for architectural purity
