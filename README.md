# vspo-lab/config

Shared Renovate presets for the vspo-lab organization.

This repository ships no runtime artifact. It contains preset JSON and the
workflow that validates it, so a change here can never alter product behavior in
a consumer; it can only change which dependency PRs get raised, and how.

## Consuming

Extend the entrypoint preset from a repository's `renovate.json`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["local>vspo-lab/config//renovate/default"]
}
```

Name the file explicitly, as above. `local>vspo-lab/config//renovate` looks like
it points at the directory, but Renovate reads the trailing segment as a *file*
name, so it fetches `renovate.json` from the repository root instead of
`renovate/default.json` — this repository's own Renovate config, not the shared
presets. The mistake is silent: a valid file loads, so nothing errors.

Unpinned means the consumer always tracks `main`, so a change here takes effect
on the next Renovate run without a follow-up PR in the consumer. To pin instead,
append a tag: `local>vspo-lab/config//renovate/default#v1.0.0`.

Repository-local rules go in the consumer's own `renovate.json` after the
`extends`, where they take precedence. Keep organization-wide policy here and
repository-specific policy there, so there is one source of truth for each.

## Presets

`renovate/default.json` is the entrypoint and composes the rest.

| Preset | Purpose |
|--------|---------|
| `schedule` | Weekday daytime schedule, Asia/Tokyo |
| `minimumReleaseAge` | 7-day supply-chain cooldown for npm packages |
| `vulnerabilityAlerts` | Security alerts enabled, labelled `security`, exempt from the cooldown |
| `groupLinters` | Collects linter and formatter updates into one PR |
| `automergeTypesMinor` | `@types/*` below major |
| `automergePin` | Pin updates |
| `pinGitHubActionDigests` | Pin third-party actions to a digest; `actions/*` is trusted by tag |
| `aqua` | Schedules `aqua-registry` updates for early Monday |

A consumer that disables automerge in its own config overrides the automerge
presets above, since local rules win.

## Validation

CI runs on every pull request:

```bash
./scripts/check-preset-references.sh   # every extended preset has a file
npx --package renovate -c renovate-config-validator
```

The reference check exists because `renovate-config-validator` does not resolve
remote presets: `default.json` previously extended `:groupLinters` and
`:vulnerabilityAlerts` with no corresponding file, and validation still passed.

Run both locally before opening a pull request.

## Changing a preset

Because consumers track `main` unpinned, a merge here is a live change across the
organization. Before merging, check what the change does to each consumer's next
run, and prefer adding a new preset over altering the meaning of an existing one.
