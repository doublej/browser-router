#!/bin/bash
# Setup git hooks for BrowserRouter

REPO_ROOT=$(git rev-parse --show-toplevel)
HOOKS_DIR="$REPO_ROOT/.git/hooks"

chmod +x "$HOOKS_DIR/post-commit"
chmod +x "$HOOKS_DIR/pre-push"

echo "Git hooks installed:"
echo "  - post-commit: Auto-builds app after each commit"
echo "  - pre-push: Verifies build before pushing"
