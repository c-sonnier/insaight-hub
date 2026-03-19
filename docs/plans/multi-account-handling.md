# Multi-Account Handling Plan

> **Status**: Complete — all phases implemented. Only remaining item: remove `api_token` from `identities` table after deploy verification.

---

## Current State

The core multi-org data model is already in place:

- **Identity** — the person (email, password, api_token)
- **Account** — the organization (name, external_id/UUID)
- **User** — join/membership model (identity + account + role: owner/member)
- **Middleware** — `AccountSlug::Extractor` pulls account UUID from URL path (`/{uuid}/dashboard`)
- **`AccountScoped` concern** — sets `Current.account` from middleware, enforces membership
- **`Current`** — resolves `identity` from session, `user` from identity + account

## What's Missing

### 1. Account Switcher UI
- Sidebar/navbar dropdown showing the identity's accounts
- Current account highlighted, others clickable
- Links route to `/{other_account_uuid}/dashboard`
- Only render if identity has 2+ accounts

### 2. Login Redirect Logic
- `after_authentication_url` and `HomeController#index` both hardcode `identity.accounts.first`
- Need to remember last-used account and redirect there instead

### 3. Invite Flow for Existing Identities
- Current invite flow creates a new identity + user
- If someone is invited to a new org but already has an identity (same email), should create only a new `User` membership — not a second identity
- Edge case: invite sent to a different email than the identity's existing email

### 4. Account Creation by Existing Users
- Allow an existing identity to create a new Account
- "Create Organization" flow — creates Account + User membership as `owner`
- Or: restrict to invite/admin-only

### 5. API Token Scoping
- `api_token` lives on Identity (global) — one token = access to all accounts
- Option A: Keep global (simpler, account UUID in URL already scopes access)
- Option B: Per-account tokens on User model (more secure, more complex)

### 6. Admin Role Clarity
- `Identity.admin` = super admin (cross-account) — already distinct from `User.role`
- Ensure admin UI respects the difference (account settings show owners, not super admins)

### 7. Data Isolation Audit
- Most queries already scope through `current_account` — good
- Verify: search, tags, export, public share links all respect account boundaries

---

## Decisions

1. **Account switcher placement** — Sidebar, above the Dashboard link, in its own section. Only render if identity has 2+ accounts.
2. **"Last used account" persistence** — Column on Identity (`last_account_id`). Update on each account switch/login.
3. **Can users create new organizations?** — Yes, self-service. Any identity can create a new Account (becomes owner).
4. **API tokens** — Single token per User (membership) that grants access to all of the identity's accounts. Token moves from Identity to User model, but cross-account access is allowed for the same identity. Adds ability to move an insight between organizations (e.g., if posted to wrong org via API).
5. **What happens with 0 accounts?** — Redirect to "create org" flow so the user can self-service a new organization.

---

## Implementation Phases

### Phase 1: Last-Used Account & Login Redirect — DONE

- [x] Migration: add `last_account_id` (references accounts) to `identities`
- [x] Update `after_authentication_url` to use `last_account_id` (fall back to `accounts.first`)
- [x] Update `HomeController#index` redirect to use `last_account_id`
- [x] Set `last_account_id` in `AccountScoped#set_current_account` via `track_last_account`

### Phase 2: Account Switcher UI — DONE

- [x] Sidebar dropdown above Dashboard link (uses `details` with DaisyUI dropdown)
- [x] Current account highlighted, others as links to `/{uuid}/dashboard`
- [x] Only renders if identity has 2+ accounts
- [x] "Create Organization" link at bottom of dropdown

### Phase 3: Self-Service Account Creation + Zero Accounts — DONE

- [x] `AccountsController#new/create` — creates Account + User (owner)
- [x] Zero-accounts redirect to create org flow (both login and home)
- [x] Global route `/accounts/new` (no account prefix)

### Phase 4: API Token Migration + Org-Aware MCP — DONE

- [x] Migration: `api_token` on `users` with unique index, tokens generated for existing users
- [x] API auth via `User.find_by(api_token:)` with cross-account access
- [x] Profile page shows per-membership token
- [x] Move insight API endpoint
- [x] New MCP tools: `list_organizations`, `move_insight`
- [x] All MCP tools accept optional `organization` param via `OrganizationResolvable`
- [x] Global `/mcp` endpoint (no account UUID in URL)
- [x] Updated how-to docs and profile page with Claude Code auto-setup prompt
- [ ] Migration: remove `api_token` from `identities` (after deploy + verification)

### Phase 5: Invite Flow Hardening — DONE

- [x] Verified: existing email creates User membership only, not duplicate Identity
- [x] Fixed: handle case where identity already has membership in invite's account (graceful skip)
- [x] Edge case: invite to different email — handled by form (email-less invites allow any email)

### Phase 6: Admin Role Clarity & Data Isolation Audit — DONE

- [x] Admin org view shows `account.users` (account members), not super admins — correct
- [x] All controllers query through `current_account` — search, tags, export, comments all scoped
- [x] Public share links use `share_token` lookup (account-agnostic by design) — correct
- [x] Super admin bypass works via `Current.super_admin?` checks — distinct from `Current.owner?`

---

## Key Files

| File | Relevance |
|------|-----------|
| `app/models/identity.rb` | Person model, has_many accounts through users |
| `app/models/account.rb` | Organization model |
| `app/models/user.rb` | Membership join model (identity + account + role) |
| `app/models/current.rb` | CurrentAttributes — resolves identity, account, user |
| `app/middleware/account_slug/extractor.rb` | URL-based account resolution |
| `app/controllers/concerns/account_scoped.rb` | Account context + membership enforcement |
| `app/controllers/concerns/authentication.rb` | Login redirect logic (`after_authentication_url`) |
| `app/controllers/home_controller.rb` | Dashboard redirect (hardcodes `.first`) |
| `app/controllers/registrations_controller.rb` | Invite-based registration flow |
| `app/views/oauth/authorization/new.html.erb` | Already has multi-account selector for OAuth |
