#!/bin/bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
readonly global_justfile="${repository_root}/global/justfile"
just_binary="$(command -v just || true)"
readonly just_binary

temporary_directory=""

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

pass() {
    echo "PASS: $1"
}

cleanup() {
    if [[ -n "${temporary_directory}" ]]; then
        rm -rf "${temporary_directory}"
    fi
}

assert_equal() {
    local expected="$1"
    local actual="$2"
    local description="$3"

    if [[ "${actual}" != "${expected}" ]]; then
        echo "Expected: ${expected}" >&2
        echo "Actual:   ${actual}" >&2
        fail "${description}"
    fi
}

assert_log_line() {
    local expected_line="$1"

    if ! grep -Fqx -- "${expected_line}" "${COMMAND_LOG}"; then
        echo "Expected command: ${expected_line}" >&2
        echo "Recorded commands:" >&2
        sed 's/^/  /' "${COMMAND_LOG}" >&2
        fail "mock command was not recorded"
    fi
}

require_just() {
    if [[ -z "${just_binary}" ]]; then
        fail "Required tool not found: just"
    fi
}

test_expected_files() {
    [[ -f "${global_justfile}" ]] || fail "Expected justfile not found: ${global_justfile}"

    pass "expected justfiles exist"
}

test_parsing_and_formatting() {
    "${just_binary}" --justfile "${global_justfile}" --list >/dev/null

    pass "global justfile parses"
}

test_recipe_interfaces() {
    assert_equal \
        "activate-pyvenv add-agents add-notes add-readme backup build-py bump-zsh cgds-repos clean-temp doctor fetch find-dupes hooks-all hooks-install hooks-run hooks-update hooks-update-check lint-md mk-cgds-repo new-shell notekeeper organize pah-repos personal-repos publish-pypi publish-test-pypi pyvenv run-streamlit serve-jekyll update-brew update-conda-all update-mamba website-repos" \
        "$("${just_binary}" --justfile "${global_justfile}" --summary)" \
        "global recipe interface changed"

    pass "recipe interfaces match the expected commands"
}

create_mock_tools() {
    local mock_binary_directory="${temporary_directory}/mock-bin"

    mkdir -p "${mock_binary_directory}"
    export COMMAND_LOG="${temporary_directory}/commands.log"
    : >"${COMMAND_LOG}"

    cat >"${mock_binary_directory}/mock-tool" <<'EOF'
#!/bin/bash
set -euo pipefail

printf '%s' "$(basename "$0")" >>"${COMMAND_LOG}"
for argument in "$@"; do
    printf '\t%s' "${argument}" >>"${COMMAND_LOG}"
done
printf '\n' >>"${COMMAND_LOG}"
EOF
    chmod +x "${mock_binary_directory}/mock-tool"

    ln -s "mock-tool" "${mock_binary_directory}/prek"

    export PATH="${mock_binary_directory}:${PATH}"
}

test_git_hook_commands() {
    : >"${COMMAND_LOG}"
    "${just_binary}" --quiet --justfile "${global_justfile}" hooks-install
    "${just_binary}" --quiet --justfile "${global_justfile}" hooks-run
    "${just_binary}" --quiet --yes --justfile "${global_justfile}" hooks-all
    "${just_binary}" --quiet --justfile "${global_justfile}" hooks-update-check
    "${just_binary}" --quiet --yes --justfile "${global_justfile}" hooks-update

    assert_log_line $'prek\tinstall'
    assert_log_line $'prek\trun'
    assert_log_line $'prek\trun\t--all-files'
    assert_log_line $'prek\tupdate\t--check'
    assert_log_line $'prek\tupdate'

    pass "global Git hook recipes invoke prek with the expected scope"
}

main() {
    trap cleanup EXIT
    require_just

    temporary_directory="$(mktemp -d)"
    test_expected_files
    test_parsing_and_formatting
    test_recipe_interfaces
    create_mock_tools
    test_git_hook_commands

    echo "All justfile tests passed."
}

main "$@"
