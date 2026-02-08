# React Patterns Rules

Applies to: `src/**/*.tsx`, `src/**/*.ts`

## React Keys (MANDATORY)
- NEVER use array index as a React key — use stable, unique IDs
- BAD:
  ```tsx
  {items.map((item, index) => <ListItem key={index} item={item} />)}
  ```
- GOOD:
  ```tsx
  {items.map((item) => <ListItem key={item.id} item={item} />)}
  ```
- Why: index-based keys cause incorrect state preservation on reorder, insert, or delete

## useEffect Cleanup (MANDATORY)
- Every `useEffect` that creates subscriptions, timers, listeners, or AbortControllers MUST return a cleanup function
- BAD — timer without cleanup (leaks on unmount):
  ```tsx
  useEffect(() => {
    const id = setInterval(() => tick(), 1000);
  }, []);
  ```
- GOOD:
  ```tsx
  useEffect(() => {
    const id = setInterval(() => tick(), TICK_INTERVAL_MS);
    return () => clearInterval(id);
  }, []);
  ```
- BAD — EventSource without cleanup:
  ```tsx
  useEffect(() => {
    const source = new EventSource("/api/stream");
    source.onmessage = (e) => addMessage(e.data);
  }, []);
  ```
- GOOD:
  ```tsx
  useEffect(() => {
    const source = new EventSource("/api/stream");
    source.onmessage = (e) => addMessage(e.data);
    return () => source.close();
  }, []);
  ```
- BAD — fetch without AbortController cleanup:
  ```tsx
  useEffect(() => {
    fetch("/api/data").then(r => r.json()).then(setData);
  }, []);
  ```
- GOOD:
  ```tsx
  useEffect(() => {
    const controller = new AbortController();
    fetch("/api/data", { signal: controller.signal })
      .then(r => r.json())
      .then(setData)
      .catch(error => {
        if (error.name !== "AbortError") console.error("Fetch failed:", error);
      });
    return () => controller.abort();
  }, []);
  ```

## Empty Catch Blocks (MANDATORY)
- Empty catch blocks are PROHIBITED — every catch MUST log the error AND handle the error state
- See `.claude/rules/error-handling.md` for full TypeScript error handling rules
- BAD: `catch {}`, `catch (e) {}`, `catch (error) { /* ignore */ }`
- GOOD: `catch (error) { console.error("Context:", error); setError(error.message); }`

## Fetch Timeouts (MANDATORY)
- Every `fetch()` call MUST have a timeout — see `.claude/rules/security.md` Frontend Security section
- BAD: `fetch(url)` — no timeout
- GOOD: `fetch(url, { signal: AbortSignal.timeout(DEFAULT_FETCH_TIMEOUT_MS) })`

## No `any` Types (MANDATORY)
- NEVER use `any` — use `unknown` and narrow with type guards
- BAD: `function handleEvent(data: any) { ... }`
- GOOD: `function handleEvent(data: unknown) { if (isValidEvent(data)) { ... } }`
- BAD: `const result: any = await response.json();`
- GOOD: `const result: unknown = await response.json(); const parsed = UserSchema.parse(result);`
- Use Zod, io-ts, or manual type guards to validate unknown data at runtime

## Strict TypeScript Config (SHOULD)
- Enable these in `tsconfig.json` for maximum safety:
  ```json
  {
    "compilerOptions": {
      "strict": true,
      "noUnusedLocals": true,
      "noUnusedParameters": true,
      "noUncheckedIndexedAccess": true,
      "noImplicitReturns": true
    }
  }
  ```

## Component Size (SHOULD)
- Keep components under 100 lines (including hooks)
- If a component exceeds 100 lines, extract sub-components or custom hooks
- Each component does ONE thing (Single Responsibility)
