# DigestHub

A report publishing and management platform built with Ruby on Rails 8. DigestHub enables teams to create, organize, and share reports with different audiences through a clean web interface and REST API.

## Features

- **Report Management**: Create, edit, and publish reports with multiple file attachments (HTML, CSS, JavaScript)
- **Audience Targeting**: Tag reports for developers, stakeholders, or end users
- **Invite-Only Registration**: Secure user onboarding via invite tokens
- **REST API**: Full API access with token authentication for programmatic report management
- **Real-time Updates**: ActionCable-powered live updates when new reports are published
- **Search & Filtering**: Find reports by query, audience type, or tags
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

## Configuration

### Environment Variables

Create a `.env` file for local development with any necessary environment variables. The application uses Rails encrypted credentials for sensitive configuration.

### Database

DigestHub uses SQLite by default. Database configuration is in `config/database.yml`.

For production, consider using PostgreSQL or MySQL by updating the Gemfile and database configuration.

## API Usage

DigestHub provides a REST API at `/api/v1/` for programmatic access.

### Authentication

All API requests require an API token passed in the `Authorization` header:

```bash
Authorization: Bearer YOUR_API_TOKEN
```

Users can view and regenerate their API token from their profile page.

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/reports` | List all reports |
| GET | `/api/v1/reports/:id` | Get a specific report |
| POST | `/api/v1/reports` | Create a new report |
| PATCH | `/api/v1/reports/:id` | Update a report |
| DELETE | `/api/v1/reports/:id` | Delete a report |
| GET | `/api/v1/tags` | List all available tags |
| GET | `/api/v1/me` | Get current user info |

### Example: Create a Report

```bash
curl -X POST http://localhost:3000/api/v1/reports \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "report": {
      "title": "Monthly Summary",
      "description": "Overview of monthly metrics",
      "audience": "stakeholder",
      "status": "draft"
    }
  }'
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

DigestHub includes configuration for Docker and Kamal deployment.

### Docker

Build and run with Docker:

```bash
docker build -t digest_hub .
docker run -p 3000:3000 digest_hub
```

### Docker Compose

```bash
docker-compose up
```

### Kamal

For production deployment with Kamal, configure your servers in `config/deploy.yml` and run:

```bash
kamal setup
kamal deploy
```

## Architecture

```
app/
├── controllers/
│   ├── api/v1/          # API controllers
│   ├── admin/           # Admin panel controllers
│   └── ...              # Web controllers
├── models/
│   ├── user.rb          # User authentication and API tokens
│   ├── report.rb        # Core report model
│   ├── report_file.rb   # File attachments for reports
│   ├── invite.rb        # Invite token management
│   └── session.rb       # Session management
├── views/               # ERB templates
├── channels/            # ActionCable channels
└── jobs/                # Background jobs (Solid Queue)
```

## License

[Add your license here]

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
