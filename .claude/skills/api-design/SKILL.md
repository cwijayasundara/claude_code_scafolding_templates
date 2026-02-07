---
name: api-design
description: REST API conventions, Pydantic schemas, RFC 7807 error format, pagination patterns, and OpenAPI-first design
---

# Skill: API Design

## When to Use
Apply this skill when designing, implementing, or reviewing REST API endpoints.

## REST Conventions
- Use plural nouns for resources: `/users`, `/tasks`, `/comments`
- Use HTTP methods correctly: GET (read), POST (create), PUT (full update), PATCH (partial update), DELETE (remove)
- Use proper status codes: 200 (OK), 201 (Created), 204 (No Content), 400 (Bad Request), 401 (Unauthorized), 403 (Forbidden), 404 (Not Found), 409 (Conflict), 422 (Validation Error), 500 (Internal Server Error)
- Use query parameters for filtering, sorting, pagination: `?status=active&sort=-created_at&page=1&per_page=20`
- Nest sub-resources: `POST /tasks/{task_id}/comments`

## Request/Response Schemas
- Use Pydantic models for all request and response bodies
- Separate Create, Update, and Response schemas (never reuse one for all)
- Use `Field(...)` with descriptions for OpenAPI documentation
- Use `ConfigDict(from_attributes=True)` for ORM compatibility

## Error Format (RFC 7807)
All errors must return structured JSON:
```json
{
  "type": "https://api.example.com/errors/not-found",
  "title": "Resource Not Found",
  "status": 404,
  "detail": "Task with ID 'abc-123' does not exist",
  "instance": "/tasks/abc-123"
}
```

## Pagination
Use offset-based pagination with consistent response shape:
```json
{
  "items": [...],
  "total": 100,
  "page": 1,
  "per_page": 20,
  "pages": 5
}
```

## OpenAPI as Source of Truth
- The OpenAPI spec at `docs/api/openapi.yaml` is the canonical API contract
- Implementation must match the spec exactly
- Run contract tests (Schemathesis) to verify compliance
- Update the spec BEFORE changing the implementation

## Authentication
- Use Bearer JWT tokens in the Authorization header
- Return tokens from POST /auth/login
- Protect endpoints with FastAPI Depends for auth injection
- Never expose sensitive data (passwords, internal IDs) in responses

## Versioning
- Use URL path versioning if needed: `/v1/tasks`
- For this project, no versioning prefix (single version)
