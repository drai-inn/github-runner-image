#!/usr/bin/env bash
# Registers one ephemeral runner with the organisation, runs one job, then
# deletes this pod so its Deployment starts a fresh one. Kubernetes restarts an
# exited container in place, on a back-off that grows to five minutes; a new
# pod starts at once and with clean volumes.
set -euo pipefail

: "${GITHUB_ORG:?}" "${RUNNER_GROUP:?}" "${RUNNER_LABELS:?}"

# GITHUB_PAT can register runners for the whole organisation. A process's
# starting environment stays readable in /proc/<pid>/environ to its user, which
# is also the jobs' user, so unsetting it is not enough: mint the registration
# token, then replace this process with one started without the PAT.
token_file=/tmp/registration-token
if [[ -n "${GITHUB_PAT:-}" ]]; then
  (umask 077; curl -fsS -X POST \
    -H "Authorization: Bearer ${GITHUB_PAT}" -H "Accept: application/vnd.github+json" \
    "https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token" \
    | jq -r .token > "$token_file")
  exec env -u GITHUB_PAT "$0"
fi
token=$(<"$token_file")
rm "$token_file"

cd /home/runner
./config.sh --unattended --ephemeral --disableupdate \
  --url "https://github.com/${GITHUB_ORG}" --token "$token" \
  --name "${RUNNER_NAME_PREFIX:-k8s}-$(hostname)" \
  --runnergroup "$RUNNER_GROUP" --labels "$RUNNER_LABELS" --work _work

status=0
./run.sh || status=$?

sa=/var/run/secrets/kubernetes.io/serviceaccount
curl -fsS -o /dev/null -X DELETE --cacert "$sa/ca.crt" \
  -H "Authorization: Bearer $(cat "$sa/token")" \
  "https://kubernetes.default.svc/api/v1/namespaces/$(cat "$sa/namespace")/pods/$(hostname)"
exit "$status"
