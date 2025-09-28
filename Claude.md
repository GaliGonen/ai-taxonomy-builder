# AI Taxonomy Builder

A comprehensive system for cataloging, categorizing, and searching AI use cases across tech company roles and departments.

## Overview

The AI Taxonomy Builder is a web-based application that helps teams discover and explore AI implementation patterns across different roles, departments, and business functions. It features a searchable database of AI use cases with rich metadata and filtering capabilities.

## Architecture

- **Frontend**: HTML/CSS/JavaScript search interface
- **Backend**: n8n workflow automation for API endpoints
- **Database**: PostgreSQL on Render for storing AI use cases
- **Search API**: RESTful API via n8n webhooks

## Key Features

- **Advanced Search**: Filter by role, department, complexity, and keywords
- **Rich Metadata**: Each use case includes implementation complexity, success metrics, and example companies
- **Responsive Design**: Modern UI with gradient styling and mobile-friendly layout
- **API Status Monitoring**: Automatic detection and wake-up of sleeping services
- **Real-time Results**: Dynamic search with instant feedback

## Tech Stack

- **Frontend**: Vanilla HTML/CSS/JavaScript
- **Workflow Engine**: n8n (hosted on Render)
- **Database**: PostgreSQL (Render PostgreSQL service)
- **Hosting**: Static frontend + n8n webhook API
- **Styling**: Custom CSS with gradient themes

## Database Schema

The system uses a PostgreSQL database with tables for:
- AI use case patterns with role/department categorization
- Implementation metadata (complexity, tech stack, metrics)
- Company examples and validation status
- Processing and quality scores

## Search Interface

Located at `frontend/src/search interface.html`, features:
- Multi-field search (keywords, role, department, complexity)
- Dynamic API status checking with wake-up functionality
- Structured result display with metadata tags
- Error handling and loading states

## n8n Workflow

The search API is implemented as an n8n workflow (`n8n-workflows/Search AI Use Cases.json`) that:
1. Receives webhook requests with search parameters
2. Builds dynamic SQL queries based on filters
3. Executes PostgreSQL queries with parameterized values
4. Returns formatted JSON responses with CORS headers

## Environment Configuration

The `.env` file template includes configuration for:
- Database connection (PostgreSQL on Render)
- Azure OpenAI integration
- n8n workflow settings
- API and frontend URLs
- Feature flags and processing options

## API Endpoints

- **GET/POST** `/webhook/search-ai-use-cases` - Search AI use cases with optional filters
- Supports parameters: `keywords`, `role`, `department`, `complexity`
- Returns paginated results with metadata

## Development Setup

1. Clone the repository
2. Configure environment variables based on `.env` template
3. Set up PostgreSQL database using `database/schema.sql`
4. Import n8n workflow from `n8n-workflows/`
5. Deploy n8n instance and configure webhook URLs
6. Host frontend statically or serve locally

## Project Structure

```
ai-taxonomy-builder/
├── frontend/src/          # Search interface
├── n8n-workflows/         # API workflow definitions
├── database/             # Database schema
├── config/               # Configuration files
├── .env                  # Environment variables template
└── Claude.md            # Project documentation
```

## Database Management

### Modifying Existing Records

To update, add, or delete use cases in the database:

1. **Connect using DBeaver (recommended):**
   - Install DBeaver Community Edition (free)
   - Create new PostgreSQL connection:
     - Host: `dpg-d36od98gjchc73cgp9p0-a.oregon-postgres.render.com`
     - Database: `ai_taxonomy`
     - Username: `ai_taxonomy_user`
     - Password: See `config/database_config.md`

2. **Navigate to data:**
   - Expand `ai_taxonomy` → `public` → `Tables`
   - Right-click `use_case_patterns` → "View Data"

3. **Edit records:**
   - Double-click any cell to edit content
   - Use `+` button to add new rows
   - Select rows and press Delete to remove
   - Press `Ctrl+S` (or `Cmd+S`) to save changes

4. **Verify changes:**
   - Open frontend search interface
   - Search for modified content
   - Changes appear immediately (no refresh needed)

### Alternative Access Methods

- **Direct SQL queries:** Use DBeaver's SQL Editor for complex operations
- **Render Admin Apps:** Deploy pgAdmin via Render Dashboard (paid option)
- **Command line:** Connect using `psql` with external database URL

## Commands

- No specific build commands required (static frontend)
- Database initialization: Apply `database/schema.sql`
- n8n deployment: Import workflow JSON files