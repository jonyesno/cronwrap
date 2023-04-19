#!/usr/bin/env bats

# shellcheck shell=sh

setup() {
  DIR=$( cd "$( dirname "${BATS_TEST_FILENAME}" )" >/dev/null 2>&1 && pwd )
  load "${DIR}/helper"
  _setup
  PROG=cronwrap.lockf
}

teardown() {
  _teardown
}

@test "usage" {
  run cronwrap
  assert_failure
  assert_output --partial 'usage:'
}

@test "creates the per-cron directory and status directory inside it" {
  run env \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    "${PROG}" "test-job-${BATS_TEST_NUMBER}" 60 uptime

  assert_success
  assert [ -d "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}" ]
  assert [ -d "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status" ]
}

@test "runs a job, logs its output to a logfile and symlinks it as last_run" {
  run env \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    "${PROG}" "test-job-${BATS_TEST_NUMBER}" 60 echo mrs jaypher said it is safer

  assert_success
  assert grep -q jaypher "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/last_run"
  assert grep -q jaypher "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}"/20[0-9][0-9][0-1][0-9][0-3][0-9]-[0-2][0-9][0-5][0-9][0-5][0-9].log # YYYYMMDD-HHMMSS kinda

}

@test "runs a successful job and marks as OK, removing any previous FAIL mark, symlinks its log as last_job_ok" {
  run env \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    "${PROG}" "test-job-${BATS_TEST_NUMBER}" 60 false

  run env \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    "${PROG}" "test-job-${BATS_TEST_NUMBER}" 60 true

  assert_success
  assert [   -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/OK" ]
  assert [ ! -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/FAIL" ]
  assert [ ! -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/LOCK" ]

  assert grep -q "success: job exited ok" "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/last_run"
  assert grep -q "success: job exited ok" "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/last_job_ok"
}

@test "runs a failing job and marks as FAIL, removing any previous OK mark, symlinks its log as last_job_fail" {
  run env \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    "${PROG}" "test-job-${BATS_TEST_NUMBER}" 60 true

  run env \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    "${PROG}" "test-job-${BATS_TEST_NUMBER}" 60 false

  assert_failure 2
  assert [ ! -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/OK" ]
  assert [   -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/FAIL" ]
  assert [ ! -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/LOCK" ]

  assert grep -q "failed: command exited non-zero" "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/last_run"
  assert grep -q "failed: command exited non-zero" "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/last_job_fail"
}

@test "records the interval time in the status directory" {
  run env \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    "${PROG}" "test-job-${BATS_TEST_NUMBER}" 60 true

  assert grep -q 60 "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/interval"
}

