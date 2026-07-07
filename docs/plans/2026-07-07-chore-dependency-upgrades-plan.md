# Dependency Upgrades Plan

Follow-up to the 2026-07-07 security audit. Already done: puma 7.2.1, addressable 2.9.0,
json 2.20.0, msgpack 1.8.3, bcrypt 3.1.22, brakeman 8.0.5 (commit 3789f38).

Remaining flagged items, ordered by risk. Each phase = one commit, full test run, deploy-ready.

## Phase 1 — MCP gem 0.4.0 → 0.23.0

**Risk: low.** Verified against SDK changelog and source: every API we use is unchanged
across the whole range — `MCP::Server.new(name:, version:, instructions:, tools:, server_context:)`,
`server.handle_json`, the `MCP::Tool` subclass pattern (`description`, `input_schema`,
`self.call(..., server_context:)`), and `MCP::Tool::Response.new`. The CVE (GHSA-qvqr-5cv7-wh35,
SSE session hijacking) lives in `StreamableHTTPTransport`, which we don't use — our controller
returns 405 for GET/DELETE and calls `handle_json` directly. So this is hygiene, not an
emergency, but it clears the last actionable bundler-audit finding.

Steps:
1. **Write characterization tests first** — there is currently zero MCP test coverage.
   Integration test against `POST /mcp`: initialize handshake, `tools/list`, and a
   `tools/call` for at least one tool with `required`/`enum` schema fields, asserting
   response shape. Also auth failures (missing/invalid token → 401 with WWW-Authenticate).
2. Pin `gem "mcp", "~> 0.23"` in Gemfile, `bundle update --conservative mcp`.
3. Run the new tests. The only latent-surprise area is 0.22.0's JSON Schema 2020-12
   conformance / tightened argument validation — our schemas are vanilla
   (`type`/`properties`/`required`/`enum`), expected to pass unchanged.
4. Manually exercise one real tool call from Claude (MCP client) against dev.

Watch item: 0.15.0 changed tool argument-validation failures from protocol errors to tool
*execution* errors — clients see a different error shape for bad args. Acceptable; note in commit.

## Phase 2 — Low-risk minor bumps (one batch commit)

**Risk: minimal.** `bundle update --conservative` for: ferrum, fugit, ffi, bootsnap,
importmap-rails, jbuilder, kamal, net-ssh, propshaft, rubyzip, selenium-webdriver,
solid_queue (1.2→1.4), sqlite3, tailwindcss-rails/-ruby, thruster, turbo-rails,
web-console, rubocop family. Run tests + `bin/rubocop` (rubocop bump may add new cops;
fix or disable in .rubocop.yml, don't churn code).

## Phase 3 — Pagy 8.6 → 43.x (calendar versioning)

**Risk: medium — real API break, small surface.** Pagy rewrote its API after v9.
Call sites (verified, complete list):
- `app/controllers/insight_items_controller.rb:31` — `pagy(@insight_items, items: 12)`
- `app/controllers/api/v1/insight_items_controller.rb:17` — `pagy(..., items: params[:per_page] || 20)`
- `app/controllers/api/v1/base_controller.rb:63-68` — reads `pagy.page/.pages/.count/.items`
- `app/views/insight_items/index.html.erb` — pagy view helpers

Changes: constructor becomes method-style (`pagy(:offset, collection, limit:)`),
`items:` → `limit:` (attr `pagy.items` → `pagy.limit`), backend/frontend include and
nav helper names changed, initializer format changed. Read the migration guide for the
target version before touching code. Update controllers, metadata helper, view, and
`config/initializers/pagy.rb` if present. Verify: browse `/insight_items` pagination in
dev + API `per_page`/`pagination` JSON contract unchanged (API consumers depend on it).

## Phase 4 — image_processing 1.14 → 2.0 + minitest 5 → 6 + solid_cable 3 → 4

**Risk: low-medium.**
- `image_processing` 2.0: only three `variant(resize_to_limit: [200, 200])` call sites
  (application_helper.rb, profiles/edit). Check 2.0 release notes for processor default
  changes (vips/mini_magick); verify avatar upload + display in dev.
- `minitest` 6: test-only; Gemfile pins `~> 5.25` — bump pin, fix any assertion deprecations.
- `solid_cable` 4: check for new migrations against the cable database
  (`db/cable_migrate`); notifications live-updates depend on this in production —
  verify Turbo Stream broadcast (bell badge) after upgrade.

## Phase 5 — Rails 8.0.5 → 8.1.3

**Risk: highest, do last.** Gemfile already allows it (`~> 8.0.3` needs bump to `~> 8.1`).
1. `bundle update rails`, run `bin/rails app:update` (review each diff, keep our config).
2. Review `new_framework_defaults_8_1.rb`, enable defaults one by one, then flip
   `config.load_defaults 8.1`.
3. Full test suite + Brakeman + manual smoke: login, insight CRUD + iframe internal links,
   notifications bell, MCP tool call, native shell paths (`/dashboard` redirect).
4. Rebuild Docker image and deploy; migrations + solid_* schema changes may apply.

## Not planned

- `webrick` 1.9.2 CVE: transitive via ferrum, no patched release, zero exposure (never a
  request-serving server here). Revisit when ferrum updates or a webrick patch ships.
- `pagy` beyond, `parser`/`parallel`/`prism` etc.: transitive, follow their parents.
