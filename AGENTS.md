# AGENTS.md

This file provides comprehensive guidelines for AI agents (GitHub Copilot, Claude, Cursor, etc.) working with the Twenty CRM codebase.

## Repository Overview

Twenty is an open-source CRM (Customer Relationship Management) platform built as a modern alternative to Salesforce. It's designed with a focus on user experience, extensibility, and developer-friendly architecture.

### Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18, TypeScript, Recoil, Emotion, Vite |
| Backend | NestJS, TypeORM, GraphQL (Yoga), PostgreSQL |
| Caching | Redis |
| Queue | BullMQ |
| Testing | Jest, Playwright, Storybook |
| Monorepo | Nx workspace with Yarn 4 |

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

| Element | Convention | Example |
|---------|-----------|---------|
| Variables/Functions | camelCase | `userAccountBalance`, `calculateTotal` |
| Constants | SCREAMING_SNAKE_CASE | `API_ENDPOINTS`, `MAX_RETRY_COUNT` |
| Types/Classes | PascalCase | `UserService`, `ButtonProps` |
| Files/Directories | kebab-case | `user-profile.component.tsx` |
| Component Props | PascalCase + Props suffix | `UserCardProps` |

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

## PR Guidelines

### Before Submitting

1. Run linting: `npx nx lint:diff-with-main <package>`
2. Run type checking: `npx nx typecheck <package>`
3. Run relevant tests
4. Ensure no console errors in browser
5. Update documentation if API changes

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
- [ ] No TypeScript errors
- [ ] GraphQL schema changes are backward compatible
- [ ] Database migrations are properly structured

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

| File | Purpose |
|------|---------|
| `nx.json` | Nx workspace configuration and task definitions |
| `tsconfig.base.json` | Base TypeScript configuration |
| `eslint.config.mjs` | ESLint configuration (flat config) |
| `package.json` | Root package with workspace definitions |
| `.cursor/rules/` | Development guidelines and rules |
| `CLAUDE.md` | Claude Code specific instructions |

## Getting Help

- Check existing code patterns in similar files
- Review `.cursor/rules/` for specific guidelines
- Run `npx nx graph` to visualize package dependencies
- Use `npx nx show project <package>` to see available targets

## CI/CD Pipeline Overview

The repository uses GitHub Actions with optimized workflows that skip jobs when relevant files haven't changed.

### Automated Checks Table

| Check | Workflow | Runs On | Required for Merge |
|-------|----------|---------|-------------------|
| Frontend Lint | `ci-front.yaml` | PR, merge_group | Yes |
| Frontend Typecheck | `ci-front.yaml` | PR, merge_group | Yes |
| Frontend Tests | `ci-front.yaml` | PR, merge_group | Yes |
| Storybook Build | `ci-front.yaml` | PR, merge_group | Yes |
| Storybook Tests | `ci-front.yaml` | PR, merge_group | Yes |
| Backend Lint | `ci-server.yaml` | PR, merge_group | Yes |
| Backend Typecheck | `ci-server.yaml` | PR, merge_group | Yes |
| Backend Unit Tests | `ci-server.yaml` | PR, merge_group | Yes |
| Backend Integration Tests | `ci-server.yaml` | PR, merge_group | Yes |
| E2E Tests | `ci-front.yaml` | PR with `run-e2e` label | No (manual) |
| Format Check | `ci-format.yaml` | PR, merge_group | Yes |
| Security Scan | `security.yaml` | PR, push, weekly | Yes |
| Breaking Changes | `ci-breaking-changes.yaml` | PR to main | Informational |
| Docker Compose | `ci-test-docker-compose.yaml` | PR, merge_group | Yes |

### Skip Detection

All CI workflows use `.github/workflows/changed-files.yaml` to skip jobs when:
- Only documentation changed (for code workflows)
- Only unrelated packages changed
- Only test files changed (for non-test workflows)

## Custom ESLint Rules

The 8 most impactful custom rules in `packages/twenty-eslint-rules/`:

| Rule | Severity | Purpose |
|------|----------|---------|
| `graphql-resolvers-should-be-guarded` | Error | **Security**: All GraphQL resolvers must have authentication guards |
| `rest-api-methods-should-be-guarded` | Error | **Security**: All REST endpoints must have authentication guards |
| `no-hardcoded-colors` | Error | **Consistency**: Use theme variables, not hex/rgb values |
| `styled-components-prefixed-with-styled` | Error | **Convention**: Styled components must start with `Styled` prefix |
| `component-props-naming` | Error | **Convention**: Props types must be named `ComponentNameProps` |
| `matching-state-variable` | Warning | **Readability**: State variable names should match atom names |
| `useRecoilCallback-has-dependency-array` | Error | **Correctness**: Prevents stale closure bugs in Recoil callbacks |
| `no-navigate-prefer-link` | Warning | **UX**: Prefer `<Link>` for better accessibility and SEO |

## Code Review Checklist

### Code Quality
- [ ] No `any` types (use `unknown` with type guards)
- [ ] Named exports only (no default exports)
- [ ] Types over interfaces (unless extending third-party)
- [ ] Functional components only (no class components)
- [ ] Event handlers over useEffect for user-triggered state changes

### Security
- [ ] GraphQL resolvers have `@UseGuards()` decorators
- [ ] REST endpoints have authentication guards
- [ ] User input is sanitized before processing
- [ ] No hardcoded secrets or credentials
- [ ] Database queries use parameterized inputs

### Testing
- [ ] New features have corresponding tests
- [ ] Tests follow AAA pattern (Arrange-Act-Assert)
- [ ] UI components have Storybook stories
- [ ] Integration tests cover critical paths
- [ ] No `test.skip` or `it.skip` without TODO comment

### CI Compliance
- [ ] `npx nx lint:diff-with-main <package>` passes
- [ ] `npx nx typecheck <package>` passes
- [ ] `npx nx fmt <package>` shows no changes needed
- [ ] `npx nx test <package>` passes
- [ ] No new ESLint rule violations

### Database & API
- [ ] Migrations are reversible when possible
- [ ] GraphQL schema changes are backward compatible
- [ ] REST API changes documented in OpenAPI
- [ ] No N+1 query patterns in resolvers

## Preview Environment

### How It Works

1. **Trigger**: Add the `preview-app` label to a PR
2. **Dispatch**: `preview-env-dispatch.yaml` triggers Render deployment
3. **Build**: Render builds a preview environment with PR changes
4. **URL**: Preview URL is posted as a PR comment
5. **Lifecycle**: Preview environments are automatically cleaned up when PR closes

### What Gets Deployed
- Frontend (`twenty-front`) at the preview URL
- Backend (`twenty-server`) with isolated database
- Worker (`twenty-server:worker`) for background jobs

### Testing Preview Environments
```bash
# Preview URL format
https://twenty-pr-{PR_NUMBER}.onrender.com

# Test the frontend
curl https://twenty-pr-123.onrender.com

# Test the API
curl https://twenty-pr-123.onrender.com/healthz
```

## Coding Standards

### TypeScript Best Practices

```typescript
// Use discriminated unions for state
type LoadingState =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: User }
  | { status: 'error'; error: Error };

// Use const assertions for literal types
const ROLES = ['admin', 'user', 'guest'] as const;
type Role = typeof ROLES[number];

// Prefer nullish coalescing over OR
const value = input ?? defaultValue;  // Correct
const value = input || defaultValue;  // Avoid (treats '' and 0 as falsy)

// Use satisfies for type checking without widening
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
} satisfies Config;
```

### Import Patterns (Nx Module Boundaries)

```typescript
// Correct: Use path aliases defined in tsconfig
import { UserService } from 'src/modules/user/user.service';
import { isDefined } from 'twenty-shared/utils';
import { Button } from '@/components/ui';

// Incorrect: Cross-scope imports
import { serverUtil } from 'twenty-server/utils';  // Frontend can't import backend

// Module boundary rules:
// scope:frontend → scope:frontend, scope:shared
// scope:backend  → scope:backend, scope:shared
// scope:shared   → scope:shared only
```

### Naming Conventions

```typescript
// Files and directories: kebab-case
// user-profile.component.tsx
// use-user-data.hook.ts
// user.service.ts

// Components: PascalCase
export const UserProfile = () => { ... };

// Hooks: camelCase with 'use' prefix
export const useUserData = () => { ... };

// Types: PascalCase
type UserProfileProps = { ... };

// Constants: SCREAMING_SNAKE_CASE
const MAX_RETRY_COUNT = 3;
const API_ENDPOINTS = { ... };

// Styled components: PascalCase with 'Styled' prefix
const StyledUserCard = styled.div`...`;
```

### State Management Patterns

```typescript
// Recoil atoms: use State suffix
export const currentUserState = atom<User | null>({
  key: 'currentUserState',
  default: null,
});

// Recoil selectors: use Selector suffix
export const currentUserNameSelector = selector({
  key: 'currentUserNameSelector',
  get: ({ get }) => get(currentUserState)?.name,
});

// Access atoms correctly in callbacks
const handleAction = useRecoilCallback(({ snapshot }) => async () => {
  // Use getLoadable for sync access
  const user = snapshot.getLoadable(currentUserState).getValue();
  // NOT: const user = get(currentUserState);
}, []);
```
