# OAuth 2.1 Implementation Plan for MCP Server

## Summary

Implement OAuth 2.1 authorization for the MCP server with:
- Built-in OAuth authorization server (Rails app acts as auth server)
- Dynamic Client Registration (RFC 7591)
- OAuth tokens replace API tokens for MCP authentication
- PKCE required (S256 method)
- Resource parameter for audience binding (RFC 8707)

## Architecture Decisions

1. **Custom implementation** (not Doorkeeper) - MCP has unique requirements (RFC 9728, resource parameter) that Doorkeeper doesn't natively support
2. **Global OAuth endpoints** - Not account-scoped; the `resource` parameter specifies which account (format: the account's MCP endpoint URL, e.g. `https://app.example.com/{slug}/mcp`)
3. **Token-Account binding** - Access tokens bound to specific account via resource parameter
4. **Revocation cascade** - Revoking a refresh token also revokes all access tokens issued from it

## Implementation Phases

### Phase 1: Feature Branch + Database Schema

Create feature branch and migration for OAuth tables:

**Files:**
- `db/migrate/YYYYMMDDHHMMSS_create_oauth_tables.rb`

**Token storage:** All token/code columns store SHA-256 digests. Plaintext values are returned to the client only once at creation and never stored.

**Tables:**
- `oauth_clients` - client_id, client_secret_digest, client_name, redirect_uris (json), grant_types (json), token_endpoint_auth_method, registration_access_token_digest
- `oauth_authorization_codes` - code_digest, client_id, identity_id, account_id, redirect_uri, scope, code_challenge, code_challenge_method, resource, state, expires_at, used_at
- `oauth_access_tokens` - token_digest, client_id, identity_id, account_id, scope, resource, refresh_token_id, expires_at, revoked_at
- `oauth_refresh_tokens` - token_digest, client_id, identity_id, account_id, scope, resource, expires_at, revoked_at, previous_token_id

### Phase 2: OAuth Models

**Files:**
- `app/models/oauth/client.rb` - Client registration with redirect URI validation
- `app/models/oauth/authorization_code.rb` - Short-lived codes (10 min expiry)
- `app/models/oauth/access_token.rb` - Bearer tokens (1 hour expiry)
- `app/models/oauth/refresh_token.rb` - With rotation support

### Phase 3: OAuth Services

**Files:**
- `app/services/oauth/pkce_verifier.rb` - S256 challenge verification
- `app/services/oauth/authorization_service.rb` - Creates authorization codes
- `app/services/oauth/token_service.rb` - Exchanges codes for tokens, handles refresh

### Phase 4: OAuth Controllers

**Files:**
- `app/controllers/oauth/base_controller.rb` - Base controller with error handling
- `app/controllers/oauth/metadata_controller.rb` - Discovery endpoints
- `app/controllers/oauth/clients_controller.rb` - Dynamic client registration (POST /oauth/register) and client read (GET /oauth/register/:client_id, authenticated via registration_access_token)
- `app/controllers/oauth/authorization_controller.rb` - Authorization flow (GET/POST /oauth/authorize). Requires authenticated session — redirects to login (with return URL) if unauthenticated
- `app/controllers/oauth/tokens_controller.rb` - Token endpoint (POST /oauth/token)
- `app/controllers/oauth/revocation_controller.rb` - Token revocation (POST /oauth/revoke)

### Phase 5: Routes + Middleware Update

**Files to modify:**
- `config/routes.rb` - Add OAuth routes
- `app/middleware/account_slug/extractor.rb` - Add OAuth paths to GLOBAL_ROUTES

**New routes:**
```
GET  /.well-known/oauth-authorization-server
GET  /.well-known/oauth-protected-resource
POST /oauth/register
GET  /oauth/register/:client_id
GET  /oauth/authorize
POST /oauth/authorize
POST /oauth/token
POST /oauth/revoke
```

### Phase 6: Update MCP Controller

**File to modify:**
- `app/controllers/mcp_controller.rb`

Changes:
1. Try OAuth token first, fall back to API token (temporary backward compatibility — remove API token fallback once clients have migrated)
2. Validate resource parameter matches the account's MCP endpoint URL
3. Return proper `WWW-Authenticate` header on 401 (per MCP spec)

### Phase 7: Consent Screen (implement alongside Phase 4)

Depends on existing session auth. The authorization controller (Phase 4) redirects unauthenticated users to login, preserving the full `/oauth/authorize?...` URL as the return path. After login, the user lands on the consent screen. Implement this view at the same time as the authorization controller — the controller cannot function without it.

**File:**
- `app/views/oauth/authorization/new.html.erb` - User consent UI showing client name, requested scopes, account

### Phase 8: Cleanup Job

**File:**
- `app/jobs/oauth/cleanup_job.rb` - Removes expired codes/tokens

## Scopes

| Scope | Description |
|-------|-------------|
| `mcp:read` | Read insights, tags, comments |
| `mcp:write` | Create, update, delete insights |
| `mcp:admin` | Full access including publish/unpublish |

Scopes are **additive** — `mcp:write` does not imply `mcp:read`. Clients must request each scope they need. If the `scope` parameter is omitted during authorization, default to `mcp:read`.

## Key Security Features

- PKCE required (S256 method only)
- Short-lived access tokens (1 hour)
- Refresh token rotation for public clients
- Resource parameter validation (audience binding)
- HTTPS required for redirect URIs (except localhost)
- State parameter for CSRF protection

## Critical Files to Modify

| File | Changes |
|------|---------|
| `app/controllers/mcp_controller.rb:41-55` | Add OAuth token auth with fallback |
| `app/middleware/account_slug/extractor.rb:8-21` | Add `/oauth` and `/.well-known` to GLOBAL_ROUTES |
| `config/routes.rb` | Add OAuth routes at top level |

## Verification Plan

1. **Run migrations**: `rails db:migrate`
2. **Test client registration**: `curl -X POST /oauth/register -d '{"client_name":"Test","redirect_uris":["http://localhost:3000/callback"]}'`
3. **Test discovery endpoints**: `curl /.well-known/oauth-authorization-server`
4. **Test full OAuth flow**:
   - Register client
   - Navigate to `/oauth/authorize?client_id=...&response_type=code&redirect_uri=...&code_challenge=...&code_challenge_method=S256&resource=...`
   - Approve consent
   - Exchange code for token at `/oauth/token`
   - Use token to call MCP endpoint
5. **Test MCP with OAuth token**: `curl -X POST /{account}/mcp -H "Authorization: Bearer {oauth_token}"`
6. **Test 401 response**: Verify `WWW-Authenticate` header returned for unauthenticated requests
7. **Run existing tests**: `rails test` to ensure no regressions
