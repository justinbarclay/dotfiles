---
name: unnested-rspec-testing
description: Use when writing, editing, refactoring, or reviewing RSpec test suites in Ruby or Rails applications.
---

# Unnested RSpec Testing Guidelines

Enforce flat, readable, and specification-focused RSpec test design for Ruby and Rails applications.

## Core Rules

1. **Flat Nesting Discipline**: Keep specs as unnested as possible. Limit nesting to a single top-level `RSpec.describe` and at most one optional shallow `describe` or `context` block. Deeply nested `context` trees obscure test state and introduce redundant test names.
2. **Expressive Specification Names**: Write clear `it` statements that fully describe the behavior being tested, without relying on concatenated `context` titles to make sense.
3. **Explicit & Local Setup**: Avoid deep `before(:each)` cascades and implicit `let!` chains defined miles above the test. Prefer explicit setup or simple helper methods inside or near the test block.
4. **Behavior over Implementation Details**: Focus test assertions on public interfaces, state changes, return values, or database effects—never private methods or internal execution details.

## Good vs. Bad Patterns

### Preferred (Flat & Expressive):

```ruby
RSpec.describe UserRegistrationService do
  it "creates a user record and sends a welcome email when params are valid" do
    params = { email: "user@example.com", name: "Justin" }

    result = described_class.call(params)

    expect(result).to be_success
    expect(User.find_by(email: "user@example.com")).to be_present
    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end

  it "returns an error result when email is missing" do
    result = described_class.call(name: "Justin")

    expect(result).to be_failure
    expect(result.errors).to include("Email cannot be blank")
  end
end
```

### Avoid (Overly Nested):

```ruby
# AVOID: Deep nesting obscures flow and makes specs fragile
RSpec.describe UserRegistrationService do
  describe "#call" do
    context "when params are valid" do
      before { @result = described_class.call(params) }
      
      context "with email present" do
        it "creates user" do
          # ...
        end
      end
    end
  end
end
```

## Completion Criteria

The RSpec test task is complete when:
- Specs have zero or minimal nesting (maximum 1 level below top-level `describe`).
- Each `it` block description clearly states expected behavior.
- Test setups are explicit and unnested.
- Existing and new specs pass cleanly.
