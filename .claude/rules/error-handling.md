# Error Handling & Logging Rules

Applies to: `src/**/*.py`

## Error Handling (MANDATORY)
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

## Logging (MANDATORY)
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
