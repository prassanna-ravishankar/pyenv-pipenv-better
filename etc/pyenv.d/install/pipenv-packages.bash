#!/usr/bin/env bash
source "${BASH_SOURCE[0]%/*}/../../../libexec/pipenv-packages.sh"

if declare -Ff after_install >/dev/null; then
  after_install 'install_pipenv $VERSION_NAME'
else
  echo "pyenv: pyenv-pipenv plugin requires pyenv v0.1.0 or later" >&2
fi