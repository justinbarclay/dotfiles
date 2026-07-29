# Emacs Lisp Functional Programming Idioms

Emacs Lisp supports functional programming through `seq.el`, pattern matching via `pcase`, and threading macros.

## 1. Pure List Combinators with `seq.el`

Prefer `seq.el` functions (`seq-map`, `seq-filter`, `seq-reduce`, `seq-take-while`) over imperative `while` loops and mutating accumulators.

```elisp
;; Preferred: Pure seq pipeline
(defun my/sum-even-squares (numbers)
  (thread-last numbers
    (seq-filter (lambda (n) (= 0 (% n 2))))
    (seq-map (lambda (n) (* n n)))
    (seq-reduce #'+ 0)))

;; Avoid: Imperative while loop with setq mutation
(defun my/sum-even-squares-imperative (numbers)
  (let ((sum 0)
        (rest numbers))
    (while rest
      (let ((n (car rest)))
        (when (= 0 (% n 2))
          (setq sum (+ sum (* n n)))))
      (setq rest (cdr rest)))
    sum))
```

## 2. Threading Macros (`thread-first` & `thread-last`)

Use `->` (`thread-first`) and `->>` (`thread-last`) to make nested function calls read sequentially as data pipelines.

```elisp
(thread-last (buffer-list)
  (seq-filter #'buffer-file-name)
  (seq-map #'buffer-name))
```

## 3. Pattern Matching with `pcase`

Use `pcase` and `pcase-let` for expression-oriented branching and destructuring instead of deep `cond` / `if` trees with `car`/`cdr`.

```elisp
(defun my/format-response (response)
  (pcase response
    (`(success . ,data) (format "OK: %s" data))
    (`(error . ,msg)    (format "ERR: %s" msg))
    (_                  "UNKNOWN")))
```

## 4. Avoiding Mutation

Avoid `setq`, `setf`, `nconc`, `setcdr`, and `delq` inside loop and function bodies. Return newly constructed immutable lists or structures using `cons`, `append`, or `mapcar`.
