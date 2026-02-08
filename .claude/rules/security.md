# Security Rules

Applies to: `src/**/*.py`, `src/**/*.ts`, `src/**/*.tsx`

## No Secrets in Code (MANDATORY)
- NEVER hardcode API keys, passwords, tokens, or connection strings
- BAD: `API_KEY = "sk-abc123..."` in source code
- GOOD: `API_KEY = os.environ["API_KEY"]` or load from Settings (Pydantic BaseSettings)
- BAD: `db_url = "postgresql://user:password@host/db"`
- GOOD: `db_url = settings.database_url` (loaded from environment)
- All secrets MUST come from environment variables, Azure Key Vault, or `.env` files (never committed)
- `.env` files MUST be in `.gitignore` — verify before committing

### Frontend Secrets
- NEVER hardcode API keys or tokens in frontend code — they are visible in the browser
- BAD: `const API_KEY = "sk-abc123..."` in any `.ts` or `.tsx` file
- GOOD: `const API_URL = import.meta.env.VITE_API_URL` (public config only, no secrets)
- Backend proxies MUST handle secret-bearing API calls — frontend sends to your backend, backend calls external APIs with secrets

## Input Validation at Boundaries (MANDATORY)
- Validate ALL user input at API boundaries (FastAPI route handlers, CLI args)
- Use Pydantic models for request validation — never trust raw input
- BAD: `query = f"SELECT * FROM users WHERE name = '{request.name}'"`
- GOOD: Use SQLAlchemy parameterized queries or ORM methods
- BAD: `os.system(f"process {user_input}")`
- GOOD: `subprocess.run(["process", user_input], check=True)` (list form prevents injection)
- BAD: `return HTMLResponse(f"<div>{user_input}</div>")`
- GOOD: Use template engine with auto-escaping, or sanitize output

## SQL Injection Prevention (MANDATORY)
- NEVER construct SQL with string concatenation or f-strings
- BAD: `db.execute(f"SELECT * FROM users WHERE id = {user_id}")`
- GOOD: `db.execute(text("SELECT * FROM users WHERE id = :id"), {"id": user_id})`
- GOOD: Use SQLAlchemy ORM: `session.query(User).filter(User.id == user_id)`
- All database queries MUST use parameterized queries or ORM methods

## Authentication & Authorization (MANDATORY)
- Every API endpoint that accesses user data MUST have authentication
- Use dependency injection for auth checks (FastAPI `Depends()`)
- BAD: Auth check inside the route handler body (easy to forget)
- GOOD: `async def get_user(current_user: User = Depends(get_current_user)):`
- Never expose internal IDs or stack traces in error responses
- Use the principle of least privilege — grant minimum required permissions

## Dependency Security (SHOULD)
- Pin dependency versions in `pyproject.toml` (exact or compatible release `~=`)
- Review new dependencies before adding — check maintenance status, known CVEs
- Prefer well-maintained packages with active security response
- Run `pip audit` or `safety check` periodically to scan for known vulnerabilities

## HTTPS & Transport Security (MANDATORY)
- All external API calls MUST use HTTPS
- BAD: `requests.get("http://api.example.com/data")`
- GOOD: `requests.get("https://api.example.com/data")`
- Set timeouts on all HTTP requests to prevent hanging
- BAD: `requests.get(url)` (no timeout — can hang forever)
- GOOD: `requests.get(url, timeout=DEFAULT_TIMEOUT_SECONDS)`

## Frontend Security (MANDATORY)

### Fetch Timeouts
- Every `fetch()` call MUST have a timeout — use `AbortSignal.timeout()` or a manual `AbortController`
- Define timeout constants — never use inline magic numbers
- BAD: `fetch(url)` — no timeout, can hang forever
- BAD: `fetch(url, { signal: AbortSignal.timeout(5000) })` — magic number
- GOOD:
  ```typescript
  const DEFAULT_FETCH_TIMEOUT_MS = 5000;
  const response = await fetch(url, { signal: AbortSignal.timeout(DEFAULT_FETCH_TIMEOUT_MS) });
  ```
- For long-running operations (file uploads, SSE), use a manual `AbortController` with a longer timeout

### Input Sanitization
- NEVER render user-supplied HTML directly — use `DOMPurify` or equivalent
- BAD: `dangerouslySetInnerHTML={{ __html: userContent }}`
- GOOD: `dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }}`
- Prefer rendering user content as text (React auto-escapes JSX expressions)
- GOOD: `<p>{userContent}</p>` — React escapes automatically, safe by default

### URL & Link Safety
- Validate URLs before rendering as `href` — check protocol is `http:` or `https:`
- BAD: `<a href={userProvidedUrl}>` — could be `javascript:` protocol
- GOOD: Validate URL protocol before rendering, or use a URL sanitizer

## Error Responses (MANDATORY)
- NEVER expose internal details (stack traces, file paths, SQL errors) in API responses
- BAD: `raise HTTPException(status_code=500, detail=str(e))`
- GOOD: `logger.error("Database error: %s", e)` then `raise HTTPException(status_code=500, detail="Internal server error. Please try again.")`
- Use RFC 7807 problem detail format for API errors (see api-design skill)
- Log the full error server-side at ERROR level; return a sanitized message to the client

## File & Path Safety (MANDATORY)
- Never use user input directly in file paths without validation
- BAD: `open(f"/uploads/{filename}")` where filename comes from user
- GOOD: `safe_path = Path("/uploads") / Path(filename).name` (strip directory traversal)
- Validate file extensions and MIME types for uploads
- Set file size limits on all upload endpoints
