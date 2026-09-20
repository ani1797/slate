# Checks for slate-dev: the language runtimes.
#
# A runtime that is installed but cannot execute is worse than one that is
# absent, so each is actually run rather than merely located.

check "bun runs" bun --version
check "go runs" go version
check "node runs" node --version
check "npm runs" npm --version
check "rustc runs" rustc --version
check "cargo runs" cargo --version
check "uv runs" uv --version
