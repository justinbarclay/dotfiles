# TypeScript & JavaScript Functional Programming Idioms

Functional patterns in TS/JS focus on strict immutability, pure functions, type-driven discriminated unions, and non-mutating array combinators.

## 1. Immutability & Readonly Types

Always use `const` bindings and enforce static immutability with TypeScript `readonly`.

```typescript
// Preferred: Readonly types and const bindings
interface User {
  readonly id: string;
  readonly name: string;
  readonly roles: ReadonlyArray<string>;
}

// Non-mutating update using object spread
const addRole = (user: User, newRole: string): User => ({
  ...user,
  roles: [...user.roles, newRole],
});
```

## 2. Non-Mutating Array Operations

Avoid in-place array mutation (`.push()`, `.splice()`, `.sort()`). Use pure array methods (`.map()`, `.filter()`, `.reduce()`, `.concat()`, `.slice()`, or ES2023 `.toSorted()`, `.toSpliced()`).

```typescript
// Preferred: Pure pipeline
const getActiveUserNames = (users: ReadonlyArray<User>): ReadonlyArray<string> =>
  users
    .filter((u) => u.isActive)
    .map((u) => u.name);

// Avoid: Array push and let loops
const getActiveUserNamesImperative = (users: User[]): string[] => {
  const names: string[] = [];
  for (let i = 0; i < users.length; i++) {
    if (users[i].isActive) {
      names.push(users[i].name);
    }
  }
  return names;
};
```

## 3. Discriminated Unions for Domain & Error Modeling

Model state transitions and explicit errors using tagged unions instead of exceptions or nullable values.

```typescript
type AsyncResult<T, E = string> =
  | { readonly status: 'idle' }
  | { readonly status: 'loading' }
  | { readonly status: 'success'; readonly data: T }
  | { readonly status: 'error'; readonly error: E };

const renderState = (state: AsyncResult<string>): string => {
  switch (state.status) {
    case 'idle': return 'Ready';
    case 'loading': return 'Loading...';
    case 'success': return `Data: ${state.data}`;
    case 'error': return `Error: ${state.error}`;
  }
};
```

## 4. Pure Functions & Side-Effect Isolation

Ensure functions are deterministic with no hidden global state or side effects. Pass all context as parameters.

```typescript
// Preferred: Pure, explicit dependency passing
const calculateTotal = (items: ReadonlyArray<{ readonly price: number }>, taxRate: number): number =>
  items.reduce((acc, item) => acc + item.price, 0) * (1 + taxRate);
```
