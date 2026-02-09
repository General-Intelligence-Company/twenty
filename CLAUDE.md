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

## CI/CD Pipeline

### CI Workflows (triggered on PRs and merge groups)

| Workflow            | File                       | What it checks                                                                                        |
| ------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------- |
| CI Front and E2E    | `ci-front.yaml`            | Lint, typecheck, test, build frontend; Storybook build/test (sharded); coverage; E2E with Playwright  |
| CI Server           | `ci-server.yaml`           | Lint, typecheck, build server; unit tests; integration tests (sharded) with Postgres/Redis/ClickHouse |
| CI Format           | `ci-format.yaml`           | Prettier format check on all affected packages                                                        |
| CI Shared           | `ci-shared.yaml`           | Lint, typecheck, test for twenty-shared                                                               |
| CI SDK              | `ci-sdk.yaml`              | Lint, typecheck, unit test for twenty-sdk                                                             |
| CI Docs             | `ci-docs.yaml`             | ESLint for MDX documentation files                                                                    |
| CI Breaking Changes | `ci-breaking-changes.yaml` | GraphQL and OpenAPI breaking changes detection                                                        |
| Security Scan       | `security.yaml`            | CodeQL analysis (JS/TS); Dependency Review (fail on high severity)                                    |

### Pre-commit Hooks

Husky + lint-staged runs on every commit:

- `*.{ts,tsx,js,jsx}` → `eslint --fix` + `prettier --write`
- `*.{json,md,mdx,yml,yaml}` → `prettier --write`

### Recommended Pre-PR Checklist

```bash
# 1. Lint changed files (fastest)
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
```

## Development Workflow

IMPORTANT: Use Context7 for code generation, setup or configuration steps, or library/API documentation. Automatically use the Context7 MCP tools to resolve library IDs and get library docs without waiting for explicit requests.

### Before Making Changes

1. Always run linting and type checking after code changes
2. Run `npx nx fmt <package>` to verify formatting
3. Test changes with relevant test suites
4. Ensure database migrations are properly structured
5. Check that GraphQL schema changes are backward compatible

### Code Style Notes

- Use **Emotion** for styling with styled-components pattern
- Follow **Nx** workspace conventions for imports
- Use **Lingui** for internationalization
- Components should be in their own directories with tests and stories

### Linting Configuration

- **ESLint v9** flat config at `eslint.config.mjs` with 16 custom rules in `packages/twenty-eslint-rules/`
- **Prettier** configured in `package.json` (singleQuote, trailingComma: all, endOfLine: lf)
- Per-package ESLint configs extend the root with additional rules (e.g., `no-explicit-any: error` in backend)

### Testing Strategy

- **Unit tests** with Jest for both frontend and backend
- **Integration tests** for critical backend workflows
- **Storybook** for component development and testing
- **E2E tests** with Playwright for critical user flows

## Important Files

- `nx.json` - Nx workspace configuration with task definitions
- `tsconfig.base.json` - Base TypeScript configuration
- `package.json` - Root package with workspace definitions
- `eslint.config.mjs` - Root ESLint configuration (flat config)
- `.husky/pre-commit` - Pre-commit hook (runs lint-staged)
- `.cursor/rules/` - Development guidelines and best practices
