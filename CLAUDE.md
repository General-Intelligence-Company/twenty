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

## CI/CD Pipeline

The repository uses GitHub Actions with 25+ workflows. Key CI pipelines to be aware of:

- **ci-front.yaml** - Frontend: lint, typecheck, test, Storybook build/test, E2E (Playwright), Chromatic
- **ci-server.yaml** - Backend: lint, typecheck, build, unit test, integration tests (8 shards), migration check
- **ci-shared.yaml** - Shared package: lint, typecheck, test
- **ci-format.yaml** - Prettier format check across all major packages
- **ci-breaking-changes.yaml** - GraphQL + OpenAPI breaking change detection
- **security.yaml** - CodeQL analysis + dependency review

### Pre-commit Hooks

Husky runs `lint-staged` on every commit:

- TypeScript/JavaScript files: `eslint --fix` then `prettier --write`
- JSON/Markdown/YAML files: `prettier --write`

### Custom GitHub Actions

Located in `.github/actions/`:

- `yarn-install` - Cached Node.js setup and dependency installation
- `nx-affected` - Runs Nx affected commands scoped by tag
- `restore-cache` / `save-cache` - Nx task cache management

## Troubleshooting

### Common Issues

**Lint errors after code changes:**

```bash
# Auto-fix lint issues on changed files (fastest)
npx nx lint:diff-with-main twenty-front --configuration=fix
# Or fix all files in a package
npx nx lint twenty-front --fix
```

**Prettier format failures:**

```bash
# Check formatting (what CI runs)
npx nx fmt twenty-front
# Fix formatting
npx nx fmt twenty-front --configuration=fix
```

**TypeScript errors with `tsgo`:**
The project uses `tsgo` (native TypeScript) for type checking. If `tsgo` is not available, check your Node.js version matches `.nvmrc` (Node 24.5.0).

**Nx cache issues:**

```bash
# Clear Nx cache
npx nx reset
```

**Module boundary violations:**
The Nx workspace enforces strict scope boundaries. Check `nx.json` for `@nx/enforce-module-boundaries` rules:

- `scope:frontend` can only import from `scope:frontend` and `scope:shared`
- `scope:backend` can only import from `scope:backend` and `scope:shared`
- `scope:shared` can only import from `scope:shared`

**Database migration errors:**

```bash
# Reset the database entirely
npx nx database:reset twenty-server
# Re-sync metadata
npx nx run twenty-server:command workspace:sync-metadata
```

## Important Files

- `nx.json` - Nx workspace configuration with task definitions
- `tsconfig.base.json` - Base TypeScript configuration
- `eslint.config.mjs` - Root ESLint flat config (v9)
- `package.json` - Root package with workspace definitions, Prettier config, lint-staged config
- `.husky/pre-commit` - Pre-commit hook running lint-staged
- `.github/workflows/` - CI/CD workflow definitions (25+ files)
- `.github/actions/` - Custom composite GitHub Actions
- `.cursor/rules/` - Development guidelines and best practices
- `AGENTS.md` - AI agent guidelines with code review checklist
