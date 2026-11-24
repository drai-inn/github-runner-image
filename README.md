# github-runner-image

The image for drai-inn's ephemeral self-hosted GitHub Actions runners on
Kubernetes. Each pod registers one runner with `--ephemeral`, runs one job and
deletes itself, so every job starts in a fresh pod.

Built on [`ghcr.io/actions/actions-runner`](https://github.com/actions/runner/pkgs/container/actions-runner)
(non-root user `runner`, uid 1001, with git, jq and curl), plus gh, uv and
Node. Published as `ghcr.io/drai-inn/github-runner-image:sha-<commit>`.

## Environment

| Variable | Meaning |
|---|---|
| `GITHUB_ORG` | organisation to register with |
| `GITHUB_PAT` | token with the organisation permission "Self-hosted runners: write"; unset before the job runs |
| `RUNNER_GROUP` | runner group to join |
| `RUNNER_LABELS` | comma-separated labels |
| `RUNNER_NAME_PREFIX` | runner name prefix (default `k8s`); the pod name follows it |

## What the pod needs

- A service account allowed to `delete` pods in its own namespace, and its
  token mounted: the start script deletes its own pod when the runner exits.
- `runAsUser: 1001`. The image runs as non-root and needs no privilege
  escalation or capabilities; `sudo` in the base image does not work under
  `allowPrivilegeEscalation: false`, so jobs cannot install system packages.

## Updating

The runner is registered with `--disableupdate`, and GitHub stops serving
runners that fall too far behind, so the base image must be kept current.
Dependabot proposes new base image and action versions; `GH_VERSION` and
`NODE_VERSION` in the `Dockerfile` are bumped by hand.

A runner pod deleted before it took a job leaves an offline registration,
which GitHub removes after a day.
