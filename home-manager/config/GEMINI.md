# Gemini

This file contains instructions for interacting with the Gemini AI

## Agent Interaction

Before interacting with Gemini, please check for the existence of an `AGENTS.md` file in the same directory. This file contains specific instructions and context that should be provided to the agent before beginning a session.

If an `AGENTS.md` file exists, please follow the instructions within it to ensure the agent has the necessary context to complete the task.

# Context: Senior Software Engineer (Justin Cole Barclay)

## Core Tech Stack
- **Backend:** Ruby on Rails (SaaS), Rust (AWS Lambda, CLI tools).
- **Frontend:** React (React Router 7), TypeScript, XState.
- **Environment:** Emacs & Org-mode.

## Technical Philosophy & Coding Standards
- **Type-First Development:** Always prefer stronger typing and static analysis regardless of the language. Lean into Rust's type system and TypeScript's strict mode.
- **Functional Patterns:** Prioritize immutability, pure functions, and higher-order functions. Avoid shared mutable state.
- **Data-Driven Architectures:** Prefer pure data systems (like RR7 routing) over component-heavy hierarchies.

## Development Workflow
- **Development Docs:** When writing development documentation use org mode syntax. Be sure to write developer documentation for moderate and higher complex systems
- **Testing Lifecycle:** Adopt a "test before and after" approach. Ensure existing tests pass before starting, and new features/refactors are fully covered before completion.
- **Atomic Commits:** Keep commits logical and atomic. One change per commit to maintain a clean, reversible history.
- **Conventional Commits:** Use the [Conventional Commits](https://www.conventionalcommits.org/) specification (e.g., `feat:`, `fix:`, `refactor:`, `test:`).

## Communication & Output Rules
- **Speak Plainly:** Do not be sycophantic. If something is a bad idea tell me. If something is a good idea there is no reason to build it up to be the best idea.
- **Conciseness:** Provide direct answers. No conversational filler.
- **Code Generation:** - Ensure all generated code is strongly typed.
  - Follow idiomatic functional patterns for the target language.
  - Suggest test cases (unit or integration) alongside implementation.
﻿- **Emacs Integration:** When the task involves Emacs configuration specifically, use `use-package` and Org-mode syntax for configuration snippets.

## Agent Documentation

 Maintain the following files to provide agents with persistent context:

 - `AGENTS.md` (per-directory): purpose, invariants, gotchas, non-obvious decisions
 - `ARCHITECTURE.md` (repo root): system design, module boundaries, data flow
 - `docs/adr/` : Architecture Decision Records — what was decided, why, what was rejected

## Project Contexts
- **Tidal Accelerator:** Focus on SaaS security and high-performance data operations.
- **Read on Supernote:** Focus on minimalist UI constraints and efficient Rust-based backends.
