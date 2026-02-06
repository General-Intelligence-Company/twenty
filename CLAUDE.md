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

## CI/CD & Code Quality Infrastructure

### CI/CD Pipelines (GitHub Actions)

The repository has comprehensive CI/CD coverage with 24 workflows:

| Workflow         | File                          | What It Checks                                                                            |
| ---------------- | ----------------------------- | ----------------------------------------------------------------------------------------- |
| CI Front & E2E   | `ci-front.yaml`               | ESLint, typecheck, unit tests, build, Storybook (sharded), Playwright E2E                 |
| CI Server        | `ci-server.yaml`              | ESLint, typecheck, build, DB init, migration check, GraphQL gen, unit + integration tests |
| CI Shared        | `ci-shared.yaml`              | Lint, typecheck, unit tests for shared packages                                           |
| Breaking Changes | `ci-breaking-changes.yaml`    | GraphQL + OpenAPI schema diff, posts PR comments                                          |
| Security         | `security.yaml`               | CodeQL analysis, dependency review (fail on high severity)                                |
| Docker           | `ci-test-docker-compose.yaml` | Docker compose build and startup verification                                             |

Additional per-package CI: `ci-emails`, `ci-docs`, `ci-sdk`, `ci-utils`, `ci-website`, `ci-create-app`

### Pre-commit Hooks

Husky + lint-staged runs on every commit:

- **TypeScript/JavaScript files** (`.ts`, `.tsx`, `.js`, `.jsx`): `eslint --fix` + `prettier --write`
- **Data/doc files** (`.json`, `.md`, `.mdx`, `.yml`, `.yaml`): `prettier --write`

### ESLint Configuration

Uses ESLint 9 flat config (`eslint.config.mjs`) with:

- `@typescript-eslint` for TypeScript rules
- `eslint-plugin-prettier` for formatting enforcement
- `eslint-plugin-import` for import ordering
- `eslint-plugin-unused-imports` for unused import detection
- `eslint-plugin-lingui` for i18n compliance
- `@nx/eslint-plugin` for module boundary enforcement
- 16 custom rules in `packages/twenty-eslint-rules/`

### Custom ESLint Rules (`packages/twenty-eslint-rules/`)

| Rule                                     | Purpose                                               |
| ---------------------------------------- | ----------------------------------------------------- |
| `graphql-resolvers-should-be-guarded`    | Security: all GraphQL resolvers must have auth guards |
| `rest-api-methods-should-be-guarded`     | Security: all REST endpoints must have auth guards    |
| `component-props-naming`                 | Enforce Props suffix naming convention                |
| `no-hardcoded-colors`                    | Enforce theme color usage                             |
| `sort-css-properties-alphabetically`     | CSS property ordering                                 |
| `styled-components-prefixed-with-styled` | Styled component naming                               |
| `matching-state-variable`                | State variable naming consistency                     |
| `explicit-boolean-predicates-in-if`      | Require explicit boolean checks                       |

### Code Quality Tools

- **DangerJS** (`packages/twenty-utils/dangerfile.ts`): Automated PR checks for lock file sync, env changes, CLA, TODO scanning
- **GraphQL Inspector**: Schema breaking change detection in CI
- **OpenAPI Diff**: REST API breaking change detection in CI
- **Chromatic**: Visual regression testing for Storybook components

### EditorConfig

`.editorconfig` ensures consistent editor settings:

- UTF-8 charset, LF line endings
- 2-space indentation for all file types
- Final newline insertion, trailing whitespace trimming

## Important Files

- `nx.json` - Nx workspace configuration with task definitions
- `tsconfig.base.json` - Base TypeScript configuration
- `package.json` - Root package with workspace definitions
- `eslint.config.mjs` - Root ESLint flat config (ESLint 9)
- `.editorconfig` - Editor settings for consistent formatting
- `.prettierignore` - Prettier ignore patterns
- `.github/CODEOWNERS` - Automatic PR reviewer assignment
- `.cursor/rules/` - Development guidelines and best practices
