#!/bin/bash

# Defines a wrapper that lazy-loads a real shell function on first use, then
# forwards the original arguments. Example:
#   NVM_SCRIPT="/opt/homebrew/opt/nvm/nvm.sh"
#   _load_nvm_impl() { source "$NVM_SCRIPT"; }
#   define_lazy_function nvm _load_nvm_impl
# This keeps shell startup fast while still letting existing `nvm use ...`
# calls work without changing their call sites. In this repo, moving `nvm`
# to this pattern reduced fresh zsh startup from roughly ~2.35s to ~0.3-0.4s,
# while shifting the cost to the first actual `nvm` use (~2.0s).
define_lazy_function() {
  local function_name=$1
  local loader_name=$2

  eval "
$function_name() {
  unset -f $function_name
  $loader_name || return \$?
  $function_name \"\$@\"
}
"
}
