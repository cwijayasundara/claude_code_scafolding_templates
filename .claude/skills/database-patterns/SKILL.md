---
name: database-patterns
description: Repository pattern, async SQLAlchemy sessions, Alembic migrations, N+1 query prevention, and transaction management
---

# Skill: Database Patterns

## When to Use
Apply this skill when working with database models, repositories, queries, or migrations.

## Repository Pattern
- Each entity has a dedicated repository class in `src/repositories/`
- Repositories accept `AsyncSession` via constructor injection
- Repositories handle ONLY data access — no business logic
- Services call repositories, never SQLAlchemy directly

### Repository Structure
```python
class TaskRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, task: Task) -> Task: ...
    async def get_by_id(self, task_id: UUID) -> Task | None: ...
    async def list(self, filters: dict, offset: int, limit: int) -> tuple[list[Task], int]: ...
    async def update(self, task: Task) -> Task: ...
    async def soft_delete(self, task_id: UUID) -> None: ...
```

## Async Sessions
- Use `create_async_engine` with `aiosqlite` (dev/test) or `asyncpg` (staging/prod)
- Use `async_sessionmaker` for session factory
- Sessions are injected via FastAPI `Depends`
- Always use `async with session.begin():` for transaction management

## SQLAlchemy Models
- Use UUID primary keys (generated server-side)
- Add `created_at` and `updated_at` timestamps to all models
- Use `Mapped[]` type annotations for all columns
- Define relationships with `back_populates`
- Use enums for status/role fields (Python Enum mapped to DB)
- Soft delete: use `is_deleted: bool` flag, filter in queries

## Query Patterns
- Use `select()` with explicit column selection when possible
- Apply filters via `.where()` chaining
- Use `.options(selectinload(...))` to prevent N+1 queries
- Pagination: `.offset(skip).limit(limit)` with separate count query

## N+1 Prevention
- ALWAYS use eager loading (`selectinload`, `joinedload`) for relationships accessed in response
- Review every endpoint that returns related data
- Use `SELECT IN` loading for collections, `JOIN` loading for single relations

## Migrations (Alembic)
- All schema changes go through Alembic migrations
- Never modify the database schema directly
- Migration files live in `src/migrations/versions/`
- Use async migration env (`run_async_migrations`)
- Name migrations descriptively: `001_create_users_table.py`
- Always include both `upgrade()` and `downgrade()` functions
- Test migrations: up, verify, down, verify, up again
