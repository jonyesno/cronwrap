#!/usr/bin/env bats

# shellcheck shell=sh

setup() {
  DIR=$( cd "$( dirname "${BATS_TEST_FILENAME}" )" >/dev/null 2>&1 && pwd )
  load "${DIR}/helper"
  _setup
}

teardown() {
  _teardown
}

@test "locks a overlapping job and marks it locked" {
  run env \
    CRONWRAP_LOCKRUN="$(which lockrun)" \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    cronwrap "test-job-${BATS_TEST_NUMBER}" 60 sleep 2 &

  sleep 1

  run env \
    CRONWRAP_LOCKRUN="$(which lockrun)" \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    cronwrap "test-job-${BATS_TEST_NUMBER}" 60 sleep 2

  assert_failure 1

  assert [ ! -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/OK"   ]
  assert [ ! -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/FAIL" ]
  assert [   -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/LOCK" ]

  assert grep -q "failed: lockrun indicated earlier process running" "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/last_run"
  assert grep -q "failed: lockrun indicated earlier process running" "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/last_lock_fail"
}

@test "doesn't lock non-overlapping job" {
  run env \
    CRONWRAP_LOCKRUN="$(which lockrun)" \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    cronwrap "test-job-${BATS_TEST_NUMBER}" 60 sleep 2 &

    sleep 3

  run env \
    CRONWRAP_LOCKRUN="$(which lockrun)" \
    CRONWRAP_LOG_DIR="${TEST_LOG_ROOT}" \
    cronwrap "test-job-${BATS_TEST_NUMBER}" 60 sleep 2

  assert_success

  assert [   -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/OK"   ]
  assert [ ! -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/FAIL" ]
  assert [ ! -f "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/status/LOCK" ]

  assert grep -q "success: job exited ok" "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/last_run"
  assert grep -q "success: job exited ok" "${TEST_LOG_ROOT}/test-job-${BATS_TEST_NUMBER}/last_job_ok"
}

