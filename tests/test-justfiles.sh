#!/bin/bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repository_root
readonly global_justfile="${repository_root}/global/justfile"
readonly r_justfile="${repository_root}/project-specific/r/package/justfile"
readonly python_justfile="${repository_root}/project-specific/python/package/justfile"
readonly nextflow_justfile="${repository_root}/project-specific/nextflow/nf-core/justfile"
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

require_tools() {
    if [[ -z "${just_binary}" ]]; then
        fail "Required tool not found: just"
    fi

    # Global recipes use zsh even though this test harness runs under Bash.
    if ! command -v zsh >/dev/null 2>&1; then
        fail "Required tool not found: zsh (needed by global/justfile)"
    fi
}

test_expected_files() {
    local justfile

    for justfile in \
        "${global_justfile}" \
        "${r_justfile}" \
        "${python_justfile}" \
        "${nextflow_justfile}"; do
        [[ -f "${justfile}" ]] || fail "Expected justfile not found: ${justfile}"
    done

    pass "expected justfiles exist"
}

test_parsing_and_formatting() {
    local justfile

    for justfile in \
        "${global_justfile}" \
        "${r_justfile}" \
        "${python_justfile}" \
        "${nextflow_justfile}"; do
        "${just_binary}" --justfile "${justfile}" --list >/dev/null
    done

    # The global file intentionally preserves the formatting of ~/.justfile.
    for justfile in "${r_justfile}" "${python_justfile}" "${nextflow_justfile}"; do
        "${just_binary}" --justfile "${justfile}" --fmt --check
    done

    pass "justfiles parse and project templates are formatted"
}

test_recipe_interfaces() {
    assert_equal \
        "activate-pyvenv add-agents add-notes add-readme backup build-py bump-zsh cgds-repos clean-temp doctor fetch find-dupes hooks-all hooks-install hooks-run hooks-update hooks-update-check lint-md mk-cgds-repo new-shell notekeeper organize pah-repos personal-repos publish-pypi publish-test-pypi pyvenv run-streamlit serve-jekyll update-brew update-conda-all update-mamba website-repos" \
        "$("${just_binary}" --justfile "${global_justfile}" --summary)" \
        "global recipe interface changed"

    assert_equal \
        "actions-dispatch actions-list actions-pr actions-pr-amd64 actions-push build-site check ci-local lintr mk-docs test" \
        "$("${just_binary}" --justfile "${r_justfile}" --summary)" \
        "R package recipe interface changed"

    assert_equal \
        "actions-dispatch actions-lint actions-list actions-pr actions-pr-amd64 actions-push build-pkg ci-local format-check lint sync test typecheck" \
        "$("${just_binary}" --justfile "${python_justfile}" --summary)" \
        "Python package recipe interface changed"

    assert_equal \
        "actions-dispatch actions-lint actions-list actions-pr actions-pr-amd64 actions-push ci-local clean-preview clean-run config lint test test-resume" \
        "$("${just_binary}" --justfile "${nextflow_justfile}" --summary)" \
        "nf-core recipe interface changed"

    pass "recipe interfaces match the expected commands"
}

create_mock_tools() {
    local mock_binary_directory="${temporary_directory}/mock-bin"
    local tool

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

    for tool in Rscript actionlint act nf-core nextflow prek uv; do
        ln -s "mock-tool" "${mock_binary_directory}/${tool}"
    done

    export PATH="${mock_binary_directory}:${PATH}"
}

test_local_ci_commands() {
    : >"${COMMAND_LOG}"
    "${just_binary}" --quiet --justfile "${r_justfile}" ci-local
    assert_log_line $'actionlint'
    assert_log_line $'Rscript\t-e\tlintr::lint_package()'
    assert_log_line $'Rscript\t-e\tdevtools::test()'
    assert_log_line \
        $'Rscript\t-e\trcmdcheck::rcmdcheck(args = "--no-manual", error_on = "warning")'

    : >"${COMMAND_LOG}"
    "${just_binary}" --quiet --justfile "${python_justfile}" ci-local
    assert_log_line $'uv\trun\truff\tcheck\t.'
    assert_log_line $'uv\trun\truff\tformat\t--check\t.'
    assert_log_line $'uv\trun\tmypy\tsrc'
    assert_log_line $'uv\trun\tpytest'
    assert_log_line $'uv\tbuild'

    : >"${COMMAND_LOG}"
    "${just_binary}" --quiet --justfile "${nextflow_justfile}" ci-local
    assert_log_line $'nf-core\tpipelines\tlint'
    assert_log_line $'nextflow\tconfig\t.'
    assert_log_line $'nextflow\trun\tmain.nf\t-profile\ttest,docker'

    pass "local CI recipes invoke the expected tools"
}

test_specialized_commands() {
    local justfile

    : >"${COMMAND_LOG}"
    for justfile in "${r_justfile}" "${python_justfile}" "${nextflow_justfile}"; do
        "${just_binary}" --quiet --justfile "${justfile}" actions-pr-amd64
    done

    assert_equal \
        "3" \
        "$(grep -Fxc $'act\tpull_request\t--container-architecture\tlinux/amd64' "${COMMAND_LOG}")" \
        "Apple Silicon action command changed"

    : >"${COMMAND_LOG}"
    "${just_binary}" --quiet --yes --justfile "${nextflow_justfile}" clean-run test-run
    assert_log_line $'nextflow\tclean\ttest-run\t-f'

    pass "specialized action and cleanup commands remain explicit"
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

test_missing_tool_error() {
    local isolated_binary_directory="${temporary_directory}/isolated-bin"
    local output_file="${temporary_directory}/missing-tool.log"

    mkdir -p "${isolated_binary_directory}"
    ln -s "$(command -v bash)" "${isolated_binary_directory}/bash"

    if PATH="${isolated_binary_directory}" \
        "${just_binary}" --justfile "${r_justfile}" lintr \
        >"${output_file}" 2>&1; then
        fail "R lintr recipe succeeded without Rscript"
    fi

    if ! grep -Fq "Required tool not found: Rscript" "${output_file}"; then
        cat "${output_file}" >&2
        fail "missing-tool error was not clear"
    fi

    pass "missing tools produce a clear error"
}

main() {
    trap cleanup EXIT
    require_tools

    temporary_directory="$(mktemp -d)"
    test_expected_files
    test_parsing_and_formatting
    test_recipe_interfaces
    create_mock_tools
    test_local_ci_commands
    test_specialized_commands
    test_git_hook_commands
    test_missing_tool_error

    echo "All justfile tests passed."
}

main "$@"
