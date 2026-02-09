# AGENTS.md

This file provides comprehensive guidelines for AI agents (GitHub Copilot, Claude, Cursor, etc.) working with the Twenty CRM codebase.

## Repository Overview

Twenty is an open-source CRM (Customer Relationship Management) platform built as a modern alternative to Salesforce. It's designed with a focus on user experience, extensibility, and developer-friendly architecture.

### Technology Stack

| Layer    | Technology                                  |
| -------- | ------------------------------------------- |
| Frontend | React 18, TypeScript, Recoil, Emotion, Vite |
| Backend  | NestJS, TypeORM, GraphQL (Yoga), PostgreSQL |
| Caching  | Redis                                       |
| Queue    | BullMQ                                      |
| Testing  | Jest, Playwright, Storybook                 |
| Monorepo | Nx workspace with Yarn 4                    |

### Package Structure

```
packages/
├── twenty-front/          # React frontend application (main CRM UI)
├── twenty-server/         # NestJS backend API (GraphQL + REST)
├── twenty-ui/             # Shared UI component library
├── twenty-shared/         # Common types, utilities, and constants
├── twenty-emails/         # Email templates (React Email)
├── twenty-website/        # Next.js documentation website
├── twenty-docs/           # Documentation content
├── twenty-zapier/         # Zapier integration
├── twenty-sdk/            # TypeScript SDK for API
├── twenty-cli/            # Command-line interface
├── twenty-apps/           # External app integrations
├── twenty-e2e-testing/    # Playwright E2E tests
├── twenty-utils/          # Utility functions
├── twenty-eslint-rules/   # Custom ESLint rules
└── create-twenty-app/     # Project scaffolding tool
```

## Code Style Requirements

### TypeScript Standards

- **Strict mode enabled** - No implicit any, strict null checks
- **No `any` type** - Use proper typing or `unknown` with type guards
- **Types over interfaces** - Exception: extending third-party interfaces
- **String literals over enums** - Exception: GraphQL enums
- **Named exports only** - No default exports anywhere

```typescript
// Correct
type UserRole = 'admin' | 'user' | 'guest';

type UserProps = {
  id: string;
  name: string;
  role: UserRole;
};

export const UserCard = ({ id, name, role }: UserProps) => {
  // ...
};

// Incorrect
enum UserRole { Admin, User, Guest }  // Use string literal
interface UserProps { ... }           // Use type
export default UserCard;              // Use named export
```

### Naming Conventions

| Element             | Convention                | Example                                |
| ------------------- | ------------------------- | -------------------------------------- |
| Variables/Functions | camelCase                 | `userAccountBalance`, `calculateTotal` |
| Constants           | SCREAMING_SNAKE_CASE      | `API_ENDPOINTS`, `MAX_RETRY_COUNT`     |
| Types/Classes       | PascalCase                | `UserService`, `ButtonProps`           |
| Files/Directories   | kebab-case                | `user-profile.component.tsx`           |
| Component Props     | PascalCase + Props suffix | `UserCardProps`                        |

### React Guidelines

- **Functional components only** - No class components
- **Event handlers over useEffect** - For state updates triggered by user actions
- **Destructure props** - Always destructure in function parameters
- **Small, focused components** - Single responsibility principle
- **Composition over inheritance** - Build complex UIs from simple components

```typescript
// Correct pattern
export const UserForm = ({ onSubmit, initialData }: UserFormProps) => {
  const handleSubmit = async (data: FormData) => {
    await onSubmit(data);
    // Direct handling, not useEffect
  };

  return <Form onSubmit={handleSubmit} defaultValues={initialData} />;
};
```

### Import Organization

1. External libraries (react, lodash, etc.)
2. Internal modules (absolute paths with @/)
3. Relative imports (./types, ../components)

```typescript
import React, { useCallback, useState } from 'react';
import styled from '@emotion/styled';

import { Button } from '@/components/ui';
import { UserService } from '@/services';

import { UserCardProps } from './types';
```

### Comments

- Use short-form comments (`//`), NOT JSDoc blocks
- Explain **WHY**, not **WHAT**
- Comment business logic and non-obvious decisions
- Avoid obvious comments that repeat the code

```typescript
// Correct - Explains business logic
// Premium users get 15% discount on orders over $100
const discount = isPremiumUser && orderTotal > 100 ? 0.15 : 0;

// Incorrect - States the obvious
// Get the user's name
const userName = user.name;
```

## Testing Requirements

### Test Structure (AAA Pattern)

```typescript
describe('UserService', () => {
  describe('when getting user by ID', () => {
    it('should return user data for valid ID', async () => {
      // Arrange
      const userId = '123';
      const mockUser = createTestUser({ id: userId });
      mockRepository.findById.mockResolvedValue(mockUser);

      // Act
      const result = await userService.getUserById(userId);

      // Assert
      expect(result).toEqual(mockUser);
    });
  });
});
```

### Testing Principles

- **Test behavior, not implementation**
- **Query by user-visible elements** (text, roles, labels) over test IDs
- **Keep tests isolated and repeatable**
- **Test pyramid**: 70% unit, 20% integration, 10% E2E

### Running Tests

```bash
# Single test file (PREFERRED - fastest)
npx jest path/to/test.test.ts --config=packages/twenty-front/jest.config.mjs

# Frontend tests use .test.ts extension
npx jest packages/twenty-front/src/modules/user/user.test.ts --config=packages/twenty-front/jest.config.mjs

# Server tests use .spec.ts extension
npx jest packages/twenty-server/src/services/user.spec.ts --config=packages/twenty-server/jest.config.mjs

# Full test suite (slower)
npx nx test twenty-front
npx nx test twenty-server
```

### Coverage Thresholds

The project enforces coverage thresholds via Storybook tests. All UI components should have corresponding stories with proper coverage.

## Development Commands

### Starting Development

```bash
# Start all services (frontend + backend + worker)
yarn start

# Individual services
npx nx start twenty-front     # Frontend dev server (port 3001)
npx nx start twenty-server    # Backend server (port 3000)
npx nx run twenty-server:worker  # Background job worker
```

### Code Quality

```bash
# Linting (diff with main - FASTEST for PRs)
npx nx lint:diff-with-main twenty-front
npx nx lint:diff-with-main twenty-server
npx nx lint:diff-with-main twenty-front --configuration=fix  # Auto-fix

# Full linting
npx nx lint twenty-front
npx nx lint twenty-server

# Type checking
npx nx typecheck twenty-front
npx nx typecheck twenty-server

# Formatting
npx nx fmt twenty-front
npx nx fmt twenty-server
```

### Building

```bash
npx nx build twenty-front
npx nx build twenty-server
npx nx build twenty-shared  # Must build before dependent packages
```

### Database Operations

```bash
# Reset database (development)
npx nx database:reset twenty-server

# Run migrations
npx nx run twenty-server:database:migrate:prod

# Generate new migration
npx nx run twenty-server:typeorm migration:generate src/database/typeorm/core/migrations/common/[name] -d src/database/typeorm/core/core.datasource.ts

# Sync metadata
npx nx run twenty-server:command workspace:sync-metadata
```

### GraphQL

```bash
# Regenerate GraphQL types after schema changes
npx nx run twenty-front:graphql:generate
```

### Storybook

```bash
npx nx storybook:build twenty-front    # Build for production
npx nx storybook:serve:dev twenty-front  # Development mode
npx nx storybook:test twenty-front     # Run visual tests
```

## Architecture Patterns

### Frontend (twenty-front)

- **State Management**: Recoil for global state, React hooks for local
- **Styling**: Emotion with styled-components pattern
- **Data Fetching**: Apollo Client with GraphQL
- **Internationalization**: Lingui
- **Routing**: React Router v6

### Backend (twenty-server)

- **Framework**: NestJS with modular architecture
- **API**: GraphQL-first with code-first approach
- **Database**: TypeORM with PostgreSQL
- **Caching**: Redis for sessions and caching
- **Jobs**: BullMQ for background processing

### Module Boundaries (Nx)

The workspace enforces strict module boundaries:

```
scope:frontend  -> can use: scope:frontend, scope:shared
scope:backend   -> can use: scope:backend, scope:shared
scope:shared    -> can use: scope:shared only
scope:sdk       -> can use: scope:sdk, scope:shared
```

## CI/CD Pipeline

### Overview

The repository has 24 GitHub Actions workflows covering CI, deployment, security, and automation. All CI workflows run on PRs and merge groups with concurrency controls.

### CI Workflow Matrix

| Workflow    | File              | Checks                                                                                                 | Runner               |
| ----------- | ----------------- | ------------------------------------------------------------------------------------------------------ | -------------------- |
| Frontend CI | `ci-front.yaml`   | lint, typecheck, test, build, Storybook build/test (4 shards), coverage, E2E                           | depot-ubuntu-24.04-8 |
| Server CI   | `ci-server.yaml`  | lint, typecheck, build, unit tests, integration tests (8 shards), migration checks, GraphQL generation | depot-ubuntu-24.04-8 |
| Shared CI   | `ci-shared.yaml`  | lint, typecheck, test                                                                                  | ubuntu-latest        |
| SDK CI      | `ci-sdk.yaml`     | SDK package checks                                                                                     | ubuntu-latest        |
| Emails CI   | `ci-emails.yaml`  | Email template checks                                                                                  | ubuntu-latest        |
| Docs CI     | `ci-docs.yaml`    | Documentation checks                                                                                   | ubuntu-latest        |
| Website CI  | `ci-website.yaml` | Website checks                                                                                         | ubuntu-latest        |
| Utils CI    | `ci-utils.yaml`   | Danger.js PR analysis                                                                                  | ubuntu-latest        |
| Security    | `security.yaml`   | CodeQL + dependency review                                                                             | ubuntu-latest        |

### CI Services (Backend)

Backend CI jobs spin up these services:

- **PostgreSQL** (`twentycrm/twenty-postgres-spilo`) - Primary database
- **Redis** - Caching and sessions
- **ClickHouse** (`clickhouse/clickhouse-server:25.8.8`) - Analytics (integration tests only)

### What CI Validates

1. **Lint** - ESLint with flat config (ESLint 9), including 15+ custom rules
2. **Type Check** - TypeScript via `tsgo` (native TypeScript compiler)
3. **Unit Tests** - Jest for both frontend and backend
4. **Integration Tests** - Backend tests with real PostgreSQL/Redis/ClickHouse (8 shards)
5. **Storybook Tests** - Visual regression with coverage (4 shards × 3 scopes)
6. **Build Verification** - Full production builds for frontend and backend
7. **Migration Check** - Detects uncommitted TypeORM migration changes
8. **GraphQL Schema Check** - Detects uncommitted GraphQL codegen changes
9. **E2E Tests** - Playwright tests (requires `run-e2e` label on PRs)

### Security Scanning

- **CodeQL Analysis** - Runs on PRs, main branch pushes, and weekly (Sunday midnight)
  - Scans `javascript-typescript` language
  - Results appear in GitHub Security tab
- **Dependency Review** - Runs on PRs, fails on `high` severity vulnerabilities
  - Uses `actions/dependency-review-action@v4`
  - `continue-on-error: true` (non-blocking until Dependency graph is enabled)

### Custom GitHub Actions

| Action          | Location                         | Purpose                                  |
| --------------- | -------------------------------- | ---------------------------------------- |
| `yarn-install`  | `.github/actions/yarn-install/`  | Cached Yarn 4 dependency installation    |
| `nx-affected`   | `.github/actions/nx-affected/`   | Run Nx tasks on affected projects by tag |
| `save-cache`    | `.github/actions/save-cache/`    | Save build artifacts to cache            |
| `restore-cache` | `.github/actions/restore-cache/` | Restore cached build artifacts           |

### Pre-commit Hooks

The repository uses **Husky** + **lint-staged**:

- **`.ts`, `.tsx`, `.js`, `.jsx`** files: `eslint --fix` then `prettier --write`
- **`.json`, `.md`, `.mdx`, `.yml`, `.yaml`** files: `prettier --write`

## Custom ESLint Rules

The project maintains custom ESLint rules in `packages/twenty-eslint-rules/`:

### Frontend Rules

| Rule                                     | Purpose                                    |
| ---------------------------------------- | ------------------------------------------ |
| `component-props-naming`                 | Enforce component prop naming conventions  |
| `effect-components`                      | Rules for effect components                |
| `matching-state-variable`                | State variable naming consistency          |
| `no-hardcoded-colors`                    | Prevent hardcoded color values (use theme) |
| `styled-components-prefixed-with-styled` | Styled component naming                    |
| `sort-css-properties-alphabetically`     | CSS property ordering                      |
| `no-navigate-prefer-link`                | Prefer Link over navigate()                |
| `no-state-useref`                        | Prevent state in useRef                    |
| `useRecoilCallback-has-dependency-array` | Recoil callback deps                       |
| `max-consts-per-file`                    | Limit constants per file                   |

### Backend Rules

| Rule                                  | Purpose                                   |
| ------------------------------------- | ----------------------------------------- |
| `inject-workspace-repository`         | Workspace repository injection pattern    |
| `rest-api-methods-should-be-guarded`  | Ensure REST endpoints have auth guards    |
| `graphql-resolvers-should-be-guarded` | Ensure GraphQL resolvers have auth guards |

### Documentation Rules

| Rule                            | Purpose                                   |
| ------------------------------- | ----------------------------------------- |
| `mdx-component-newlines`        | JSX tags on separate lines (i18n/Crowdin) |
| `no-angle-bracket-placeholders` | No angle bracket placeholders in MDX      |

## PR Guidelines

### Before Submitting

1. Run linting: `npx nx lint:diff-with-main <package>`
2. Run type checking: `npx nx typecheck <package>`
3. Run relevant tests
4. Ensure no console errors in browser
5. Update documentation if API changes
6. Regenerate GraphQL types if schema changed: `npx nx run twenty-front:graphql:generate`

### Commit Messages

- Use conventional commit format
- Keep messages concise and descriptive
- Reference issue numbers when applicable

```
feat(twenty-front): add user profile avatar upload
fix(twenty-server): resolve race condition in sync worker
docs: update API authentication guide
```

### PR Checklist

- [ ] Code follows project style guidelines (ESLint, Prettier)
- [ ] Self-review completed
- [ ] Tests added/updated for new functionality
- [ ] No TypeScript errors (`npx nx typecheck <package>`)
- [ ] No ESLint errors (`npx nx lint:diff-with-main <package>`)
- [ ] GraphQL schema changes are backward compatible
- [ ] GraphQL types regenerated if schema changed
- [ ] Database migrations are properly structured
- [ ] No pending migration drift (CI checks automatically)
- [ ] Security: no hardcoded secrets, inputs sanitized

### Code Review Automation

The following checks run automatically on every PR:

- **Danger.js** (`ci-utils.yaml`) - PR analysis and automated comments
- **ESLint** - Via `nx-affected` with `scope:frontend` and `scope:backend` tags
- **TypeScript** - Type checking via `tsgo`
- **Tests** - Unit and integration tests for affected packages
- **Security** - CodeQL analysis and dependency vulnerability scanning

## Common Patterns

### Utility Helpers

```typescript
import { isDefined } from 'twenty-shared/utils';
import { isNonEmptyString, isNonEmptyArray } from '@sniptt/guards';

// Use utilities instead of manual checks
const validItems = items.filter(isDefined);
const hasValue = isDefined(value);
const hasContent = isNonEmptyString(text);
```

### Error Handling

```typescript
try {
  const user = await userService.findById(userId);
  if (!user) {
    throw new UserNotFoundError(`User with ID ${userId} not found`);
  }
  return user;
} catch (error) {
  logger.error('Failed to fetch user', { userId, error });
  throw error;
}
```

### Security Patterns

```typescript
// Always sanitize before formatting for exports
const safeValue = formatValueForCSV(sanitizeValueForCSVExport(userInput));

// Validate input before processing
const sanitizedInput = validateAndSanitize(userInput);
const result = processData(sanitizedInput);
```

## Important Files

| File                            | Purpose                                         |
| ------------------------------- | ----------------------------------------------- |
| `nx.json`                       | Nx workspace configuration and task definitions |
| `tsconfig.base.json`            | Base TypeScript configuration                   |
| `eslint.config.mjs`             | Root ESLint flat config (ESLint 9)              |
| `package.json`                  | Root package with workspace definitions         |
| `.husky/pre-commit`             | Pre-commit hook (runs lint-staged)              |
| `.github/workflows/`            | CI/CD pipeline (24 workflows)                   |
| `.github/actions/`              | Custom reusable GitHub Actions                  |
| `packages/twenty-eslint-rules/` | Custom ESLint rules (15+ rules)                 |
| `.cursor/rules/`                | Development guidelines and rules                |
| `CLAUDE.md`                     | Claude Code specific instructions               |

## Getting Help

- Check existing code patterns in similar files
- Review `.cursor/rules/` for specific guidelines
- Run `npx nx graph` to visualize package dependencies
- Use `npx nx show project <package>` to see available targets
