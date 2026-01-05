# insAIght Hub - Codebase Structure

> **For AI Agents**: Read this document before exploring the codebase to understand architecture, conventions, and where to find things.

## Overview

insAIght Hub is a Rails 8 application that transforms scattered AI outputs into structured, searchable, and shareable insights. It provides:

- **Insight Management**: Create, edit, and publish multi-file insights (HTML, CSS, JS)
- **Audience Targeting**: Tag content for developers, stakeholders, or end users
- **Threaded Comments**: Collaborate on published insights
- **REST API**: Programmatic access with token authentication
- **MCP Server**: AI agent integration via Model Context Protocol

### Key Terminology

| Term | Rails Model | Description |
|------|-------------|-------------|
| Insight | `InsightItem` | A collection of one or more HTML files representing content |
| Insight File | `InsightItemFile` | An individual file within an insight |
| Audience | String enum | Target reader: `developer`, `stakeholder`, `end_user` |
| Status | String enum | `draft` or `published` |
| Waitlist Entry | `WaitlistEntry` | Email signup for public waitlist |
| Share Token | String | Unique token for public sharing of insights |

---

## Tech Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Language | Ruby | 3.4.5 |
| Framework | Rails | 8.0.3 |
| Database | SQLite | via `sqlite3` gem |
| Asset Pipeline | Propshaft | Rails 8 default |
| CSS | Tailwind CSS + DaisyUI | via `tailwindcss-rails` |
| JavaScript | Hotwire (Turbo + Stimulus) | via `importmap-rails` |
| Authentication | Rails 8 built-in | `has_secure_password` |
| Background Jobs | Solid Queue | Rails 8 default |
| Action Cable | Solid Cable | Rails 8 default |
| Cache | Solid Cache | Rails 8 default |
| Pagination | Pagy | ~> 8.0 |
| MCP | `mcp` gem | Model Context Protocol |

---

## Directory Structure

```
app/
├── assets/
│   ├── images/              # SVG icons, hero images
│   ├── stylesheets/         # Custom CSS (beyond Tailwind)
│   └── tailwind/            # Tailwind entry point
├── channels/
│   └── insight_items_channel.rb   # Real-time updates for new insights
├── controllers/
│   ├── admin/               # Admin namespace (users, invites)
│   ├── api/v1/              # REST API controllers
│   ├── concerns/            # Authentication concern
│   ├── application_controller.rb
│   ├── insight_items_controller.rb
│   ├── comments_controller.rb
│   ├── home_controller.rb   # Landing + dashboard
│   ├── mcp_controller.rb    # MCP endpoint handler
│   └── ...
├── helpers/
│   ├── application_helper.rb
│   └── meta_tags_helper.rb
├── javascript/
│   └── controllers/         # Stimulus controllers
├── models/
│   ├── insight_item.rb      # Main insight model
│   ├── insight_item_file.rb # Files within insights
│   ├── user.rb              # User with auth + API token
│   ├── comment.rb           # Comments on insights
│   ├── engagement.rb        # Links users to comments/insights
│   ├── invite.rb            # Invite-only registration
│   └── session.rb           # Rails 8 auth sessions
├── tools/                   # MCP Tools for AI agents
│   ├── create_insight_tool.rb
│   ├── list_insights_tool.rb
│   ├── get_insight_tool.rb
│   ├── update_insight_tool.rb
│   ├── delete_insight_tool.rb
│   ├── publish_insight_tool.rb
│   ├── unpublish_insight_tool.rb
│   ├── get_tags_tool.rb
│   ├── add_comment_tool.rb
│   └── list_comments_tool.rb
└── views/
    ├── admin/               # Admin views (users, invites, waitlist)
    ├── comments/            # Comment partials
    ├── home/                # Landing, dashboard, how-to
    ├── insight_items/       # Insight CRUD views + share panel
    ├── layouts/             # Application + public layouts
    ├── public_insights/     # Public share views
    ├── waitlist/            # Waitlist signup views
    └── ...

config/
├── routes.rb               # All route definitions
├── database.yml            # SQLite config (dev/test/prod)
├── importmap.rb            # JavaScript imports
└── initializers/           # Rails initializers

db/
├── schema.rb               # Current database schema
├── migrate/                # Migration files
└── seeds.rb                # Default admin user

docs/
├── API.md                  # REST API documentation
└── PRD.md                  # Product requirements document
```

---

## Models & Relationships

### Core Models

```
User
├── has_many :sessions
├── has_many :insight_items
├── has_many :engagements
├── has_many :comments, through: :engagements
├── has_many :created_invites (as creator)
└── has_one_attached :avatar

InsightItem
├── belongs_to :user
├── has_many :insight_item_files
├── has_many :engagements
└── has_many :comments, through: :engagements

InsightItemFile
└── belongs_to :insight_item

Comment
├── belongs_to :parent (optional, for threading)
└── has_many :replies (self-referential)

Engagement (join model)
├── belongs_to :insight_item
├── belongs_to :user
└── belongs_to :engageable (polymorphic: Comment)

Invite
├── belongs_to :created_by (User)
└── belongs_to :used_by (User, optional)

WaitlistEntry
└── (standalone - email signups for public waitlist)
```

### Key Model Behaviors

**InsightItem**:
- `enum :audience` → `developer`, `stakeholder`, `end_user`
- `enum :status` → `draft`, `published`
- Auto-generates `slug` from title
- Tags stored in `metadata` JSON field
- `to_param` returns `slug` for friendly URLs
- `publish!` broadcasts to ActionCable channel
- **Public Sharing**: `share_token`, `share_enabled` fields
- `enable_sharing!` / `disable_sharing!` / `regenerate_share_token!`
- `shareable?` returns true when published + share_enabled + has token

**User**:
- `has_secure_password` for authentication
- Auto-generates `api_token` on create
- `regenerate_api_token!` for token rotation

---

## Controllers

### Web Controllers

| Controller | Purpose |
|------------|---------|
| `HomeController` | Landing page (`#index`), dashboard (`#dashboard`), how-to (`#how_to`) |
| `InsightItemsController` | Full CRUD + publish/unpublish/export |
| `InsightItemFilesController` | Serves raw file content for iframe display |
| `CommentsController` | CRUD for comments on insights |
| `ProfilesController` | User profile management + token regeneration |
| `SessionsController` | Login/logout (Rails 8 auth) |
| `PasswordsController` | Password reset flow |
| `RegistrationsController` | Invite-based registration |
| `OnboardingController` | First-user setup flow |
| `McpController` | MCP protocol handler endpoint |
| `WaitlistController` | Public waitlist signup |
| `PublicInsightsController` | Public sharing view (unauthenticated) |
| `PublicInsightFilesController` | Serves files for public shared insights |

### Admin Controllers (`Admin::`)

| Controller | Purpose |
|------------|---------|
| `BaseController` | Admin authorization check |
| `UsersController` | User management (CRUD) |
| `InvitesController` | Invite creation/management |
| `WaitlistEntriesController` | View/manage waitlist signups |

### API Controllers (`Api::V1::`)

| Controller | Purpose |
|------------|---------|
| `BaseController` | Token authentication, JSON responses |
| `InsightItemsController` | REST API for insights |
| `InsightItemFilesController` | File deletion API |
| `MeController` | Current user info |
| `TagsController` | List all tags |

---

## Routes Summary

```ruby
# Health check
GET /health
GET /up

# MCP endpoint
POST /mcp

# Authentication
resource :session                    # login/logout
resources :passwords, param: :token  # password reset

# Registration (invite-only)
GET/POST /register/:token

# Main pages
root "home#index"                    # landing (public) or dashboard (logged in)
GET /dashboard
GET /how-to

# Waitlist (public signup)
GET/POST /waitlist
GET /waitlist/thank-you

# Public share links (unauthenticated)
GET /s/:token                        # view shared insight
GET /s/:token/files/*id              # serve shared insight files

# Insights
resources :insight_items do
  member { post :publish, :unpublish, :enable_share, :disable_share, :regenerate_share_token; get :export }
  get "files/*id"                    # serve file content
  resources :comments, only: [:create, :update, :destroy]
end
GET /my-insights

# Profile
resource :profile do
  post :regenerate_token
  get :export_all_insights
  post :import_insights
end

# Admin
namespace :admin do
  resources :users
  resources :invites, only: [:index, :new, :create, :destroy]
  resources :waitlist_entries, only: [:index, :destroy]
end

# API
namespace :api do
  namespace :v1 do
    resource :me, only: [:show]
    resources :tags, only: [:index]
    resources :insight_items do
      member { post :publish, :unpublish }
      resources :files, only: [:destroy]
    end
  end
end
```

---

## Stimulus Controllers (JavaScript)

| Controller | Purpose |
|------------|---------|
| `avatar_upload_controller` | Avatar image upload handling |
| `clipboard_controller` | Copy to clipboard (API token, etc.) |
| `comments_controller` | Comment form interactions |
| `comments_drawer_controller` | Slide-out comments panel |
| `comparison_controller` | Side-by-side comparison view |
| `fullscreen_controller` | Toggle fullscreen mode for insight view |
| `insight_form_controller` | Dynamic file management in insight forms |
| `insight_view_controller` | Insight viewing with file navigation |
| `live_updates_controller` | ActionCable subscriptions for real-time updates |
| `nav_sidebar_controller` | Navigation sidebar toggle |
| `sidebar_toggle_controller` | Sidebar open/close |
| `theme_controller` | Theme switching (light/dark/custom) |

---

## MCP Tools (AI Agent Integration)

Tools are defined in `app/tools/` and follow the `MCP::Tool` pattern:

| Tool | Description |
|------|-------------|
| `ListInsightsTool` | List insights with filtering (status, audience, tag, search) |
| `GetInsightTool` | Get single insight by slug with all files |
| `CreateInsightTool` | Create insight (single-file via `content` or multi-file via `files`) |
| `UpdateInsightTool` | Update insight metadata and/or files |
| `DeleteInsightTool` | Delete insight and all files |
| `PublishInsightTool` | Publish a draft insight |
| `UnpublishInsightTool` | Revert to draft status |
| `GetTagsTool` | Get all unique tags |
| `AddCommentTool` | Add comment to an insight |
| `ListCommentsTool` | List comments for an insight |

### Tool Pattern

```ruby
class CreateInsightTool < MCP::Tool
  description "Create a new insight..."
  
  input_schema(
    properties: {
      title: { type: "string", description: "..." },
      # ...
    },
    required: ["title", "audience"]
  )
  
  class << self
    def call(title:, audience:, server_context:, **opts)
      user = server_context[:user]
      # ... implementation
      MCP::Tool::Response.new([{ type: "text", text: result.to_json }])
    end
  end
end
```

---

## API Authentication

API requests require Bearer token authentication:

```bash
Authorization: Bearer YOUR_API_TOKEN
```

Users can find their API token at `/profile` and regenerate it if needed.

---

## Database Schema (Key Tables)

```sql
-- Core content
insight_items (id, user_id, title, slug, description, audience, status, entry_file, metadata, published_at, share_token, share_enabled)
insight_item_files (id, insight_item_id, filename, content, content_type)

-- Users & Auth
users (id, email_address, password_digest, name, api_token, admin, theme)
sessions (id, user_id, ip_address, user_agent)
invites (id, token, email, created_by_id, used_by_id, expires_at, used_at)

-- Waitlist
waitlist_entries (id, email)

-- Collaboration
comments (id, body, parent_id, commentable_type, commentable_id)
engagements (id, insight_item_id, user_id, engageable_type, engageable_id)

-- MCP (action_mcp_* tables for session management)
```

---

## Key Patterns & Conventions

### 1. Authentication
- Uses Rails 8 built-in authentication via `Authentication` concern
- `Current.user` available via `current.rb` model
- API uses token auth, web uses session auth

### 2. Authorization
- Owners can edit/delete their own insights
- Published insights visible to all authenticated users
- Draft insights only visible to owner
- Admin-only: user/invite management

### 3. Slug-based URLs
- InsightItems use `slug` as param (`to_param` override)
- Find by: `InsightItem.find_by!(slug: params[:id])`

### 4. Real-time Updates
- `InsightItemsChannel` broadcasts when insights are published
- `live_updates_controller.js` handles client-side updates

### 5. File Serving
- Insight files served via iframe
- `InsightItemFilesController#show` renders raw content
- Supports HTML, CSS, JS, Markdown

### 6. DaisyUI Components
- Custom theme: `insaight` (see `StyleGuide.md`)
- Badges for audience: `badge-primary` (developer), `badge-secondary` (stakeholder), `badge-accent` (end_user)
- Uses: cards, modals, drawers, toasts

### 7. Pagination
- Uses Pagy gem (version 8.x)
- Include `Pagy::Backend` in controllers
- Include `Pagy::Frontend` in helpers

---

## Common Development Tasks

### Run the app
```bash
bin/dev
```

### Run tests
```bash
bin/rails test
bin/rails test:system
```

### Access console
```bash
bin/rails console
```

### Create admin user (seeds)
```bash
bin/rails db:seed
# Creates: admin@example.com / admin
```

### Generate API token for existing user
```ruby
user.regenerate_api_token!
```

### Publish an insight
```ruby
insight = InsightItem.find_by(slug: "my-insight")
insight.publish!
```

---

## Key Files to Read First

1. `app/models/insight_item.rb` - Core domain model
2. `app/controllers/insight_items_controller.rb` - Main CRUD logic
3. `config/routes.rb` - All available endpoints
4. `app/tools/create_insight_tool.rb` - MCP tool pattern example
5. `docs/API.md` - REST API reference
6. `StyleGuide.md` - UI/UX conventions
