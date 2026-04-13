# Outline: `ih` CLI as an MCP Replacement
Date: 2026-04-13
Design: docs/convergence/design/2026-04-13-insaight-hub-cli-design.md

## Phase 1: End-to-end auth slice — `ih login` + `ih organizations list`
Proves Go module, cobra, TOML config with env overrides, Bearer-auth HTTP client, and the new Rails endpoint line up.

**Files:**
- `cli/go.mod`, `cli/main.go`, `cli/cmd/root.go` (global flags: `--json`, `--pretty`, `--org`, `--url`)
- `cli/cmd/login.go`, `cli/cmd/logout.go`, `cli/cmd/organizations.go`
- `cli/internal/config/config.go` (+ `_test.go`) — load/save `~/.config/ih/config.toml`, env precedence
- `cli/internal/client/client.go` — HTTP client, Bearer auth, error unwrap
- `cli/internal/output/output.go` — JSON render (tables stubbed)
- `config/routes.rb` — add `get "/api/v1/organizations"` + path to `AccountSlug::Extractor::GLOBAL_ROUTES`
- `app/controllers/api/v1/organizations_controller.rb` — skips `require_account_membership`, returns identity's memberships
- `test/controllers/api/v1/organizations_controller_test.rb`

**Signatures:** `Client{URL, Token}.Get(path) ([]byte, error)`; `Organization{ID, Name, Role}`; `ListOrganizations() ([]Organization, error)`; `Api::V1::OrganizationsController#index`.

**Verify:**
- `cd cli && go build ./... && go test ./...` green
- `./ih login` then `./ih organizations list --json | jq .` prints identity's orgs
- `bin/rails test test/controllers/api/v1/organizations_controller_test.rb` green

## Phase 2: Insight read — `ih insights list` + `ih insights get`
Hits existing REST; establishes org resolution.

**Files:**
- `cli/cmd/insights.go` (list, get)
- `cli/internal/client/insights.go` — read types
- `cli/internal/org/org.go` (+ `_test.go`) — flag → `INSAIGHT_ORG` → config default → sole-account → error

**Signatures:** `Insight{...}`; `ListInsights(org, opts) ([]Insight, Pagination, error)`; `GetInsight(org, slug, format) (InsightDetail, error)` (default `format=markdown`).

**Verify:**
- `./ih insights list --status published --json | jq '.insight_items|length'` ≥ 0
- `./ih insights get <slug>` prints markdown
- `go test ./cli/internal/org/...` green

## Phase 3: Insight write — `ih insights create|update|delete`
Adds file-input UX and write payloads.

**Files:**
- `cli/cmd/insights.go` (create, update, delete)
- `cli/internal/client/insights.go` — POST/PATCH/DELETE
- `cli/internal/fileinput/fileinput.go` (+ `_test.go`) — parse `--file name=path` repeatable, `--content <path|->`, content_type by extension

**Signatures:** `CreateReq{Title, Audience, Description, Tags, EntryFile, Files, Publish}`; `CreateInsight`, `UpdateInsight`, `DeleteInsight`.

**Verify:**
- `echo '<h1>hi</h1>' | ./ih insights create --title "cli test" --audience developer --content -` prints slug
- `./ih insights update <slug> --description x` → updated
- `./ih insights delete <slug>` then `./ih insights get <slug>` exits non-zero

## Phase 4: Lifecycle + tags — `publish|unpublish|move`, `tags list`
Closes MCP parity.

**Files:**
- `cli/cmd/insights.go` (publish, unpublish, move), `cli/cmd/tags.go`
- `cli/internal/client/insights.go`, `cli/internal/client/tags.go`

**Signatures:** `PublishInsight`, `UnpublishInsight`, `MoveInsight(slug, fromOrg, toOrg)`, `ListTags(org) ([]string, error)`.

**Verify:**
- `./ih insights publish <slug>` → status `published`
- `./ih insights move <slug> --from A --to B` → `organization: B`
- `./ih tags list --json` → JSON array of strings

## Phase 5: Output polish — TTY-aware tables
Applies output rules uniformly; no new endpoints.

**Files:**
- `cli/internal/output/output.go` — isatty + renderer dispatch
- `cli/internal/output/tables.go` — per-resource formatters
- Each `cli/cmd/*.go` — route through `output.Render(v)`

**Verify:**
- `./ih insights list` at TTY → table (slug, title, audience, status)
- `./ih insights list | cat` → JSON array
- `./ih insights list --json` at TTY → JSON (override honored)
