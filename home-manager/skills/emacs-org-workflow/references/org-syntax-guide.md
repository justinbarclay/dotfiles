# Org-Mode Syntax & Graphviz Guide

Follow these Org-mode conventions when writing developer documentation and architecture diagrams.

## 1. Document Structure & Metadata Headers

Every Org document must begin with metadata headers:

```org
#+TITLE: System Architecture & Design
#+AUTHOR: Justin Cole Barclay
#+DATE: 2026-07-29

* System Overview
This document describes the high-level architecture.

** Core Subsystems
- Subsystem A: Data processing
- Subsystem B: Storage engine
```

## 2. Source Blocks (`#+begin_src`)

Format code snippets using explicit language headers:

```org
#+begin_src elisp
(defun my/org-helper ()
  (interactive)
  (message "Hello from Org!"))
#+end_src
```

## 3. Graphviz Diagram Source Blocks (`dot`)

Use Graphviz `dot` blocks for architecture diagrams and flowcharts:

```org
#+begin_src dot :file architecture.png :cmdline -Tpng
digraph system_architecture {
    rankdir=LR;
    node [shape=box, style=rounded];

    Client -> APIGateway [label="HTTPS"];
    APIGateway -> WorkerPool [label="gRPC"];
    WorkerPool -> Database [label="SQL"];
}
#+end_src
```

## 4. Org Tables, Links, and Formatting

- **Bold**: `*bold*`
- **Italic**: `/italic/`
- **Code / Verbatim**: `=code=` or `~verbatim~`
- **Links**: `[[file:path/to/file.org][Link Description]]`
- **Tables**:
```org
| Component | Status   | Owner  |
|-----------+----------+--------|
| API       | Active   | Justin |
| DB        | Migrated | Ops    |
```
