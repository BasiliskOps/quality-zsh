# Quality Kit — zsh, separate-repo friendly

Keep this repo **separate** from product code. You have two ways to use it:

## Option A — Reuse CI remotely
No files copied. Your product repo references a **reusable workflow** from this repo.

1) In your product repo, create `.github/workflows/ci.yml` with:

```yaml
name: ci
on:
  pull_request:
  push:
    branches: [ main ]
jobs:
  use-quality:
    uses: basiliskops/quality-zsh/.github/workflows/quality-reusable.yml@main
