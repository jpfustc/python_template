#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Automatic Initialization of Python Repo Interractively

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --flag      Some flag description
-p, --param     Some param description
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''
  name=''
  base_dir=''
  venv_flag=0
  venv_name="/home/jpfustc/projects/venv_general"
  git_flag=1
  poetry_flag=1

  while :; do
    case "${1-}" in
    -n | --name)
      name="${2-}"
      base_dir=$(dirname ${name})
      shift;;
    -h | --help) usage ;;
    -ng | --no-git) git_flag=0;;
    -np | --no-poetry) poetry_flag=0;;
    --venv) venv_flag=1;;
    -v | --verbose) set -x;;
    --no-color) NO_COLOR=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  # [[ -z "${param-}" ]] && die "Missing required parameter: param"
  [[ -z "${name-}" ]] && die "Missing required parameter: name"
  # [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

  return 0
}

# Bash Initialization
parse_params "$@"
setup_colors


# script logic here

msg "${RED}Read parameters:${NOFORMAT}"
msg "- flag: ${flag}"
msg "- venv_flag: ${venv_flag}"
msg "- git_flag: ${git_flag}"
msg "- poetry_flag: ${poetry_flag}"
msg "- name: ${name}"
# msg "- arguments: ${args[*]-}"

init() {
  msg "Setting up repo ${base_dir}/${name}"
  mkdir -p ${base_dir}/${name}
  cd ${base_dir}/${name}
  touch README.md
  mkdir -p test
  [[ ${venv_flag} == 1 ]] && venv_init
  [[ ${git_flag} == 1 ]] && git_init
  [[ ${poetry_flag} == 1 ]] && poetry_init
  cd ${base_dir}
}

venv_init(){
  [[-z $(virtualenv -v)]] && die "python virtualenv not installed"
  msg "${RED}Setting up new virtual env${NOFORMAT}"
  venv_name=${base_dir}/venv_${name}
  virtualenv --python=python3.6 ${venv_name}
  source ${venv_name}/bin/activate
  msg "${RED}Installing basic dependencies in new environment${NOFORMAT}"
  pip install --upgrade pip poetry wheel pytest
  deactivate
}

git_init(){
  # Initialize git repo
  git init
}

poetry_init(){
  # Initialize poetry pyproject file
  # TODO activate python virtualenv
  # 
  source ${venv_name}/bin/activate
  poetry init
}

init

