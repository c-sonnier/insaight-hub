# insAIght Hub

> Because understanding beats output.

A platform for managing and sharing AI-generated insights, built with Ruby on Rails 8. insAIght Hub turns scattered AI output into shared understanding — structured, searchable, and easy to act on.

## Features

- **Insight Management**: Create, edit, and publish insights with multiple file attachments (HTML, CSS, JavaScript)
- **Audience Targeting**: Tag insights for developers, stakeholders, or end users
- **Invite-Only Registration**: Secure user onboarding via invite tokens
- **REST API**: Full API access with token authentication for programmatic insight management
- **Real-time Updates**: ActionCable-powered live updates when new insights are published
- **Search & Filtering**: Find insights by query, audience type, or tags
- **Theme Support**: Multiple DaisyUI themes (light, dark, corporate, etc.)
- **Admin Panel**: Manage users and invites

## Requirements

- Ruby 3.4.5
- Rails 8.0.3
- SQLite 3
- Node.js (for asset compilation)

## Getting Started

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd digest_hub
   ```

2. Install Ruby dependencies:
   ```bash
   bundle install
   ```

3. Install JavaScript dependencies:
   ```bash
   npm install
   ```

4. Set up the database:
   ```bash
   bin/rails db:create db:migrate db:seed
   ```

5. Set up credentials (if needed):
   ```bash
   bin/rails credentials:edit
   ```

### Running the Application

Start the development server:
```bash
bin/dev
```

This runs the Rails server with Tailwind CSS watching for changes.

The application will be available at `http://localhost:3000`.

### Default Credentials

After seeding the database, you can log in with:
- **Email**: admin@example.com
- **Password**: admin

## Configuration

### Environment Variables

Copy `.env.example` to `.env` for local development:

```bash
cp .env.example .env
```

| Variable | Description | Required |
|----------|-------------|----------|
| `SECRET_KEY_BASE` | Rails secret key (generate with `bin/rails secret`) | Yes (production) |
| `RAILS_MASTER_KEY` | Master key for encrypted credentials | Yes (production) |
| `RAILS_ENV` | Environment (development/production) | Yes |

### Database

insAIght Hub uses SQLite by default. Database configuration is in `config/database.yml`.

## API Documentation

insAIght Hub provides a REST API at `/api/v1/` for programmatic access.

### Authentication

All API requests require an API token passed in the `Authorization` header:

```bash
Authorization: Bearer YOUR_API_TOKEN
```

Users can view and regenerate their API token from their profile page at `/profile`.

Unauthenticated requests return:
```json
{
  "error": "Unauthorized",
  "message": "Invalid or missing API token"
}
```

### Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/me` | Get current user info |
| GET | `/api/v1/insight_items` | List insights |
| GET | `/api/v1/insight_items/:id` | Get a specific insight with files |
| POST | `/api/v1/insight_items` | Create a new insight |
| PATCH | `/api/v1/insight_items/:id` | Update an insight |
| DELETE | `/api/v1/insight_items/:id` | Delete an insight |
| POST | `/api/v1/insight_items/:id/publish` | Publish an insight |
| POST | `/api/v1/insight_items/:id/unpublish` | Unpublish an insight |
| DELETE | `/api/v1/insight_items/:id/files/:filename` | Delete a file from an insight |
| GET | `/api/v1/tags` | List all available tags |

---

### GET /api/v1/me

Returns current user information.

**Response (200)**:
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "admin": false,
    "theme": "dark",
    "created_at": "2024-12-29T12:00:00Z"
  }
}
```

---

### GET /api/v1/insight_items

List insights with optional filtering and pagination.

**Query Parameters**:
| Parameter | Description | Default |
|-----------|-------------|---------|
| `status` | Filter by status (`draft`, `published`) | `published` |
| `audience` | Filter by audience (`developer`, `stakeholder`, `end_user`) | - |
| `tag` | Filter by tag | - |
| `search` | Search title/description | - |
| `page` | Page number | 1 |
| `per_page` | Items per page (max: 100) | 20 |

**Response (200)**:
```json
{
  "insight_items": [
    {
      "id": 1,
      "title": "API Documentation",
      "slug": "api-documentation",
      "description": "Complete API docs",
      "audience": "developer",
      "status": "published",
      "tags": ["api", "docs"],
      "entry_file": "index.html",
      "file_count": 3,
      "author": {
        "id": 1,
        "name": "John Doe"
      },
      "published_at": "2024-12-29T12:00:00Z",
      "created_at": "2024-12-29T11:00:00Z",
      "updated_at": "2024-12-29T12:00:00Z",
      "url": "/insight_items/api-documentation"
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 42,
    "per_page": 20
  }
}
```

---

### GET /api/v1/insight_items/:id

Get a single insight with its files.

**Response (200)**:
```json
{
  "insight_item": {
    "id": 1,
    "title": "API Documentation",
    "slug": "api-documentation",
    "description": "Complete API docs",
    "audience": "developer",
    "status": "published",
    "tags": ["api", "docs"],
    "entry_file": "index.html",
    "author": {
      "id": 1,
      "name": "John Doe"
    },
    "files": [
      {
        "id": 1,
        "filename": "index.html",
        "content_type": "text/html",
        "url": "/insight_items/api-documentation/files/index.html"
      }
    ],
    "published_at": "2024-12-29T12:00:00Z",
    "created_at": "2024-12-29T11:00:00Z",
    "updated_at": "2024-12-29T12:00:00Z",
    "url": "/insight_items/api-documentation"
  }
}
```

---

### POST /api/v1/insight_items

Create a new insight. Supports single-file or multi-file creation.

**Request Body (Single File)**:
```json
{
  "title": "Sprint Summary",
  "slug": "sprint-42-summary",
  "description": "Key outcomes from sprint 42",
  "audience": "stakeholder",
  "tags": ["sprint", "summary"],
  "content": "<!DOCTYPE html><html>...</html>"
}
```

**Request Body (Multi-File)**:
```json
{
  "title": "Test Mode Documentation",
  "slug": "test-mode-docs",
  "description": "Complete documentation for test mode feature",
  "audience": "developer",
  "tags": ["documentation", "testing"],
  "entry_file": "index.html",
  "files": [
    {"filename": "index.html", "content": "<!DOCTYPE html>..."},
    {"filename": "architecture.html", "content": "<!DOCTYPE html>..."}
  ]
}
```

**Notes**:
- If `content` is provided (single file), a file is created with filename "index.html"
- If `files` is provided (multi-file), files are created for each entry
- `slug` is optional; auto-generated from title if not provided
- `entry_file` defaults to "index.html"
- New insights default to `status: draft`

**Response (201)**: Returns the created insight

**Response (422 - Validation Error)**:
```json
{
  "error": "Validation failed",
  "messages": {
    "title": ["can't be blank"],
    "slug": ["has already been taken"]
  }
}
```

---

### PATCH /api/v1/insight_items/:id

Update an insight.

**Request Body**:
```json
{
  "title": "Updated Title",
  "description": "Updated description",
  "tags": ["new", "tags"],
  "files": [
    {"filename": "new-page.html", "content": "<!DOCTYPE html>..."}
  ]
}
```

**Notes**:
- Files are merged/upserted by filename
- To delete a file, use the separate delete file endpoint

**Response (200)**: Returns the updated insight

---

### DELETE /api/v1/insight_items/:id

Delete an insight and all its files.

**Response (204)**: No content

---

### POST /api/v1/insight_items/:id/publish

Publish a draft insight.

**Response (200)**:
```json
{
  "insight_item": {
    "status": "published",
    "published_at": "2024-12-29T12:00:00Z"
  }
}
```

---

### POST /api/v1/insight_items/:id/unpublish

Unpublish a published insight.

**Response (200)**:
```json
{
  "insight_item": {
    "status": "draft",
    "published_at": null
  }
}
```

---

### DELETE /api/v1/insight_items/:id/files/:filename

Delete a file from an insight.

**Response (204)**: No content

**Response (422)**: Cannot delete the last file

---

### GET /api/v1/tags

List all unique tags used across insights.

**Response (200)**:
```json
{
  "tags": ["api", "documentation", "sprint", "testing"]
}
```

---

### Example: Create and Publish an Insight

```bash
# Create an insight
curl -X POST http://localhost:3000/api/v1/insight_items \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Monthly Summary",
    "description": "Overview of monthly metrics",
    "audience": "stakeholder",
    "tags": ["monthly", "metrics"],
    "content": "<!DOCTYPE html><html><body><h1>Monthly Summary</h1></body></html>"
  }'

# Publish the insight (replace :id with the insight ID)
curl -X POST http://localhost:3000/api/v1/insight_items/:id/publish \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

## Testing

Run the test suite:

```bash
bin/rails test
```

Run system tests:

```bash
bin/rails test:system
```

## Code Quality

Run RuboCop for Ruby linting:

```bash
bundle exec rubocop
```

Run Brakeman for security analysis:

```bash
bundle exec brakeman
```

## Deployment

### Docker

Build and run with Docker:

```bash
# Build the image
docker build -t insaight_hub .

# Run the container
docker run -d -p 80:80 \
  -e RAILS_MASTER_KEY=<value from config/master.key> \
  -e SECRET_KEY_BASE=$(bin/rails secret) \
  --name insaight_hub \
  insaight_hub
```

### Docker Compose

1. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

2. Fill in the required values in `.env`:
   ```bash
   RAILS_MASTER_KEY=<value from config/master.key>
   SECRET_KEY_BASE=$(bin/rails secret)
   ```

3. Start the services:
   ```bash
   docker-compose up -d
   ```

The application will be available at `http://localhost:3000`.

Health check endpoint: `GET /health` returns `200 OK`

### Kamal

For production deployment with Kamal, configure your servers in `config/deploy.yml` and run:

```bash
kamal setup
kamal deploy
```

## Architecture

```
app/
├── channels/
│   ├── application_cable/
│   │   ├── channel.rb
│   │   └── connection.rb
│   └── insight_items_channel.rb  # Real-time insight updates
├── controllers/
│   ├── api/v1/                   # API controllers
│   │   ├── base_controller.rb
│   │   ├── me_controller.rb
│   │   ├── insight_items_controller.rb
│   │   └── tags_controller.rb
│   ├── admin/                    # Admin panel controllers
│   │   ├── base_controller.rb
│   │   ├── invites_controller.rb
│   │   └── users_controller.rb
│   ├── home_controller.rb        # Dashboard
│   ├── profiles_controller.rb    # User profile
│   ├── registrations_controller.rb
│   ├── insight_items_controller.rb   # Insight CRUD
│   └── insight_item_files_controller.rb
├── models/
│   ├── user.rb                   # User authentication and API tokens
│   ├── insight_item.rb           # Core insight model
│   ├── insight_item_file.rb      # File attachments for insights
│   ├── invite.rb                 # Invite token management
│   └── session.rb                # Session management
├── views/                        # ERB templates with DaisyUI
├── javascript/controllers/       # Stimulus controllers
│   ├── theme_controller.js
│   ├── insight_form_controller.js
│   ├── insight_view_controller.js
│   ├── live_updates_controller.js
│   └── fullscreen_controller.js
└── jobs/                         # Background jobs (Solid Queue)
```

## License

[Add your license here]

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
