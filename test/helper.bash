# shellcheck shell=sh

if [ -z "${BATS_HELPERS}" ] ; then
  echo 'define BATS_HELPERS to point at parent dir of bats-* clones' >& 2
fi

_setup() {
  load "${BATS_HELPERS}/bats-support/load"
  load "${BATS_HELPERS}/bats-assert/load"
  DIR=$( cd "$( dirname "${BATS_TEST_FILENAME}" )" >/dev/null 2>&1 && pwd )
  PATH="${DIR}/..:${PATH}"
  TEST_LOG_ROOT="$(dirname "${BATS_TEST_FILENAME}" )/.tmp"
}

_teardown() {
  rm  -Rf "${TEST_LOG_ROOT}"
}
