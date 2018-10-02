#!/usr/bin/env sh

## Some Variables to use in this script

# VERSION_NAMES=($(pyenv-version-name))
# export PYENV_VERSION="${VERSION_NAMES}"

GET_PIPENV_URL="https://raw.githubusercontent.com/kennethreitz/pipenv/master/get-pipenv.py"
# Pip urls are dyamically calculated, so you'll find them down there

if [ -z "${PYENV_VIRTUALENV_CACHE_PATH}" ]; then
  PYENV_PIPENV_CACHE_PATH="${PYTHON_BUILD_CACHE_PATH:-${PYENV_ROOT}/cache}"
fi


### Helper functions
http() {
  local method="$1"
  local url="$2"
  local file="$3"
  [ -n "$url" ] || return 1

  if type curl &>/dev/null; then
    "http_${method}_curl" "$url" "$file"
  elif type wget &>/dev/null; then
    "http_${method}_wget" "$url" "$file"
  else
    echo "error: please install \`curl\` or \`wget\` and try again" >&2
    exit 1
  fi
}

http_head_curl() {
  curl -qsILf "$1" >&4 2>&1
}

http_get_curl() {
  curl -C - -o "${2:--}" -qsSLf "$1"
}

http_head_wget() {
  wget -q --spider "$1" >&4 2>&1
}

http_get_wget() {
  wget -nv -c -O "${2:--}" "$1"
}

build_package_get_pipenv() {
  echo "Building PIPenv package"
  local get_pipenv="${PYENV_PIPENV_CACHE_PATH}/get-pipenv.py"
  rm -f "${get_pipenv}"
  { if [ "${GET_PIPENV+defined}" ] && [ -f "${GET_PIPENV}" ]; then
      echo "Installing pip from ${GET_PIPENV}..." 1>&2
      cat "${GET_PIPENV}"
    else
      [ -n "${GET_PIPENV_URL}" ]
      echo "Installing pip from ${GET_PIPENV_URL}..." 1>&2
      http get "${GET_PIPENV_URL}"
    fi
  } 1> "${get_pipenv}"
  pyenv-exec python "${get_pipenv}" ${GET_PIP_OPTS} 1>&2 || {
    echo "error: failed to install pip via get-pipenv.py" >&2
    return 1
  }
}

build_package_get_pip() {
  echo "Building PIP package"
  local get_pip="${PYENV_PIPENV_CACHE_PATH}/get-pip.py"
  rm -f "${get_pip}"
  { if [ "${GET_PIP+defined}" ] && [ -f "${GET_PIP}" ]; then
      echo "Installing pip from ${GET_PIP}..." 1>&2
      cat "${GET_PIP}"
    else
      [ -n "${GET_PIP_URL}" ]
      echo "Installing pip from ${GET_PIP_URL}..." 1>&2
      http get "${GET_PIP_URL}"
    fi
  } 1> "${get_pip}"
  pyenv-exec python -s "${get_pip}" ${GET_PIP_OPTS} 1>&2 || {
    echo "error: failed to install pip via get-pip.py" >&2
    return 1
  }
}
## End helper functions



get_pip_url() {

  echo "Getting the right PIP url"

  if [ -z "${GET_PIP_URL}" ]; then
    if [ -n "${PIP_VERSION}" ]; then
      { colorize 1 "WARNING"
        echo ": Setting PIP_VERSION=${PIP_VERSION} is no longer supported and may cause failures during the install process."
      } 1>&2
      GET_PIP_URL="https://raw.githubusercontent.com/pypa/pip/${PIP_VERSION}/contrib/get-pip.py"
      # Unset `PIP_VERSION` from environment before invoking `get-pip.py` to deal with "ValueError: invalid truth value" (pypa/pip#4528)
      unset PIP_VERSION
    else
      # Use custom get-pip URL based on the target version (#1127)
      case "${PYENV_VERSION}" in
      2.6 | 2.6.* )
        GET_PIP_URL="https://bootstrap.pypa.io/2.6/get-pip.py"
        ;;
      3.2 | 3.2.* )
        GET_PIP_URL="https://bootstrap.pypa.io/3.2/get-pip.py"
        ;;
      3.3 | 3.3.* )
        GET_PIP_URL="https://bootstrap.pypa.io/3.3/get-pip.py"
        ;;
      * )
        GET_PIP_URL="https://bootstrap.pypa.io/get-pip.py"
        ;;
      esac
    fi
  fi
  echo "PIP url is : ${GET_PIP_URL}"
  return 1
}




install_pipenv() {
  # Only install default packages after successfully installing Python.
  [ "$STATUS" = "0" ] || return 0

  local installed_version
  installed_version=$1
  PYENV_VERSION="$installed_version"
  echo "${PYENV_VERSION} is your pyenv version"


  mkdir -p "${PYENV_PIPENV_CACHE_PATH}"
  cd "${PYENV_PIPENV_CACHE_PATH}"
  
  # Installing pipenv and required projects
  echo "Installed pipenv"
  build_package_get_pipenv || {
    echo "will attempt building pip and then pip install pipenv"
    get_pip_url
    echo "PIP url is : ${GET_PIP_URL}, building ..."
    build_package_get_pip
    echo "Executing pip install pyenv"
    pyenv-exec pip install pipenv
  }
  echo "Installed pipenv"  
  
}
