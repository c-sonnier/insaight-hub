# insAIght Hub API Documentation

Full REST API documentation for programmatic access to insAIght Hub.

## Authentication

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

## Endpoints Summary

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

## GET /api/v1/me

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

## GET /api/v1/insight_items

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

## GET /api/v1/insight_items/:id

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

## POST /api/v1/insight_items

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

## PATCH /api/v1/insight_items/:id

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

## DELETE /api/v1/insight_items/:id

Delete an insight and all its files.

**Response (204)**: No content

---

## POST /api/v1/insight_items/:id/publish

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

## POST /api/v1/insight_items/:id/unpublish

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

## DELETE /api/v1/insight_items/:id/files/:filename

Delete a file from an insight.

**Response (204)**: No content

**Response (422)**: Cannot delete the last file

---

## GET /api/v1/tags

List all unique tags used across insights.

**Response (200)**:
```json
{
  "tags": ["api", "documentation", "sprint", "testing"]
}
```

---

## Example: Create and Publish an Insight

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
