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

## Deployment & Preview Environments

### Render Services

| Service | Type | Description |
|---------|------|-------------|
| twenty-server | Web Service | Backend API server (GraphQL + REST) |
| twenty-worker | Background Worker | BullMQ job processor |
| twenty-redis | Private Service | Redis for caching and sessions |
| twenty-postgres | Private Service | PostgreSQL database |

### Preview Environment Behavior

- **Auto-creation**: Preview environments are automatically created when a PR is opened
- **Auto-destruction**: Preview environments are automatically destroyed when PR is merged or closed
- **Preview URL pattern**: `https://twenty-server-pr-{N}.onrender.com` (where N is the PR number)
- **Production URL**: `https://twenty-server-8x55.onrender.com`

### Testing Preview Environments

1. Open a PR and wait for the Render deployment to complete
2. Access the preview URL using the PR number
3. Test your changes in an isolated environment
4. Preview environments share the same schema but have isolated data

## CI/CD Pipeline

### Required Status Checks

All PRs must pass these status checks before merging:

| Check | Description |
|-------|-------------|
| `ci-front-status-check` | Frontend linting, type checking, and tests |
| `ci-server-status-check` | Backend linting, type checking, and tests |
| `ci-shared-status-check` | Shared packages validation |
| `ci-format-status-check` | Prettier formatting validation |
| `ci-emails-status-check` | Email templates validation |
| `ci-create-app-status-check` | Create app scaffolding validation |
| `Cursor Bugbot` | Automated AI code review |

### Branch Protection Rules

- **Required conversations resolution**: All review comments must be resolved
- **Strict status checks**: Branch must be up to date with base branch before merging
- **Linear history**: Encouraged through squash merging

## Code Quality Rules

### Cyclomatic Complexity

The project enforces cyclomatic complexity limits to maintain code readability:

```javascript
'complexity': ['warn', { max: 20 }]
```

- **Max complexity**: 20 (set higher for large existing codebase)
- **Level**: Warning (does not block CI, but should be addressed)
- **Guidance**: Functions exceeding this threshold should be refactored into smaller, focused functions

### Custom ESLint Rules

The `twenty-eslint-rules` package provides custom rules:

- `twenty/mdx-component-newlines`: Enforces JSX tags on separate lines in MDX files
- `twenty/no-angle-bracket-placeholders`: Prevents angle bracket placeholders that cause translation issues

## Getting Help

- Check existing code patterns in similar files
- Review `.cursor/rules/` for specific guidelines
- Run `npx nx graph` to visualize package dependencies
- Use `npx nx show project <package>` to see available targets
