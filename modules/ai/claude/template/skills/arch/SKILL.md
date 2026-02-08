---
name: arch
description: Software architecture design guidance supporting Clean Architecture, Vertical Slice Architecture, and Flux patterns. Use when designing architecture for new projects (web apps, TUI apps, etc.), applying architectural patterns to existing codebases, refactoring monolithic applications, or choosing and combining appropriate architectural patterns. Triggered by requests like "design the architecture", "apply clean architecture", "refactor with layers", "choose an architecture pattern".
---

# Architecture Design

## Overview

Guides software architecture design using three proven patterns:
- **Clean Architecture**: Separation by layers, domain-centric
- **Vertical Slice Architecture**: Organization by features
- **Flux**: Unidirectional data flow for state management

Supports both new project design and existing system refactoring.

## Workflow

### Step 1: Understand Requirements

Use AskUserQuestion to gather information in two rounds:

**Round 1: Deep Dive into Application (自由記述を促す質問)**

Question 1: "What kind of application are you building? Describe its purpose and main functionality."
- Let user provide free-form description

Question 2: "What are the main features or use cases? List 3-5 examples."
- Examples: "User registration", "Product search", "Order processing", etc.
- Free-form response

Question 3: "How does the application handle data?"
- Options:
  - Mainly input/display (CRUD-focused)
  - Transform/process data into output (pipeline-style)
  - Process data with complex business rules
  - Monitor/update data in real-time

**Round 2: Architecture Decision Axes (アーキテクチャ判断軸)**

Based on Round 1 answers, ask targeted questions:

Question 4: "How frequently do business rules or requirements change?"
- Options:
  - Frequently (weekly/monthly feature additions or changes)
  - Occasionally (few times per quarter)
  - Stable (few times per year)

Question 5: "Does the application need multiple interfaces?"
- Options:
  - Single (e.g., Web only, CLI only)
  - Multiple needed (e.g., Web + API, CLI + TUI)
  - Potentially multiple in the future

Question 6: "How complex is state management?"
- Options:
  - Simple (mostly local state, minimal cross-screen coordination)
  - Moderate (some screens share state)
  - Complex (many components reference/update same state, many state transitions)

**Default Assumption:** Balanced approach to maintainability and extensibility (moderate structure, practical extensibility, avoid both over-engineering and under-engineering).

Analyze responses to identify patterns and recommend architecture in Step 2.

### Step 2: Select Architecture Pattern(s)

Based on requirements, recommend appropriate pattern(s):

**Quick Selection:**
- Complex business logic + long-term maintainability → **Clean Architecture**
- Feature-driven development + rapid iteration → **Vertical Slice**
- Complex UI state + multiple reactive components → **Flux**
- Combination needed? → See pattern combinations in selection guide

**Detailed guidance**: Read `references/selection-guide.md` for:
- Pattern comparison table
- Selection criteria for each pattern
- How to combine patterns
- Decision tree
- Migration paths

### Step 3: Design Architecture

Once pattern(s) are selected, create detailed design:

1. **Read pattern reference**:
   - `references/clean-architecture.md` for Clean Architecture
   - `references/vertical-slice.md` for Vertical Slice
   - `references/flux.md` for Flux

2. **Design components**:
   - Define layers/slices/stores based on pattern
   - Specify dependencies and data flow
   - Identify shared vs. feature-specific code

3. **Provide directory structure**:
   - Use templates in `assets/` as starting point
   - Customize based on project needs
   - Document key files and their purposes

4. **Document decisions**:
   - Explain why this pattern was chosen
   - Note any trade-offs or constraints
   - Provide implementation guidelines

## Supported Patterns

### Clean Architecture
**Best for**: Business logic-heavy applications, long-term maintainability

**Key concepts**: Dependency inversion, layered separation (Domain → Application → Infrastructure → Presentation)

**Template**: `assets/clean-arch-template/`

### Vertical Slice Architecture
**Best for**: Feature-driven development, independent teams, rapid iteration

**Key concepts**: Feature cohesion, duplication over coupling, vertical organization

**Template**: `assets/vertical-slice-template/`

### Flux
**Best for**: Complex UI state management, predictable state updates

**Key concepts**: Unidirectional data flow (Action → Reducer → Store → View)

**Template**: `assets/flux-template/`

## Pattern Combinations

Patterns can be combined for complex requirements:
- **Clean + Flux**: Domain logic in Clean layers, UI state in Flux
- **Vertical Slice + Flux**: Feature slices with Flux per slice
- **Clean + Vertical Slice**: Shared domain core, feature-specific slices
- **All three**: Large-scale applications with diverse needs

See `references/selection-guide.md` for combination strategies.

## Resources

### references/
Detailed architectural guidance loaded as needed:
- **selection-guide.md**: Pattern comparison, selection criteria, combinations
- **clean-architecture.md**: Layers, dependency rules, implementation details
- **vertical-slice.md**: Slice structure, shared code handling, CQRS
- **flux.md**: Components, variants (Redux/Zustand), patterns, testing

### assets/
Directory structure templates for each pattern:
- **clean-arch-template/**: Full Clean Architecture structure
- **vertical-slice-template/**: Feature-based organization
- **flux-template/**: Store, features, and views setup

Use these templates as starting points and customize for specific projects.

## Output Format

Provide architecture design as:
1. **Overview**: Chosen pattern(s) and rationale
2. **Architecture diagram**: ASCII or Mermaid visualization
3. **Directory structure**: Complete project layout
4. **Component descriptions**: Key files/modules and their roles
5. **Dependencies**: How components interact
6. **Implementation notes**: Guidelines for development
7. **Trade-offs**: Benefits and limitations of chosen approach
