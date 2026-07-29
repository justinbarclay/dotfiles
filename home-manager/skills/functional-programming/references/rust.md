# Rust Functional Programming Idioms

Rust's type system and ownership model natively support functional programming. Leverage these idioms to write clean, memory-safe, and expression-oriented Rust code.

## 1. Expression-Based Control Flow

In Rust, `match`, `if`, `if let`, and code blocks are expressions that return values.

```rust
// Preferred: Expression-based match
let status_code = match result {
    Ok(data) => process(data),
    Err(err) => {
        log_error(&err);
        500
    }
};

// Avoid: Mutating variable from inside branches
let mut status_code = 0;
if let Ok(data) = result {
    status_code = process(data);
} else {
    status_code = 500;
}
```

## 2. Iterator Combinators over Imperative Loops

Avoid explicit `for` loops with `mut` vectors or accumulators. Use lazy `Iterator` combinators.

```rust
// Preferred: Pure iterator pipeline
fn sum_even_squares(numbers: &[i32]) -> i32 {
    numbers
        .iter()
        .filter(|&&n| n % 2 == 0)
        .map(|&n| n * n)
        .sum()
}

// Avoid: Imperative loop with mutable accumulator
fn sum_even_squares_imperative(numbers: &[i32]) -> i32 {
    let mut sum = 0;
    for &n in numbers {
        if n % 2 == 0 {
            sum += n * n;
        }
    }
    sum
}
```

## 3. Monadic Chaining on `Option` and `Result`

Use combinators like `.map()`, `.and_then()`, `.map_err()`, `.unwrap_or_else()`, and `.transpose()` to chain operations smoothly.

```rust
fn get_user_domain(user_id: u64) -> Option<String> {
    find_user(user_id)
        .and_then(|user| user.email)
        .map(|email| extract_domain(&email))
}
```

## 4. Immutability & Borrowing

Default to immutable bindings (`let x = ...`). Leverage owned moves and shared references (`&T`) to enforce zero shared mutation.

## 5. Type-State Pattern with Zero-Sized Types

Make invalid states unrepresentable using marker types and PhantomData.

```rust
struct Draft;
struct Published;

struct Post<State> {
    content: String,
    _state: std::marker::PhantomData<State>,
}

impl Post<Draft> {
    fn publish(self) -> Post<Published> {
        Post {
            content: self.content,
            _state: std::marker::PhantomData,
        }
    }
}
```
