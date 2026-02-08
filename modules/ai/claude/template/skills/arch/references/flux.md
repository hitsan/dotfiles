# Flux Architecture

## Core Concept

**Principle:** Unidirectional data flow for predictable state management.

**Unidirectional Data Flow:**

1. **View** (user interaction) → dispatches **Action**
2. **Action** (what happened) → processed by **Reducer**
3. **Reducer** (pure function) → updates **Store**
4. **Store** (state container) → notifies subscribed **Views**
5. **Views** re-render based on new state

The flow is circular but unidirectional: View → Action → Reducer → Store → View

**Key Property:** Data flows in one direction only, making state changes predictable and traceable.

## Components

### 1. Store
**Central state container.**

**Responsibilities:**
- Hold application state
- Provide state access (selectors)
- Allow state updates via reducers only
- Notify subscribers of changes

**Example:**
```python
# Python (simple implementation)
class Store:
    def __init__(self, reducer, initial_state):
        self._state = initial_state
        self._reducer = reducer
        self._subscribers = []

    def get_state(self):
        return self._state

    def dispatch(self, action):
        self._state = self._reducer(self._state, action)
        self._notify()

    def subscribe(self, callback):
        self._subscribers.append(callback)

    def _notify(self):
        for callback in self._subscribers:
            callback(self._state)
```

### 2. Actions
**Describe what happened.**

**Responsibilities:**
- Plain data objects/dictionaries
- Have a type field
- Carry payload data
- Do not contain logic

**Example:**
```python
# Action creators
def add_todo(text):
    return {
        'type': 'ADD_TODO',
        'payload': {'text': text, 'id': uuid4()}
    }

def toggle_todo(todo_id):
    return {
        'type': 'TOGGLE_TODO',
        'payload': {'id': todo_id}
    }

# Usage
store.dispatch(add_todo("Buy milk"))
```

### 3. Reducers
**Specify how state changes.**

**Responsibilities:**
- Pure functions: `(state, action) → new_state`
- No side effects (no API calls, no mutations)
- Return new state object (immutability)
- Handle unknown actions by returning current state

**Example:**
```python
def todos_reducer(state=[], action):
    if action['type'] == 'ADD_TODO':
        return [*state, {
            'id': action['payload']['id'],
            'text': action['payload']['text'],
            'completed': False
        }]
    elif action['type'] == 'TOGGLE_TODO':
        return [
            {**todo, 'completed': not todo['completed']}
            if todo['id'] == action['payload']['id']
            else todo
            for todo in state
        ]
    else:
        return state
```

### 4. Views
**Display state and dispatch actions.**

**Responsibilities:**
- Subscribe to store
- Render based on current state
- Dispatch actions on user interaction
- No business logic (delegate to reducers)

**Example:**
```python
# TUI example (with textual or similar)
class TodoView:
    def __init__(self, store):
        self.store = store
        self.store.subscribe(self.render)

    def render(self, state):
        for todo in state['todos']:
            print(f"[{'x' if todo['completed'] else ' '}] {todo['text']}")

    def on_add_click(self, text):
        self.store.dispatch(add_todo(text))

    def on_toggle_click(self, todo_id):
        self.store.dispatch(toggle_todo(todo_id))
```

## Flux Variants

### Classic Flux (Facebook)
- Multiple stores
- Dispatcher coordinates actions
- Stores register with dispatcher

**When to use:** Legacy, not recommended for new projects.

### Redux
- Single store
- Middleware for side effects
- Time-travel debugging
- DevTools integration

**When to use:** Complex state, need debugging tools, established ecosystem.

### Zustand (Lightweight)
- Minimal boilerplate
- No reducers required (mutable updates allowed)
- Simpler API

**When to use:** Simpler apps, prefer less boilerplate.

### MobX (Observable)
- Observable state
- Automatic dependency tracking
- Less explicit than Redux

**When to use:** Prefer reactivity, less verbose code.

## Directory Structure

### Redux-Style Structure
```
src/
├── store/
│   ├── index.py              # Store configuration
│   ├── root_reducer.py       # Combine reducers
│   └── middleware/
│       └── logger.py
├── features/
│   ├── todos/
│   │   ├── actions.py        # Action creators
│   │   ├── reducer.py        # Todo reducer
│   │   ├── selectors.py      # State selectors
│   │   └── types.py          # Action types
│   └── filters/
│       ├── actions.py
│       ├── reducer.py
│       └── selectors.py
└── views/
    ├── todo_list.py
    └── filter_bar.py
```

### Feature-Based Structure (Ducks/Slices)
```
src/
├── store/
│   └── index.py
├── features/
│   ├── todos/
│   │   ├── slice.py          # Actions + Reducer together
│   │   ├── selectors.py
│   │   └── view.py
│   └── filters/
│       ├── slice.py
│       ├── selectors.py
│       └── view.py
└── app.py
```

### Simple Structure (Zustand-style)
```
src/
├── stores/
│   ├── todo_store.py         # Store + actions + state
│   └── filter_store.py
└── views/
    ├── todo_list.py
    └── filter_bar.py
```

## Patterns and Best Practices

### Normalized State Shape
❌ **Wrong:** Nested, duplicated data
```python
state = {
    'todos': [
        {'id': 1, 'text': 'Buy milk', 'author': {'id': 1, 'name': 'Alice'}},
        {'id': 2, 'text': 'Read book', 'author': {'id': 1, 'name': 'Alice'}}
    ]
}
```

✅ **Right:** Flat, normalized
```python
state = {
    'todos': {
        'byId': {
            1: {'id': 1, 'text': 'Buy milk', 'authorId': 1},
            2: {'id': 2, 'text': 'Read book', 'authorId': 1}
        },
        'allIds': [1, 2]
    },
    'users': {
        'byId': {
            1: {'id': 1, 'name': 'Alice'}
        }
    }
}
```

### Selectors for Derived State
❌ **Wrong:** Compute in view
```python
class TodoView:
    def render(self, state):
        completed = [t for t in state['todos'] if t['completed']]
        print(f"Completed: {len(completed)}")
```

✅ **Right:** Use selectors
```python
# selectors.py
def get_completed_todos(state):
    return [t for t in state['todos'] if t['completed']]

def get_completed_count(state):
    return len(get_completed_todos(state))

# view.py
class TodoView:
    def render(self, state):
        count = get_completed_count(state)
        print(f"Completed: {count}")
```

### Async Actions (Thunks/Side Effects)
❌ **Wrong:** Async in reducer
```python
def reducer(state, action):
    if action['type'] == 'FETCH_TODOS':
        todos = api.fetch_todos()  # ← Side effect in reducer!
        return {**state, 'todos': todos}
```

✅ **Right:** Middleware or thunks
```python
# Thunk action creator
def fetch_todos():
    def thunk(dispatch):
        dispatch({'type': 'FETCH_TODOS_REQUEST'})
        try:
            todos = api.fetch_todos()
            dispatch({'type': 'FETCH_TODOS_SUCCESS', 'payload': todos})
        except Exception as e:
            dispatch({'type': 'FETCH_TODOS_FAILURE', 'payload': str(e)})
    return thunk

# Reducer handles sync actions only
def reducer(state, action):
    if action['type'] == 'FETCH_TODOS_REQUEST':
        return {**state, 'loading': True}
    elif action['type'] == 'FETCH_TODOS_SUCCESS':
        return {**state, 'loading': False, 'todos': action['payload']}
    elif action['type'] == 'FETCH_TODOS_FAILURE':
        return {**state, 'loading': False, 'error': action['payload']}
```

### Action Type Constants
✅ **Use constants to avoid typos**
```python
# types.py
ADD_TODO = 'todos/ADD_TODO'
TOGGLE_TODO = 'todos/TOGGLE_TODO'
DELETE_TODO = 'todos/DELETE_TODO'

# actions.py
def add_todo(text):
    return {'type': ADD_TODO, 'payload': text}

# reducer.py
def reducer(state, action):
    if action['type'] == ADD_TODO:
        ...
```

## State Organization Strategies

### By Feature
```python
state = {
    'todos': {...},        # Todo feature state
    'filters': {...},      # Filter feature state
    'auth': {...}          # Auth feature state
}
```

### By Type
```python
state = {
    'entities': {          # All domain data
        'todos': {...},
        'users': {...}
    },
    'ui': {                # UI-specific state
        'selectedTodoId': 1,
        'filterVisible': True
    },
    'network': {           # Request state
        'loading': False,
        'error': None
    }
}
```

## Middleware

### Logger Middleware
```python
def logger_middleware(store):
    def middleware(next_dispatch):
        def dispatch(action):
            print(f"Action: {action['type']}")
            print(f"Prev State: {store.get_state()}")
            result = next_dispatch(action)
            print(f"Next State: {store.get_state()}")
            return result
        return dispatch
    return middleware
```

### Thunk Middleware (for async)
```python
def thunk_middleware(store):
    def middleware(next_dispatch):
        def dispatch(action):
            if callable(action):
                return action(store.dispatch, store.get_state)
            return next_dispatch(action)
        return dispatch
    return middleware
```

## Testing

### Reducer Tests (Pure Functions)
```python
def test_add_todo():
    state = []
    action = add_todo("Buy milk")
    new_state = todos_reducer(state, action)

    assert len(new_state) == 1
    assert new_state[0]['text'] == "Buy milk"
    assert new_state[0]['completed'] == False
```

### Selector Tests
```python
def test_get_completed_count():
    state = {
        'todos': [
            {'id': 1, 'completed': True},
            {'id': 2, 'completed': False},
            {'id': 3, 'completed': True}
        ]
    }
    assert get_completed_count(state) == 2
```

### Integration Tests
```python
def test_todo_flow():
    store = create_store(todos_reducer)

    store.dispatch(add_todo("Buy milk"))
    assert len(store.get_state()) == 1

    store.dispatch(toggle_todo(store.get_state()[0]['id']))
    assert store.get_state()[0]['completed'] == True
```

## Common Mistakes

### ❌ Mutating State
```python
def reducer(state, action):
    if action['type'] == 'ADD_TODO':
        state.append(action['payload'])  # ← Mutation!
        return state
```
**Fix:** Return new object/array.

### ❌ Too Many Actions
```python
SET_TODO_TEXT = 'SET_TODO_TEXT'
SET_TODO_COMPLETED = 'SET_TODO_COMPLETED'
SET_TODO_PRIORITY = 'SET_TODO_PRIORITY'
# ... 50 more micro-actions
```
**Fix:** Group related updates into one action.

### ❌ Business Logic in Views
```python
class TodoView:
    def on_add(self, text):
        if len(text) < 3:
            return  # ← Validation in view
        if profanity.check(text):
            return  # ← Business logic in view
        self.store.dispatch(add_todo(text))
```
**Fix:** Move validation to reducer or middleware.

### ❌ Global State for Everything
```python
state = {
    'mouseX': 10,           # ← No need in store
    'mouseY': 20,           # ← No need in store
    'todos': [...]
}
```
**Fix:** Keep transient UI state local to components.

## When to Use Flux

✅ **Use when:**
- Complex state shared across many components
- State updates need to be predictable and traceable
- Need time-travel debugging or state persistence
- Multiple views react to same state changes

❌ **Avoid when:**
- Application has simple, local state
- State rarely shared between components
- Server-side rendering with minimal client state
- Performance overhead of immutability is prohibitive

## Integration with Other Patterns

### Flux + Clean Architecture
- Flux manages UI/presentation state
- Clean Architecture for domain logic
- Use cases dispatch Flux actions

### Flux + Vertical Slice
- Each slice has its own Flux store
- Stores communicate via events or shared state
- Independent feature state management

## Migration from Imperative State

### Before (Imperative)
```python
class TodoApp:
    def __init__(self):
        self.todos = []

    def add_todo(self, text):
        self.todos.append({'text': text, 'completed': False})
        self.render()

    def toggle_todo(self, index):
        self.todos[index]['completed'] = not self.todos[index]['completed']
        self.render()
```

### After (Flux)
```python
store = create_store(todos_reducer)

class TodoApp:
    def __init__(self, store):
        self.store = store
        self.store.subscribe(self.render)

    def add_todo(self, text):
        self.store.dispatch(add_todo(text))

    def toggle_todo(self, todo_id):
        self.store.dispatch(toggle_todo(todo_id))

    def render(self, state):
        # Render based on state
```

## Resources

- **Redux:** Full-featured, mature ecosystem
- **Zustand:** Lightweight, minimal boilerplate
- **MobX:** Observable-based, automatic tracking
- **Pinia (Vue):** Vue-specific Flux implementation
- **Recoil (React):** Atomic state management
