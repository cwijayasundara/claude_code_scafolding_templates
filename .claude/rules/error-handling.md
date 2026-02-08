# Error Handling & Logging Rules

Applies to: `src/**/*.py`, `src/**/*.ts`, `src/**/*.tsx`

## Error Handling — Python (MANDATORY)
- Every external call (API, filesystem, network) MUST be wrapped in try/except
- NEVER let raw library exceptions bubble to the user — catch and re-raise with context
- Catch SPECIFIC exceptions, not bare `except:` or `except Exception:`
- BAD: `settings = Settings()` with no handling — crashes with raw Pydantic traceback on missing env vars
- GOOD:
  ```python
  try:
      settings = Settings()
  except ValidationError as e:
      logger.error("Configuration error: %s", e)
      sys.exit("Error: required environment variables are missing. See .env.example")
  ```
- BAD: `response = requests.get(url)` with no error handling
- GOOD:
  ```python
  try:
      response = requests.get(url, timeout=30)
      response.raise_for_status()
  except requests.RequestException as e:
      logger.error("API request failed: %s", e)
      raise
  ```
- CLI entry points (`main()`) must catch all expected errors and print clean, actionable messages

## Error Handling — TypeScript / React (MANDATORY)
- Every `fetch`, WebSocket, or external SDK call MUST be in a try/catch
- Empty catch blocks are PROHIBITED — every catch MUST log the error AND handle the error state
- BAD: `catch {}` or `catch (e) {}` with no body
- BAD: `catch (error) { /* ignore */ }`
- GOOD:
  ```typescript
  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(DEFAULT_FETCH_TIMEOUT_MS) });
    if (!response.ok) throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    return await response.json();
  } catch (error) {
    console.error("Failed to fetch user data:", error);
    setError(error instanceof Error ? error.message : "An unexpected error occurred");
  }
  ```
- React components MUST use Error Boundaries to catch rendering errors
- Async errors in event handlers MUST be caught — they do NOT propagate to Error Boundaries
- BAD: `onClick={async () => { await saveData(); }}` — unhandled rejection if `saveData` throws
- GOOD:
  ```typescript
  onClick={async () => {
    try {
      await saveData();
    } catch (error) {
      console.error("Save failed:", error);
      setError("Failed to save. Please try again.");
    }
  }}
  ```

## Logging — Python (MANDATORY)
- Every module MUST create a logger: `logger = logging.getLogger(__name__)`
- NEVER use `print()` for operational output — use `logger.info()` instead
- BAD: `print(f"Processing {item}")`
- GOOD: `logger.info("Processing %s", item)`
- If a Settings/config class has `log_level`, it MUST be wired to `logging.basicConfig()` at startup
- Log these events at appropriate levels:
  - DEBUG: internal state, variable values, loop iterations
  - INFO: component initialization, pipeline start/end, key operations
  - WARNING: recoverable issues, fallback behavior triggered
  - ERROR: failures, exceptions, missing required data

## Logging — TypeScript / React (MANDATORY)
- Use `console.error()` for errors, `console.warn()` for warnings in browser code
- For Node.js backend services, use a structured logger (e.g., pino, winston) — not raw `console.log()`
- BAD: `console.log("error occurred")` — no error object, wrong log level
- GOOD: `console.error("Failed to load user profile:", error)`
- Include the error object in log calls so stack traces are visible in developer tools
- Log at appropriate levels:
  - `console.error()`: failures, caught exceptions, failed API calls
  - `console.warn()`: recoverable issues, deprecation warnings, fallback behavior
  - `console.info()`: key lifecycle events (mount, unmount, navigation)
  - `console.debug()`: internal state changes, render cycles (disable in production)
