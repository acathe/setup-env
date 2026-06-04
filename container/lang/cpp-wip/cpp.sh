#!/usr/bin/env bash

set -e

if [[ -n "${_SETUP_ENV_DEBIAN_LANG_CPP_SH}" ]]; then
    return 0
else
    _SETUP_ENV_DEBIAN_LANG_CPP_SH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    readonly _SETUP_ENV_DEBIAN_LANG_CPP_SH
fi

# shellcheck source=../util/apt.sh
source "${_SETUP_ENV_DEBIAN_LANG_CPP_SH}/../util/apt.sh"

cpp::install() {
    apt::update
    apt::install "curl" "lsb-release" "wget" "software-properties-common" "gnupg"

    local _llvm_script
    _llvm_script="$(curl --proto "=https" --tlsv1.2 -sSfL https://apt.llvm.org/llvm.sh)"
    sudo bash -c "${_llvm_script}" -- all

    # local _llvm_version
    # _llvm_version="$(echo "${_llvm_script}" | grep -oP "(?<=^CURRENT_LLVM_STABLE=)[0-9]+")"
    # sudo update-alternatives --install "/usr/bin/clangd" clangd "/usr/bin/clangd-${_llvm_version}" 100

    apt::install "cmake" "cmake-format"
}

cpp::set_env() {
    if [ ! -f "./CMakeLists.txt" ]; then
        echo "No CMakeLists.txt found."
        return 0
    fi

    # Ref. https://clangd.llvm.org/installation
    tee -a "./CMakeLists.txt" <<EOF >"/dev/null"
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_FLAGS "-stdlib=libc++")
EOF
}

main() {
    cpp::install
    cpp::set_env
}

if [[ "${0}" == "${BASH_SOURCE[0]}" ]]; then
    main "$@"
fi
