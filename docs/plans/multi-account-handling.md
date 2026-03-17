# Multi-Account Handling Plan

> **Status**: Decisions made — ready for implementation planning.

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

### Phase 1: Last-Used Account & Login Redirect
_Foundation — everything else depends on this._

- [ ] Migration: add `last_account_id` (references accounts) to `identities`
- [ ] Update `after_authentication_url` in `Authentication` concern to use `last_account_id` (fall back to `accounts.first`)
- [ ] Update `HomeController#index` redirect to use `last_account_id`
- [ ] Set `last_account_id` in `AccountScoped#set_current_account` so it updates on every account visit

**Files:** `authentication.rb`, `home_controller.rb`, `account_scoped.rb`, `identity.rb`

### Phase 2: Account Switcher UI
_Visible multi-account experience._

- [ ] Sidebar partial: account switcher section above Dashboard link
- [ ] Show current account name (highlighted), list other accounts as links to `/{uuid}/dashboard`
- [ ] Only render if identity has 2+ accounts
- [ ] Mobile-responsive (works in sidebar drawer)

**Files:** `_sidebar.html.erb`, `account_routing_helper.rb`

### Phase 3: Self-Service Account Creation + Zero Accounts
_Lets users create orgs and handles the empty state._

- [ ] `AccountsController#new/create` — form to create a new Account
- [ ] On create: build Account + User membership (role: owner)
- [ ] Add "Create Organization" link in account switcher section
- [ ] Zero-accounts guard: if identity has no accounts after login, redirect to create org flow
- [ ] Route: global (no account prefix) since there's no account context yet

**Files:** new controller, routes.rb, `authentication.rb`, `account_scoped.rb`

### Phase 4: API Token Migration
_Move token from Identity to User, support cross-account access._

- [ ] Migration: add `api_token` to `users`, generate tokens for existing users
- [ ] Update `Api::V1::BaseController` to authenticate via User token
- [ ] Cross-account logic: find User by token, then allow access to any account the identity belongs to
- [ ] Update profile page to show per-membership token
- [ ] Migration: remove `api_token` from `identities` (after deploy + verification)
- [ ] Add "move insight" endpoint: `POST /api/v1/insight_items/:id/move` with `target_account_id`

**Files:** `user.rb`, `identity.rb`, `api/v1/base_controller.rb`, `profiles_controller.rb`, new migration

### Phase 5: Invite Flow Hardening
_The registration controller already handles existing identities — verify and improve._

- [ ] Verify: inviting an existing email creates User membership, not duplicate Identity
- [ ] Edge case: invite to a different email than existing identity — decide behavior
- [ ] Test: accept invite while logged in vs. logged out

**Files:** `registrations_controller.rb`, `admin/invites_controller.rb`

### Phase 6: Admin Role Clarity & Data Isolation Audit
_Cleanup and verification pass._

- [ ] Audit: ensure admin UI shows account owners, not super admins, in organization view
- [ ] Audit: search, tags, export, public share links all respect account boundaries
- [ ] Verify super admin bypass works correctly across all account-scoped controllers

**Files:** `admin/organization_controller.rb`, all account-scoped controllers

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
