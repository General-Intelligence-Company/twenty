# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Twenty is an open-source CRM built with modern technologies in a monorepo structure. The codebase is organized as an Nx workspace with multiple packages.

## Key Commands

### Development
```bash
# Start development environment (frontend + backend + worker)
yarn start

# Individual package development
npx nx start twenty-front     # Start frontend dev server
npx nx start twenty-server    # Start backend server
npx nx run twenty-server:worker  # Start background worker
```

### Testing
```bash
# Run tests
npx nx test twenty-front      # Frontend unit tests
npx nx test twenty-server     # Backend unit tests
npx nx run twenty-server:test:integration:with-db-reset  # Integration tests with DB reset

# Storybook
npx nx storybook:build twenty-front         # Build Storybook
npx nx storybook:test twenty-front     # Run Storybook tests


When testing the UI end to end, click on "Continue with Email" and use the prefilled credentials.
```

### Code Quality
```bash
# Linting (diff with main - fastest)
npx nx lint:diff-with-main twenty-front           # Lint only files changed vs main
npx nx lint:diff-with-main twenty-server          # Lint only files changed vs main
npx nx lint:diff-with-main twenty-front --configuration=fix  # Auto-fix files changed vs main

# Linting (full project)
npx nx lint twenty-front      # Lint all files in frontend
npx nx lint twenty-server     # Lint all files in backend
npx nx lint twenty-front --fix  # Auto-fix all linting issues

# Type checking
npx nx typecheck twenty-front
npx nx typecheck twenty-server

# Format code
npx nx fmt twenty-front
npx nx fmt twenty-server
```

### Build
```bash
# Build packages
npx nx build twenty-front
npx nx build twenty-server
```

### Database Operations
```bash
# Database management
npx nx database:reset twenty-server         # Reset database
npx nx run twenty-server:database:init:prod # Initialize database
npx nx run twenty-server:database:migrate:prod # Run migrations

# Generate migration
npx nx run twenty-server:typeorm migration:generate src/database/typeorm/core/migrations/common/[name] -d src/database/typeorm/core/core.datasource.ts

# Sync metadata
npx nx run twenty-server:command workspace:sync-metadata
```

### GraphQL
```bash
# Generate GraphQL types
npx nx run twenty-front:graphql:generate
```

## Architecture Overview

### Tech Stack
- **Frontend**: React 18, TypeScript, Recoil (state management), Emotion (styling), Vite
- **Backend**: NestJS, TypeORM, PostgreSQL, Redis, GraphQL (with GraphQL Yoga)
- **Monorepo**: Nx workspace managed with Yarn 4

### Package Structure
```
packages/
├── twenty-front/          # React frontend application
├── twenty-server/         # NestJS backend API
├── twenty-ui/             # Shared UI components library
├── twenty-shared/         # Common types and utilities
├── twenty-emails/         # Email templates with React Email
├── twenty-website/        # Next.js documentation website
├── twenty-zapier/         # Zapier integration
└── twenty-e2e-testing/    # Playwright E2E tests
```

### Key Development Principles
- **Functional components only** (no class components)
- **Named exports only** (no default exports)
- **Types over interfaces** (except when extending third-party interfaces)
- **String literals over enums** (except for GraphQL enums)
- **No 'any' type allowed**
- **Event handlers preferred over useEffect** for state updates

### State Management
- **Recoil** for global state management
- Component-specific state with React hooks
- GraphQL cache managed by Apollo Client

### Backend Architecture
- **NestJS modules** for feature organization
- **TypeORM** for database ORM with PostgreSQL
- **GraphQL** API with code-first approach
- **Redis** for caching and session management
- **BullMQ** for background job processing

### Database
- **PostgreSQL** as primary database
- **Redis** for caching and sessions
- **TypeORM migrations** for schema management
- **ClickHouse** for analytics (when enabled)

## Development Workflow

IMPORTANT: Use Context7 for code generation, setup or configuration steps, or library/API documentation. Automatically use the Context7 MCP tools to resolve library IDs and get library docs without waiting for explicit requests.

### Before Making Changes
1. Always run linting and type checking after code changes
2. Test changes with relevant test suites
3. Ensure database migrations are properly structured
4. Check that GraphQL schema changes are backward compatible

### Code Style Notes
- Use **Emotion** for styling with styled-components pattern
- Follow **Nx** workspace conventions for imports
- Use **Lingui** for internationalization
- Components should be in their own directories with tests and stories

### Testing Strategy
- **Unit tests** with Jest for both frontend and backend
- **Integration tests** for critical backend workflows
- **Storybook** for component development and testing
- **E2E tests** with Playwright for critical user flows

## Important Files
- `nx.json` - Nx workspace configuration with task definitions
- `tsconfig.base.json` - Base TypeScript configuration
- `package.json` - Root package with workspace definitions
- `.cursor/rules/` - Development guidelines and best practices

## CI/CD Pipeline Overview

The repository uses GitHub Actions for continuous integration. All workflows are located in `.github/workflows/`.

### CI Workflows

| Workflow | File | Trigger | What It Checks |
|----------|------|---------|----------------|
| CI Front and E2E | `ci-front.yaml` | PR, merge_group | Frontend lint, typecheck, test, Storybook build/test, E2E tests |
| CI Server | `ci-server.yaml` | PR, merge_group | Backend lint, typecheck, unit tests, integration tests, DB migrations |
| CI Shared | `ci-shared.yaml` | PR, merge_group | Shared package lint, typecheck, tests |
| CI SDK | `ci-sdk.yaml` | PR, merge_group | SDK lint, typecheck, unit tests |
| CI Utils | `ci-utils.yaml` | PR (target) | Danger.js PR checks, congratulation messages |
| CI Docs | `ci-docs.yaml` | PR, push to main | MDX documentation linting |
| CI Website | `ci-website.yaml` | PR, merge_group | Website build validation |
| CI Emails | `ci-emails.yaml` | PR, push to main | Email template build and server test |
| CI Create App | `ci-create-app.yaml` | PR, push to main | create-twenty-app lint, typecheck, tests |
| CI Docker Compose | `ci-test-docker-compose.yaml` | PR, merge_group | Docker compose build and startup test |
| CI Breaking Changes | `ci-breaking-changes.yaml` | PR to main | GraphQL and OpenAPI breaking change detection |
| CI Format | `ci-format.yaml` | PR, merge_group | Prettier format checking for frontend and backend |
| Security Scan | `security.yaml` | PR, push to main, weekly | CodeQL analysis, dependency review |
| Preview Env Dispatch | `preview-env-dispatch.yaml` | PR (labeled) | Triggers Render preview environment |

### CD Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| CD Deploy Main | `cd-deploy-main.yaml` | Push to main | Deploy main branch to staging |
| CD Deploy Tag | `cd-deploy-tag.yaml` | Tag `v*` | Deploy tagged releases to production |

### Reusable Workflows

| Workflow | File | Purpose |
|----------|------|---------|
| Changed Files | `changed-files.yaml` | Detect changed files to skip unnecessary CI jobs |

## Pre-commit Hooks

The repository uses **Husky v9** with **lint-staged** for pre-commit hooks.

### What Runs on Commit

```bash
# Configured in package.json under "lint-staged"
*.{ts,tsx,js,jsx}  → eslint --fix && prettier --write
*.{json,md,mdx,yml,yaml} → prettier --write
```

### Setup
```bash
# Husky is automatically set up after yarn install
# To manually install hooks:
npx husky install

# Pre-commit hook location: .husky/pre-commit
# Runs: npx lint-staged
```

## Pre-PR Checklist

Before opening a PR, run these commands to ensure CI will pass:

```bash
# 1. Lint your changes (fastest - only changed files vs main)
npx nx lint:diff-with-main twenty-front
npx nx lint:diff-with-main twenty-server

# 2. Type check
npx nx typecheck twenty-front
npx nx typecheck twenty-server

# 3. Format check
npx nx fmt twenty-front
npx nx fmt twenty-server

# 4. Run tests
npx nx test twenty-front
npx nx test twenty-server

# 5. For backend changes, run integration tests
npx nx run twenty-server:test:integration:with-db-reset
```

### Quick Commands
```bash
# Fix all linting issues automatically
npx nx lint:diff-with-main twenty-front --configuration=fix
npx nx lint:diff-with-main twenty-server --configuration=fix

# Run all checks for a package
npx nx run-many -t lint,typecheck,test -p twenty-front
```

## Custom ESLint Rules

The repository includes 16 custom ESLint rules in `packages/twenty-eslint-rules/`. These enforce Twenty-specific coding standards.

### Rule Categories

**React & State Management:**
| Rule | Purpose |
|------|---------|
| `component-props-naming` | Enforces consistent prop type naming (e.g., `ComponentNameProps`) |
| `effect-components` | Ensures Effect components follow naming conventions |
| `matching-state-variable` | Enforces state variable names match their Recoil atom names |
| `no-state-useref` | Prevents using useRef for state that should use useState |
| `use-getLoadable-and-getValue-to-get-atoms` | Enforces correct Recoil atom access patterns |
| `useRecoilCallback-has-dependency-array` | Ensures useRecoilCallback has proper dependencies |

**Styling & UI:**
| Rule | Purpose |
|------|---------|
| `no-hardcoded-colors` | Prevents hardcoded colors; use theme variables |
| `sort-css-properties-alphabetically` | Enforces alphabetical CSS property ordering |
| `styled-components-prefixed-with-styled` | Requires `Styled` prefix for styled components |

**Code Quality:**
| Rule | Purpose |
|------|---------|
| `explicit-boolean-predicates-in-if` | Requires explicit boolean checks in if statements |
| `max-consts-per-file` | Limits constants per file for maintainability |
| `no-navigate-prefer-link` | Prefers `<Link>` over `useNavigate` for navigation |

**Security & Backend:**
| Rule | Purpose |
|------|---------|
| `graphql-resolvers-should-be-guarded` | Ensures GraphQL resolvers have auth guards |
| `rest-api-methods-should-be-guarded` | Ensures REST endpoints have auth guards |
| `inject-workspace-repository` | Enforces proper repository injection patterns |

**Documentation:**
| Rule | Purpose |
|------|---------|
| `mdx-component-newlines` | Enforces proper newlines in MDX components |
| `no-angle-bracket-placeholders` | Prevents `<placeholder>` patterns in docs |

## Testing Guide

### Unit Tests

**Frontend (Jest with jsdom)**
```bash
# Run all frontend tests
npx nx test twenty-front

# Run specific test file
npx jest path/to/file.test.ts --config=packages/twenty-front/jest.config.mjs

# Run with coverage
npx nx test twenty-front --coverage
```

**Backend (Jest with node)**
```bash
# Run all backend tests
npx nx test twenty-server

# Run specific test file
npx jest path/to/file.spec.ts --config=packages/twenty-server/jest.config.mjs
```

### Integration Tests

```bash
# Run integration tests with database reset
npx nx run twenty-server:test:integration:with-db-reset

# Run specific integration test shard (used in CI)
npx nx run twenty-server:test:integration:with-db-reset --shard=1/8
```

### E2E Tests (Playwright)

```bash
# Install Playwright browsers
npx nx setup twenty-e2e-testing

# Run E2E tests
npx nx test twenty-e2e-testing

# E2E tests require running frontend and backend servers
# See ci-front.yaml for the full setup
```

### Storybook Tests

```bash
# Build Storybook
npx nx storybook:build twenty-front

# Run Storybook tests (requires built Storybook)
npx nx storybook:test twenty-front

# Run with coverage
npx nx storybook:coverage twenty-front --checkCoverage=true

# Run specific scope
npx nx storybook:test twenty-front --configuration=modules
npx nx storybook:test twenty-front --configuration=pages
npx nx storybook:test twenty-front --configuration=performance
```

### Test File Conventions
- **Frontend**: `*.test.ts` or `*.test.tsx`
- **Backend**: `*.spec.ts`
- **E2E**: Located in `packages/twenty-e2e-testing/`

## Deployment Architecture

### Render Services

The production deployment uses Render with the following services:

| Service | Type | Purpose |
|---------|------|---------|
| `twenty-server` | Web Service | NestJS API server (GraphQL + REST) |
| `twenty-worker` | Background Worker | BullMQ job processor |
| `twenty-redis` | Redis | Caching, sessions, job queue |
| `twenty-postgres` | PostgreSQL | Primary database |

### Docker Deployment

For self-hosted deployments, use the Docker setup:

```bash
# Using docker-compose
cd packages/twenty-docker
cp .env.example .env
# Edit .env with your configuration
docker compose up -d
```

**Docker Images:**
- `twentycrm/twenty` - Main application image
- `twentycrm/twenty-postgres-spilo` - PostgreSQL with extensions

### Environment Variables

Key environment variables for deployment:

```bash
# Database
PG_DATABASE_URL=postgres://user:pass@host:5432/twenty

# Redis
REDIS_URL=redis://host:6379

# Server
NODE_PORT=3000
APP_SECRET=your-secret-key

# Optional: Analytics
CLICKHOUSE_URL=http://host:8123/twenty
ANALYTICS_ENABLED=true
```

### Preview Environments

PRs labeled with `preview-app` trigger Render preview environments automatically via `preview-env-dispatch.yaml`.
