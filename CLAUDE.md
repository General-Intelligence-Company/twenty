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

## Pre-commit Hooks

The repository uses **Husky** + **lint-staged** for pre-commit checks:

- **TypeScript/JavaScript files** (`.ts`, `.tsx`, `.js`, `.jsx`): ESLint `--fix` + Prettier `--write`
- **Config/doc files** (`.json`, `.md`, `.mdx`, `.yml`, `.yaml`): Prettier `--write`

These run automatically on `git commit`. To skip temporarily: `git commit --no-verify` (not recommended).

## CI/CD Pipeline

### Continuous Integration Workflows

| Workflow          | Trigger                  | What it checks                                                                                                        |
| ----------------- | ------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `ci-front.yaml`   | PR, merge_group          | Frontend lint, typecheck, test, build, Storybook build/test, coverage, E2E                                            |
| `ci-server.yaml`  | PR, merge_group          | Backend lint, typecheck, build, unit tests, integration tests (8 shards), migration checks, GraphQL generation checks |
| `ci-shared.yaml`  | PR, merge_group          | Shared package lint, typecheck, test                                                                                  |
| `ci-sdk.yaml`     | PR, merge_group          | SDK checks                                                                                                            |
| `ci-emails.yaml`  | PR, merge_group          | Email template checks                                                                                                 |
| `ci-docs.yaml`    | PR, merge_group          | Documentation checks                                                                                                  |
| `ci-website.yaml` | PR, merge_group          | Website checks                                                                                                        |
| `ci-utils.yaml`   | PR                       | Danger.js PR checks                                                                                                   |
| `security.yaml`   | PR, push to main, weekly | CodeQL analysis + dependency review                                                                                   |

### Key CI Checks for PRs

- **Frontend**: ESLint, TypeScript type checking, Jest unit tests, Storybook build + visual tests (4 shards), build verification
- **Backend**: ESLint, TypeScript type checking, Jest unit tests, integration tests (8 shards with PostgreSQL + Redis + ClickHouse), pending migration detection, GraphQL schema drift detection
- **Security**: CodeQL static analysis, dependency vulnerability scanning (fails on `high` severity)

### Custom GitHub Actions

- `.github/actions/yarn-install/` - Cached Yarn dependency installation
- `.github/actions/nx-affected/` - Run Nx tasks on affected projects
- `.github/actions/save-cache/` and `.github/actions/restore-cache/` - Build artifact caching

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

### Custom ESLint Rules

The project has its own ESLint rules in `packages/twenty-eslint-rules/`:

- `component-props-naming` - Enforce component prop naming conventions
- `effect-components` - Rules for effect components
- `matching-state-variable` - State variable naming consistency
- `no-hardcoded-colors` - Prevent hardcoded color values (use theme)
- `styled-components-prefixed-with-styled` - Styled component naming convention
- `sort-css-properties-alphabetically` - CSS property ordering
- `no-navigate-prefer-link` - Prefer Link over navigate()
- `no-state-useref` - Prevent state in useRef
- `useRecoilCallback-has-dependency-array` - Ensure Recoil callbacks have deps
- `inject-workspace-repository` - Backend workspace repository injection
- `rest-api-methods-should-be-guarded` - Ensure REST endpoints have guards
- `graphql-resolvers-should-be-guarded` - Ensure GraphQL resolvers have guards
- `max-consts-per-file` - Limit constants per file
- `mdx-component-newlines` - MDX formatting for i18n
- `no-angle-bracket-placeholders` - Prevent angle bracket placeholders in MDX

### Testing Strategy

- **Unit tests** with Jest for both frontend and backend
- **Integration tests** for critical backend workflows (8 parallel shards in CI)
- **Storybook** for component development and testing (4 parallel shards in CI)
- **E2E tests** with Playwright for critical user flows
- **Coverage** enforced via Storybook coverage reports per scope (modules, pages, performance)

## Important Files

- `nx.json` - Nx workspace configuration with task definitions
- `tsconfig.base.json` - Base TypeScript configuration
- `package.json` - Root package with workspace definitions
- `eslint.config.mjs` - Root ESLint flat config (ESLint 9)
- `.husky/pre-commit` - Pre-commit hook (runs lint-staged)
- `.github/workflows/` - CI/CD pipeline definitions (24 workflows)
- `packages/twenty-eslint-rules/` - Custom ESLint rules
- `.cursor/rules/` - Development guidelines and best practices
