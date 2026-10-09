---
name: my-infra-ci-preferences
description: Don's preferences for Dockerfiles, GitLab CI, Helm/Kubernetes deploy YAML, Terraform/CloudFormation, IAM, and per-environment config. Use when writing or reviewing any of these, or when adding env vars, queues, secrets, regions, scheduled jobs, or deployments.
---

# Infra and CI preferences

## Per-environment config
- When editing one environment's or region's config, open every sibling environment and region. Check every field that embeds an env-specific name: secret paths and auth methods, cluster, ARNs, policy names. When cloning a region, diff against the source and justify every deviation.
- Never commit local-only edits such as compose `external: true`, `protected: false`, or a disabled test. Grep the diff for them.
- New feature flags and settings are set explicitly in the shared deploy env (e.g. `false`), not left implicit.
- Anything declared in shared or default deploy config (cronjobs, plugins, sidecars) deploys to every environment, prod included. Default it off and enable it per environment.
- Before building a scheduled job, check whether an existing pipeline schedule or another team's job already does it.

## Docker
- COPY an explicit allowlist of what the image needs. Don't rely on a `.dockerignore` denylist.
- Keep stages minimal. After a redesign, collapse stages that no longer earn their place. Don't re-set ENV that the base image already sets.
- When a target's CMD, USER, or contents change, grep docker-compose, CI jobs (including jobs that use the app image as their job image), and deploy YAML for every consumer.
- Something in CI must build and exercise the production target.

## GitLab CI
- Use CI-provided variables for registries and images instead of hardcoded hosts.
- A job that `needs` another must mirror that job's `rules`. A `needs` on a job that is excluded on main breaks main pipeline creation.
- Release verification tests the released tag, not the latest main.
- Jobs that push test images also clean them up. Build caches are per branch, with main as the fallback.
- Prefer one final default rule over repeating `when: never` in every rule.

## Kubernetes resources
- Set CPU limits well above average usage, because CFS throttling is invisible otherwise. Every resource limit cites its source (load test, measurement). When you bound memory, bound disk too.

## IAM and security
- Least privilege: separate read and write policies, and no wildcards that let a read role map to a write user.
- Producer and consumer permissions follow the actual data flow. Write out the producer/consumer table for each topic or queue before granting.
- Upload endpoints declare a size limit.

## Rationale
- Every interval, timeout, limit, pinned version, or workaround gets a one-line reason and its source.
