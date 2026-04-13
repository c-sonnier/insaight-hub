# Design: `ih` CLI as an MCP Replacement
Date: 2026-04-13

Related: `docs/convergence/research/2026-04-13-insaight-hub-cli.md`

## Current State

- `POST /mcp` (global, no account prefix) exposes 10 MCP tools via JSON-RPC. Auth: OAuth 2.1 or Bearer token (`User.api_token` or `Identity.api_token`).
- `/<account_uuid>/api/v1/...` REST API covers most tool functionality but has gaps: **no `list_organizations` endpoint**. Comments endpoints exist only at the web layer (out of v1 scope).
- MCP tools resolve org by **name or UUID** via `OrganizationResolvable` (`app/tools/concerns/organization_resolvable.rb`). REST requires the account UUID in the URL path.
- No existing CLI in the repo. No Thor/Go/other CLI scaffolding.
- Go is not present in the codebase — this introduces a new language and toolchain.

## Desired End State

A Go-based CLI named `ih` that a user or LLM runs locally against any reachable insaight-hub deployment. Functional parity with the 10 registered MCP tools, so an LLM can use `ih <command>` instead of an MCP connection.

- Install: `cd cli && go build -o ih && mv ih ~/bin/` (no published channel for v1).
- First use: `ih login` captures hub URL, token, optional default org, writes `~/.config/ih/config.toml`.
- Runtime: `ih insights list`, `ih insights create --title X --audience developer --file index.html=./report.html`, etc.
- Output: JSON when stdout is not a TTY (piped / captured by LLM); human-friendly tables when at a TTY.
- Multi-account: config default org + `--org <name-or-uuid>` flag override; sole-org identities get implicit fallback.

## Patterns to Follow

- **Bearer token auth** (`Authorization: Bearer <token>`) — matches existing MCP + REST. CONFIRMED.
- **Organization resolution by name or UUID** (`OrganizationResolvable`) — CLI accepts either for `--org`. CONFIRMED.
- **Slug as insight identifier** (`InsightItem#to_param => slug`). CONFIRMED.
- **LLM-optimized markdown output** (`GetInsightTool` default = markdown; REST `content_format=markdown`) — CLI defaults `ih insights get` to markdown. CONFIRMED.
- **Sole-account implicit fallback** (from `OrganizationResolvable`) — preserved in CLI when no `--org` supplied and config default unset. CONFIRMED.
- ~~**MCP JSON-RPC transport**~~ — REJECTED: response payloads are `{type: "text", text: "<stringified-json>"}` which adds unwrapping noise in the CLI client.
- ~~**CLI calls ActiveRecord directly (Rake-style)**~~ — REJECTED: CLI must run on arbitrary machines, not only the server host.

## Approach

Build a thin HTTP client in Go that talks to the existing REST API, adding one new endpoint (`GET /api/v1/organizations`) to close the only gap for v1 scope.

### Architecture

```
cli/                          (new, in this repo)
├── go.mod
├── main.go                   (wire cobra root)
├── cmd/
│   ├── root.go
│   ├── login.go
│   ├── logout.go
│   ├── organizations.go      (list)
│   ├── tags.go               (list)
│   └── insights.go           (list/get/create/update/delete/publish/unpublish/move)
├── internal/
│   ├── client/               (HTTP client, auth, request/response types)
│   ├── config/               (TOML config load/save, env override)
│   └── output/               (TTY detect, JSON vs table rendering)
```

- **CLI framework**: `github.com/spf13/cobra` + `github.com/spf13/viper` for config/env precedence. De facto Go standard.
- **Config file**: `~/.config/ih/config.toml` (XDG-compliant). Fields: `url`, `token`, `default_org`. Single profile in v1 (multi-profile deferred).
- **Env overrides**: `INSAIGHT_URL`, `INSAIGHT_TOKEN`, `INSAIGHT_ORG` beat the config file.
- **Output**: `isatty(stdout)` gates JSON vs table. `--json` forces JSON. `--pretty` / `--table` forces tables.
- **Backend change (Rails)**: add `GET /api/v1/organizations` returning `[{id, name, role}]` for the authenticated identity — scoped by identity, not account (sits under `/api/v1` without account prefix or at a new global path TBD at outline time).

### Command surface (v1)

| Command | Backend call |
|---|---|
| `ih login` | writes config; optional `GET /api/v1/me` to verify |
| `ih logout` | clears token in config |
| `ih organizations list` | `GET /api/v1/organizations` (new) |
| `ih tags list [--org]` | `GET /<uuid>/api/v1/tags` |
| `ih insights list [--org] [--status] [--audience] [--tag] [--search] [--page] [--per-page]` | `GET /<uuid>/api/v1/insight_items` |
| `ih insights get <slug> [--org] [--format markdown\|html]` | `GET /<uuid>/api/v1/insight_items/:id?content_format=...` |
| `ih insights create --title --audience [--org] [--description] [--tag] [--entry-file] [--file name=path]... [--content <file\|->] [--publish]` | `POST /<uuid>/api/v1/insight_items` |
| `ih insights update <slug> [flags]` | `PATCH /<uuid>/api/v1/insight_items/:id` |
| `ih insights delete <slug> [--org]` | `DELETE /<uuid>/api/v1/insight_items/:id` |
| `ih insights publish <slug> [--org]` | `POST /<uuid>/api/v1/insight_items/:id/publish` |
| `ih insights unpublish <slug> [--org]` | `POST /<uuid>/api/v1/insight_items/:id/unpublish` |
| `ih insights move <slug> --from <org> --to <org>` | `POST /<from-uuid>/api/v1/insight_items/:id/move` with `target_account_id` |

Org resolution order per command: `--org` flag → `INSAIGHT_ORG` → `config.default_org` → sole-account fallback (one org on identity) → error directing the user to `ih organizations list`.

### Alternatives Considered

- **JSON-RPC client over `POST /mcp`** — zero backend changes, 100% tool parity. Rejected because every response is a JSON string wrapped in MCP's `{type,text}` envelope — extra unwrap layer and uglier error surfaces.
- **Hybrid (REST + MCP fallback for gaps)** — avoids new REST endpoint. Rejected because two client code paths for one feature is more complex than one new Rails endpoint.
- **Ruby Thor CLI in `bin/`** — matches project language. Rejected (user preference) in favor of a Go static binary.
- **Compiled Ruby via `ruby-packer`** — ship Ruby code as a binary. Rejected — adds more moving parts than writing native Go.
- **Separate repo for the CLI** — cleaner boundary. Rejected (user preference) in favor of a `cli/` subdirectory for lockstep evolution with the API.
- **Published distribution channel in v1 (Homebrew / GitHub Releases)** — Rejected (user preference) — `go build` from source only for v1; revisit once usage is real.
- **Multi-profile config** (multiple hubs per machine) — deferred; single profile for v1.
- **Comments and unregistered MCP tools** — out of v1 scope (`AddCommentTool`, `ListCommentsTool` are not registered on the MCP server either).

## Resolved Decisions

1. **Protocol**: REST API + one new endpoint (`GET /api/v1/organizations`) — structured JSON responses and existing pagy pagination beat MCP's double-wrapped responses.
2. **Language**: Go, compiled static binary — user preference; clean install story, no runtime deps.
3. **Repo location**: `cli/` subdirectory in `insaight_hub` — single repo keeps server + client changes synchronized.
4. **Scope v1**: 10 registered MCP tools (parity). Comments and move-only-via-API stay out of scope.
5. **Config**: config file + env var override — config file is canonical, env vars beat it; matches `gh`, `aws`.
6. **Binary name / command shape**: `ih`, noun-first (`ih insights list`) — user preference; scales cleanly in cobra.
7. **Output**: TTY auto-detect (JSON when piped, tables when at a terminal) — matches `gh`, `docker`.
8. **Org scoping**: config default + `--org` override, sole-account implicit fallback — mirrors `OrganizationResolvable` behavior.
9. **Distribution**: deferred — `go build ./...` from source only for v1.
10. **CLI framework**: cobra + viper — standard for Go CLIs with config precedence.
11. **Config format**: TOML — conventional for Go/Rust CLIs; simpler to edit than YAML.
12. **Config path**: `~/.config/ih/config.toml` (XDG `$XDG_CONFIG_HOME` respected).

## Open Questions

- Should `GET /api/v1/organizations` live under the existing `Api::V1` namespace (unusual — the namespace is account-scoped by middleware) or at a new **global** path like `GET /api/v1/organizations` outside `AccountSlug::Extractor`'s scope? Same URL, different middleware behavior. Resolve at outline time.
- `ih insights create` file input UX: `--file name=path` (repeatable) vs `--files path1,path2` (filename inferred) vs both. Pick at outline time.
- Error formatting: follow REST's `{error, messages}` shape verbatim, or reshape into a CLI-idiomatic form. Pick at outline time.
- Go module path (e.g., `github.com/c-sonnier/insaight_hub/cli`). Confirm at outline time.
