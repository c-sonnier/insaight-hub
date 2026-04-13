# Research: CLI as an MCP Replacement for insAIght Hub
Date: 2026-04-13

## Questions Investigated

1. How does the existing MCP integration work? What tools are exposed, and how are they registered, authenticated, and invoked?
2. How does authentication work across MCP and REST API (tokens, OAuth, multi-account)?
3. What is the project's structure and tooling (Rails app, gems, bin/, lib/, existing CLI patterns)?
4. How do MCP tools map to underlying models/controllers/services? Is there shared business logic?
5. How does multi-account/multi-tenancy work, and how does it propagate into tools and API requests?
6. What REST API endpoints exist for programmatic access, and how do they differ from MCP tool coverage?
7. Are there past learnings, prior CLI attempts, or conventions that would constrain a CLI implementation?

## Past Learnings

No `docs/convergence/learnings/` or `docs/solutions/` directory exists. `docs/plans/multi-account-handling.md` marks the multi-account model "complete — all phases implemented," with `api_token` column removal from `identities` as the only pending step.

## Findings

### 1. MCP Integration

**Routes** (`config/routes.rb:17-20`):
```ruby
post   "mcp", to: "mcp#handle"
get    "mcp", to: "mcp#stream"       # returns 405
delete "mcp", to: "mcp#disconnect"   # returns 405
```
The `/mcp` path is listed in `AccountSlug::Extractor::GLOBAL_ROUTES` (`app/middleware/account_slug/extractor.rb:24`), so the MCP endpoint is **global** — it does not require an account UUID in the URL.

**Controller** (`app/controllers/mcp_controller.rb`, 116 lines):
- `McpController < ActionController::API`
- `before_action :set_current_account, :authenticate_identity, :require_account_membership`
- `require_account_membership` runs only `if: -> { @current_account.present? }` (`mcp_controller.rb:6`), so no-account (global) flow is allowed.
- `handle` instantiates `MCP::Server.new(name: "digest-hub", version: "1.0.0", tools: [...], server_context: { user:, identity:, account: })` and calls `server.handle_json(request.body.read)`.

**Tools registered on the server** (`mcp_controller.rb:25-34`):
`ListOrganizationsTool`, `ListInsightsTool`, `GetInsightTool`, `CreateInsightTool`, `UpdateInsightTool`, `PublishInsightTool`, `UnpublishInsightTool`, `DeleteInsightTool`, `MoveInsightTool`, `GetTagsTool` — 10 tools.

**Tools that exist as files but are NOT registered**: `AddCommentTool` (`app/tools/add_comment_tool.rb`) and `ListCommentsTool` (`app/tools/list_comments_tool.rb`). Git history: `e03fdcd feat: added comment tools to MCP server` added them; they are not present in the current `tools:` array.

**Tool pattern** (example: `app/tools/create_insight_tool.rb`):
```ruby
class CreateInsightTool < MCP::Tool
  extend OrganizationResolvable
  description "..."
  input_schema(properties: { organization: {...}, title: {...}, ... }, required: ["title", "audience"])
  class << self
    def call(title:, audience:, organization: nil, ..., server_context:)
      account, user, error = resolve_organization(organization:, server_context:)
      return error if error
      # ... build record, save, return:
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
```

All 10 registered tools return `MCP::Tool::Response.new([{ type: "text", text: <json>.to_json }])`.

**`mcp` gem**: `Gemfile:38` — `gem "mcp"`. No version pin.

### 2. Authentication

**Identity model** (`app/models/identity.rb`, 34 lines):
- `has_secure_password`, `email_address`, `name`
- `api_token` column exists (unique, auto-generated via `before_create :generate_api_token` using `SecureRandom.hex(32)`).
- `has_many :users, :sessions`; `has_many :accounts, through: :users`.
- `regenerate_api_token!` → `SecureRandom.hex(32)`.
- Plan notes `api_token` on `identities` is pending removal post-deploy (`docs/plans/multi-account-handling.md`).

**User model** (`app/models/user.rb`, 43 lines):
- Membership: `belongs_to :account, :identity`; `enum :role, { member:, owner: }`.
- Has own `api_token` (unique, allow_nil), auto-generated at create.
- `regenerate_api_token!` at `user.rb:34`.
- Delegates `email_address, name, admin?, theme, avatar` to `identity`.

**MCP auth** (`mcp_controller.rb:54-71`):
```ruby
@current_identity = authenticate_via_oauth(token) ||
                    Identity.find_by(api_token: token) ||
                    User.find_by(api_token: token)&.identity
```
Three token paths: OAuth 2.1 (via `Oauth::AccessToken.find_by_plaintext`), legacy Identity token, current User token. Missing token → 401 with `WWW-Authenticate` header pointing to `.well-known/oauth-protected-resource` (`mcp_controller.rb:109-115`).

**REST API auth** (`app/controllers/api/v1/base_controller.rb:17-35`):
```ruby
@token_user = User.find_by(api_token: token)
@token_user ||= Identity.find_by(api_token: token)&.users&.first
@current_identity = @token_user.identity
```
Two paths: User token (preferred), Identity token fallback.

**OAuth 2.1** (routes.rb:6-15): `.well-known/oauth-authorization-server`, `.well-known/oauth-protected-resource`, `oauth/register`, `oauth/authorize`, `oauth/token`, `oauth/revoke`. `Oauth::AccessToken` has `identity`, `scope`, `resource`. The resource is validated against `"#{base_url}/#{account.external_id}/mcp"` (`mcp_controller.rb:101-102`).

### 3. Project Structure & Existing Tooling

**Stack** (`Gemfile`, `codebase-structure.md`):
- Ruby 3.4.5, Rails 8.0.3, SQLite, Puma, Propshaft, Tailwind, Hotwire (Turbo+Stimulus), Solid Queue/Cache/Cable, Pagy 8, Redcarpet, `reverse_markdown`, Rubyzip, Ferrum (screenshots), Postmark, `mcp`, `kamal`, `thruster`.

**Directory `bin/`** (`ls bin/`): `brakeman`, `dev`, `docker-entrypoint`, `importmap`, `jobs`, `kamal`, `rails`, `rake`, `rubocop`, `setup`, `thrust`. No bespoke CLI entry point.

**Directory `lib/`**: Contains only `lib/tasks/` with `demo_reports.rake` and `thumbnails.rake`. No `lib/cli/`, no Thor or GLI usage. Grep for `Thor`/`GLI`/`Commander` in `Gemfile` returns no matches.

**Middleware directory**: `app/middleware/account_slug/extractor.rb` (82 lines). Wired at `config/initializers/account_slug_middleware.rb`.

### 4. Tool-to-Model/Controller Mapping

Tools do **not** delegate to controllers or service objects; they call ActiveRecord directly.

| Tool (lines) | Model operations |
|---|---|
| `ListOrganizationsTool` (28) | `identity.users.includes(:account).map` |
| `ListInsightsTool` (94) | `account.insight_items.includes(...)` + scopes `by_audience`, `by_tag`, `search_basic`; manual pagination (not Pagy) |
| `GetInsightTool` (74) | `account.insight_items.find_by(slug:)`, `insight.files_as_markdown` when `format: "markdown"` |
| `CreateInsightTool` (123) | Builds `InsightItem` + nested `insight_item_files`; optional `insight.publish!` |
| `UpdateInsightTool` (121) | Upserts files by filename; checks `insight.user_id == user.id` |
| `PublishInsightTool` (61) | `insight.publish!` after ownership check |
| `UnpublishInsightTool` (60) | `insight.unpublish!` after ownership check |
| `DeleteInsightTool` (48) | `insight.destroy!` after ownership check |
| `MoveInsightTool` (60) | `insight.update!(account: target_account, user: target_user)` |
| `GetTagsTool` (34) | `account.insight_items.pluck(:metadata).map { dig("tags") }.flatten.uniq.sort` |

The REST API controllers (e.g., `Api::V1::InsightItemsController`, 179 lines) duplicate this logic with Rails patterns (strong params, `pagy`, `render json:`). There is no shared service layer — MCP tools and API controllers independently implement CRUD and authorization. Example divergence: API uses `pagy` (`base_controller.rb:2`); MCP tool does manual offset/limit (`list_insights_tool.rb:46-54`).

Ownership check appears inline in each tool: `unless insight.user_id == user.id`.

### 5. Multi-Tenancy

**Data model** (`docs/plans/multi-account-handling.md`, `app/models/*.rb`):
- `Identity` = person (email, password).
- `Account` = organization (`name`, `external_id: UUID`, `to_param → external_id`).
- `User` = membership = `(identity, account, role)`; owns `api_token`, `insight_items`.
- One identity → many users (one per account).

**Middleware** (`app/middleware/account_slug/extractor.rb`):
- Matches leading UUID segment in `PATH_INFO` (regex `/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i`).
- Sets `env["insaight.account"]` and rewrites `SCRIPT_NAME`/`PATH_INFO` so Rails routes see a path without the UUID prefix.
- `GLOBAL_ROUTES = %w[/ /up /health /waitlist /s /assets /rails /session /passwords /setup /register /how-to /oauth /.well-known /accounts /mcp]` — these bypass extraction.

**Effect on endpoints**:
- REST API: path is `/<account_uuid>/api/v1/insight_items` (API is **not** in GLOBAL_ROUTES). `Api::V1::BaseController` reads `Current.account` from `env["insaight.account"]` (`base_controller.rb:13-15`). Requests without UUID prefix hit root/404.
- MCP: path is `/mcp` (global). `set_current_account` reads `env["insaight.account"]` which is `nil` in the global case (`mcp_controller.rb:48-52`). Tools then resolve the account from the `organization` tool argument via `OrganizationResolvable`.

**`OrganizationResolvable` concern** (`app/tools/concerns/organization_resolvable.rb`, 41 lines):
```ruby
def resolve_organization(organization:, server_context:)
  if organization.present?
    account = identity.accounts.find_by(external_id: organization) ||
              identity.accounts.find_by(name: organization)
    return error_response if !account
    [account, identity.users.find_by(account:), nil]
  elsif server_context[:account]
    [server_context[:account], server_context[:user], nil]
  else
    accounts = identity.accounts
    accounts.one? ? [accounts.first, identity.users.find_by(account: accounts.first), nil] : error_response
  end
end
```
Fallback order: explicit `organization` param → URL-scoped account → sole-account default → error asking user to call `list_organizations`.

**Tools without `OrganizationResolvable`**: `AddCommentTool` and `ListCommentsTool` use `InsightItem.find_by(slug:)` globally (cross-account), relying on `server_context[:user]` directly. These are not registered on the server (§1).

**Cross-account token behavior**: A single `User#api_token` grants access "for the same identity" across accounts. From `base_controller.rb` comment at line 44: "Token grants cross-account access for the same identity." This is enforced by resolving `@current_user = @current_identity.users.find_by(account: Current.account)` per request.

### 6. REST API Surface

**Routes** (`config/routes.rb:95-108`, inside `/<account_uuid>/`):

| Method | Path | Controller#action |
|---|---|---|
| GET | `/api/v1/me` | `Api::V1::MeController#show` |
| GET | `/api/v1/tags` | `Api::V1::TagsController#index` |
| GET | `/api/v1/insight_items` | `#index` (supports `status, audience, tag, q, per_page, page`) |
| POST | `/api/v1/insight_items` | `#create` (single-file via `content` or multi via `files: [{filename, content}]`) |
| GET | `/api/v1/insight_items/:id` | `#show` (supports `content_format=markdown`) |
| PATCH | `/api/v1/insight_items/:id` | `#update` (upsert files by filename) |
| DELETE | `/api/v1/insight_items/:id` | `#destroy` |
| POST | `/api/v1/insight_items/:id/publish` | `#publish` |
| POST | `/api/v1/insight_items/:id/unpublish` | `#unpublish` |
| POST | `/api/v1/insight_items/:id/move` | `#move` (body: `target_account_id: <external_id>`) |
| DELETE | `/api/v1/insight_items/:id/files/:filename` | `Api::V1::InsightItemFilesController#destroy` |

**Gaps relative to MCP tools**:
- No REST endpoint for listing organizations (MCP has `ListOrganizationsTool`). Closest is `GET /api/v1/me`, which returns membership info for the *current* account only (`me_controller.rb:16-22`).
- No REST endpoint for comments (API controllers for comments exist only at the web layer, not under `Api::V1::`).
- `InsightItem` `:id` param in REST is actually the `slug` (model overrides `to_param` to `slug`, `codebase-structure.md:397`).

**Response shapes**: JSON objects with top-level keys like `insight_items`, `insight_item`, `pagination`, `error`, `errors`. Pagination via `pagy_metadata` in `base_controller.rb:63-70`.

### 7. Prior CLI Attempts

Grep across `Gemfile`, `bin/`, `lib/` finds no Thor, GLI, Commander, or OptionParser-based CLI. No `bin/insaight`, `bin/hub`, or similar scripts. Git log for `app/tools/` and `app/controllers/mcp_controller.rb`:

```
00cc4c7 fix: preserve existing API tokens during migration
f9d181f fix: MCP global endpoint and org-aware improvements
84b2ee3 feat: multi-account handling (phases 1-4)
2d1a48c fix: guide LLM to batch file creation for large multi-file insights
6de48e4 feat: add markdown output format for insights
9e356d6 fix: resolve MCP OAuth reconnection failure with resource parameter mismatch
629821c feat: implement OAuth 2.1 authorization for MCP server
37690c5 feat: update MCP tools for multi-tenancy
8e0fa2b feat: update API controllers for multi-tenancy
e03fdcd feat: added comment tools to MCP server
a03f030 fix: mcp authentication bug
3299d6f feat: added MCP server capability
```

## Existing Patterns

- **Bearer-token auth for programmatic access**: both MCP and REST use `Authorization: Bearer <token>` (`mcp_controller.rb:55`, `base_controller.rb:18`). Token types accepted: OAuth (MCP only), `Identity.api_token` (legacy), `User.api_token` (current).
- **Account resolution by name or UUID**: `OrganizationResolvable` looks up `external_id` then `name`. `Account.external_id` is a UUID; `to_param` returns it.
- **JSON responses**: MCP tools wrap in `MCP::Tool::Response.new([{ type: "text", text: json }])`; REST uses `render json:`. Both return `{ error: "...", messages: [...] }` on failure.
- **Ownership check**: `insight.user_id == user.id` — enforced in-tool and in-controller (`api/v1/insight_items_controller.rb:101-105`, `publish_insight_tool.rb:31`, etc.). Super admins can access any account (`mcp_controller.rb:86-92`, `base_controller.rb:41`).
- **Slug as identifier**: `InsightItem.to_param` returns `slug`. All tools and REST endpoints accept slug as `:id`.
- **File upsert by filename**: `UpdateInsightTool` and `Api::V1::InsightItemsController#update` both upsert `insight_item_files` keyed by `filename`.
- **Multi-file creation limit**: `CreateInsightTool` description guides callers to create with entry file first, then `update_insight` in 2-3 file batches to avoid request-size limits (`create_insight_tool.rb:6`).
- **Content formats**: `GetInsightTool` defaults to `markdown` (strips CSS/JS, converts HTML via `reverse_markdown`); REST `GET /api/v1/insight_items/:id` defaults to `html` (`content_format=markdown` opts in).

## Code Health

| Area | Size | Notes |
|---|---|---|
| `app/tools/*.rb` | 10 files, 28-123 lines each (~760 LOC total) | Low-logic, no tests under `test/tools/` confirmed via directory listing. |
| `app/controllers/mcp_controller.rb` | 116 lines | OAuth + token-fallback auth logic inline. |
| `app/controllers/api/v1/base_controller.rb` | 73 lines | Shared before_actions, pagy_metadata helper. |
| `app/controllers/api/v1/insight_items_controller.rb` | 179 lines | Duplicates logic from tools. |
| `app/models/insight_item.rb` | 147 lines | Core domain model with `publish!`, `unpublish!`, `files_as_markdown`, sharing helpers. |
| `app/middleware/account_slug/extractor.rb` | 82 lines | Single-purpose, fully tested via GLOBAL_ROUTES constant. |
| `app/tools/concerns/organization_resolvable.rb` | 41 lines | Only shared tool helper. |
| Tests | `test/tools/` not listed in codebase-structure.md; MCP tools have no test files visible under `app/tools/` spot check. | REST API test coverage not audited in this pass. |

High churn on multi-account (Phase 1-4 merged recently: `84b2ee3`, `f9d181f`). Recent focus: MCP global endpoint, OAuth resource validation, API token migration.

## Dependencies

**Runtime** (`Gemfile`):
- `rails ~> 8.0.3` — controllers, routing, AR
- `mcp` (no pin) — `MCP::Server`, `MCP::Tool`, `MCP::Tool::Response`
- `bcrypt ~> 3.1.7` — identity passwords (not CLI-relevant)
- `pagy ~> 8.0` — REST pagination
- `redcarpet`, `reverse_markdown` — markdown rendering/conversion in `GetInsightTool` and `InsightItem#files_as_markdown`
- `rubyzip` — profile export/import; not touched by tools or API
- `sqlite3 >= 2.1` — local dev DB
- `kamal` (require: false), `thruster` (require: false) — deploy

**Dev/test**: `debug`, `brakeman`, `rubocop-rails-omakase`, `capybara`, `selenium-webdriver`, `minitest ~> 5.25`.

**No CLI framework gem is present** (no `thor`, `gli`, `commander`, `dry-cli`, `tty-*`).

**Config**:
- `config/initializers/account_slug_middleware.rb` — `config.middleware.use AccountSlug::Extractor`
- `Current` model resolves `identity` (from session), `account`, `user` per request.
- API token generation: `SecureRandom.hex(32)` in both `User#generate_api_token` and `Identity#generate_api_token`.
