# Cadence

Course platform (mini Udemy): React Router v8 framework mode with SSR, SQLite through Drizzle, Tailwind 4 + shadcn/ui. Scripts are in `package.json`.

## Feedback loops

Before calling work done, `npm run test` and `npm run typecheck` both pass. `typecheck` runs `react-router typegen` first, so new routes get their `./+types/*` files from it.

## Layering

- **Routes** (`app/routes/*.tsx`) own HTTP: validate input, check the session, call services, render. Register every new route in `app/routes.ts`; file names alone do nothing.
- **Services** (`app/services/*Service.ts`) own data access and business rules. Each is a flat set of exported functions taking **positional parameters** (project convention), querying through `db` from `~/db`.
- **Schema** lives in `app/db/schema.ts`; status and role values are TypeScript `enum`s there (`UserRole`, `CourseStatus`, ...). Use the enum members, never string literals.

## Routes

- Validate params with `parseParams` and form bodies with `parseFormData` from `~/lib/validation`, each against a Zod schema. `parseFormData` returns a field-error map to send back with `data(...)`; `parseParams` throws a 400.
- Current user comes from `getCurrentUserId(request)` in `~/lib/session`. Authorize in the loader/action against roles and ownership; the UI hiding a button is not a check.
- A route with several form actions dispatches on a hidden `intent` field (see `courses.$slug.lessons.$lessonId.tsx`). Submit with `useFetcher` so the page doesn't reload.
- Server-only modules use the `.server.ts` suffix (e.g. `~/lib/markdown.server`).

## Database

- `~/db/index.ts` must stay side-effect free: the connection opens lazily so the client bundle can drop `better-sqlite3`. Keep new top-level code there pure.
- Schema change: edit `schema.ts`, then `npm run db:generate` to write a migration into `drizzle/`, then `npm run db:migrate`. Never hand-edit generated migrations or snapshots. Tests run the same migrations, so a schema edit without a generated migration breaks them.
- Extend `scripts/seed.ts` when a feature needs demo data.

## Tests

Service tests sit beside the service (`fooService.test.ts`) and run against a fresh in-memory database per test. Copy the shape of an existing one:

```ts
let testDb: ReturnType<typeof createTestDb>;
vi.mock("~/db", () => ({ get db() { return testDb; } }));
beforeEach(() => { testDb = createTestDb(); base = seedBaseData(testDb); });
```

`createTestDb` and `seedBaseData` (a student, an instructor, a category, a published course) live in `app/test/setup.ts`. Write tests through the service's public functions.

## Specs

Feature specs live in `specs/`. When implementing one, its user stories are the acceptance criteria: every story accounted for.

## Out of scope

- `request-logger/` is course tooling, not app code; read `request-logger/CLAUDE.md` before touching it.
- Request logging is on when `ANTHROPIC_BASE_URL` is `http://localhost:8787` (set by `npm run claude`). Every model request and response, including file contents and command output, is then written to `request-logger/logs/` (gitignored). Details: `request-logger/README.md`.
- `.agents/skills/` and `.claude/skills/` are vendored skills; edit only when asked.

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `luisfff/ai-coding-crash-course`, managed through the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default roles, each label named after its role: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root, created only when a term or decision is settled. See `docs/agents/domain.md`.
