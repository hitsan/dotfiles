# Flux Architecture Template

This template provides a starting directory structure for Flux-based state management.

## Structure

```
store/                     # Store configuration
├── index.py              # Store setup and middleware
└── root_reducer.py       # Combine feature reducers

features/                  # Features with actions + reducers
├── todos/                # Example feature
│   ├── actions.py        # Action creators
│   ├── reducer.py        # State reducer
│   ├── selectors.py      # State selectors
│   └── types.py         # Action type constants
└── [other features]/

views/                     # UI components
├── todo_list.py
└── [other views]/
```

## Usage

1. Copy this template to your project directory
2. Create a new directory under `features/` for each state domain
3. Define actions, reducer, and selectors for each feature
4. Wire up store in `store/index.py`
5. Connect views to store

## Feature Structure (Redux/Ducks Pattern)

Each feature contains:
- **actions.py**: Action creator functions
- **reducer.py**: Pure reducer function
- **selectors.py**: State access functions
- **types.py**: Action type constants

Alternatively, use **slice.py** to combine actions and reducer in one file.

## Data Flow

```
User Interaction
    ↓
View dispatches Action
    ↓
Reducer updates Store
    ↓
Store notifies Views
    ↓
Views re-render
```

## Principles

- **Unidirectional Flow:** Data flows one way only
- **Immutability:** Never mutate state, return new objects
- **Pure Reducers:** No side effects in reducers
- **Single Source of Truth:** One store for entire state

See `references/flux.md` for detailed guidance.
