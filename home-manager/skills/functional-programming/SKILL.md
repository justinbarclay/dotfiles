---
name: functional-programming
description: Use when designing, writing, editing, or refactoring code in Rust, TypeScript, JavaScript, or Emacs Lisp (Elisp). Enforces functional programming principles including immutability, pure functions, algebraic data types (ADTs), monadic error handling, iterator combinators, pattern matching, and function composition.
---

# Functional Programming Principles

Apply functional programming principles to build predictable, deterministic, and highly composable code across Rust, TypeScript, JavaScript, and Emacs Lisp.

## Core Rules

1. **Immutability First**: Default to immutable bindings and immutable data structures. Eliminate unnecessary `mut`, `let` reassignments, and in-place array/list mutation.
2. **Pure Functions & Side-Effect Isolation**: Keep core business logic pure (transparent inputs to outputs with zero side-effects). Push I/O, state mutation, and non-determinism out to system boundaries.
3. **Expression-Oriented Control Flow**: Prefer expressions returning values over mutating control structures. Replace imperative loops and `if-else` blocks with pattern matching and combinators (`map`, `filter`, `fold`/`reduce`).
4. **Type-Driven & Monadic Error Handling**: Represent domain states with Algebraic Data Types (ADTs) / discriminated unions. Handle errors explicitly using monadic types (`Option`, `Result`) or tagged error unions instead of null, undefined, or unhandled exceptions.
5. **Function Composition**: Build complex data transformations out of small, single-purpose, composable functions.

## Language-Specific References

When working with a specific language, read the corresponding reference file for detailed functional patterns, syntax examples, and idiomatic APIs:

- **Rust**: See [`references/rust.md`](references/rust.md) for `Iterator` combinators, `match` expressions, `Option`/`Result` monadic methods, and type-state pattern.
- **TypeScript & JavaScript**: See [`references/ts-js.md`](references/ts-js.md) for `readonly` constraints, pure array combinators, discriminated unions, and non-mutating transformations.
- **Emacs Lisp**: See [`references/elisp.md`](references/elisp.md) for `seq.el` combinators, `pcase` pattern matching, threading macros (`->`, `->>`), and pure list processing.

## Completion Criteria

The code design/implementation is complete when:
- Pure business logic is isolated from I/O.
- Variables use immutable bindings (`const`, `readonly`, non-`mut`, pure bindings).
- Domain states and error modes are explicitly represented without null/undefined/exceptions.
- Transformations use composable higher-order functions or pattern matching instead of imperative mutating loops.
