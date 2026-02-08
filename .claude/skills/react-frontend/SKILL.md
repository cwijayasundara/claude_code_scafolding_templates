---
name: react-frontend
description: React 18 + TypeScript conventions, component patterns, state management, streaming UI for agent output, and project structure
---

# Skill: React Frontend

> **MANDATORY RULES**: All React code MUST follow `.claude/rules/react-patterns.md` (keys, useEffect cleanup, empty catch blocks, fetch timeouts, no `any` types). This skill provides implementation guidance (advisory); the rules file takes precedence on any conflict.

## When to Use
Apply this skill when building React frontends, especially UIs that interact with AI agents or streaming backends.

## Project Structure

```
frontend/
  src/
    components/          # Reusable UI components
      ui/                # Primitive components (Button, Input, Card)
      layout/            # Layout components (Header, Sidebar, PageLayout)
      features/          # Feature-specific components (ChatPanel, AgentStatus)
    hooks/               # Custom React hooks
    services/            # API client functions
    types/               # TypeScript type definitions
    utils/               # Pure utility functions
    pages/               # Route-level page components (if using routing)
    App.tsx
    main.tsx
  public/
  package.json
  tsconfig.json
  vite.config.ts
```

## Component Patterns

### Functional Components Only
Never use class components. Use typed function components:

```tsx
interface UserCardProps {
  name: string;
  email: string;
  avatarUrl?: string;
  onSelect: (email: string) => void;
}

export function UserCard({ name, email, avatarUrl, onSelect }: UserCardProps) {
  return (
    <div className="user-card" onClick={() => onSelect(email)}>
      {avatarUrl && <img src={avatarUrl} alt={name} />}
      <h3>{name}</h3>
      <p>{email}</p>
    </div>
  );
}
```

**Rules:**
- Props interface defined above the component, named `<Component>Props`
- Export named functions (not `export default`)
- Destructure props in the parameter list
- One component per file, filename matches component name

### Component Size Limits
- Max 100 lines per component (including hooks)
- If a component exceeds 100 lines, extract sub-components or custom hooks
- Each component does ONE thing (Single Responsibility)

## State Management

### Local State (useState)
Use for UI-only state that doesn't need to be shared:

```tsx
const [isOpen, setIsOpen] = useState(false);
const [query, setQuery] = useState("");
```

### Server State (React Query / TanStack Query)
Use for data fetched from APIs — never store API data in useState:

```tsx
import { useQuery, useMutation } from "@tanstack/react-query";

function useResearchResults(topic: string) {
  return useQuery({
    queryKey: ["research", topic],
    queryFn: () => fetchResearch(topic),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}
```

**Rules:**
- Wrap API calls in custom hooks named `use<Resource>`
- Use `queryKey` arrays for cache invalidation
- Set `staleTime` to avoid unnecessary refetches
- Use `useMutation` for POST/PUT/DELETE operations

### Global State (Context or Zustand)
Use React Context for simple shared state (theme, auth). Use Zustand for complex state:

```tsx
// Simple: React Context
const ThemeContext = createContext<"light" | "dark">("light");

// Complex: Zustand store
import { create } from "zustand";

interface AgentStore {
  isRunning: boolean;
  messages: Message[];
  startAgent: (topic: string) => void;
  addMessage: (msg: Message) => void;
}

const useAgentStore = create<AgentStore>((set) => ({
  isRunning: false,
  messages: [],
  startAgent: (topic) => set({ isRunning: true }),
  addMessage: (msg) => set((s) => ({ messages: [...s.messages, msg] })),
}));
```

## Streaming Agent UI

### Server-Sent Events (SSE) for Agent Output
Use SSE to stream agent responses in real-time:

```tsx
function useAgentStream(topic: string) {
  const [chunks, setChunks] = useState<string[]>([]);
  const [isStreaming, setIsStreaming] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const startStream = useCallback(() => {
    setIsStreaming(true);
    setChunks([]);
    setError(null);

    const eventSource = new EventSource(
      `/api/agent/stream?topic=${encodeURIComponent(topic)}`
    );

    eventSource.onmessage = (event) => {
      setChunks((prev) => [...prev, event.data]);
    };

    eventSource.onerror = () => {
      setError("Stream connection lost");
      setIsStreaming(false);
      eventSource.close();
    };

    eventSource.addEventListener("done", () => {
      setIsStreaming(false);
      eventSource.close();
    });

    return () => eventSource.close();
  }, [topic]);

  return { chunks, isStreaming, error, startStream };
}
```

### Streaming Chat Component
```tsx
function ChatPanel() {
  const [input, setInput] = useState("");
  const { chunks, isStreaming, startStream } = useAgentStream(input);

  return (
    <div className="chat-panel">
      <MessageList messages={chunks} />
      {isStreaming && <StreamingIndicator />}
      <ChatInput
        value={input}
        onChange={setInput}
        onSubmit={startStream}
        disabled={isStreaming}
      />
    </div>
  );
}
```

## TypeScript Conventions

### Strict Mode
Enable in `tsconfig.json`:
```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true
  }
}
```

### Type Definitions
- Define shared types in `src/types/`
- Use `interface` for object shapes, `type` for unions/intersections
- Never use `any` — use `unknown` and narrow with type guards
- Export types from the same file as the component that uses them

```tsx
// src/types/agent.ts
export interface AgentMessage {
  id: string;
  role: "user" | "assistant" | "tool";
  content: string;
  timestamp: Date;
  toolCalls?: ToolCall[];
}

export interface ToolCall {
  name: string;
  args: Record<string, unknown>;
  result?: string;
}
```

## API Client Pattern

### Typed API Functions
Create typed API client functions in `src/services/`:

```tsx
// src/services/api.ts
const API_BASE_URL = import.meta.env.VITE_API_URL ?? "http://localhost:8000";

export async function startResearch(topic: string): Promise<ResearchResult> {
  const response = await fetch(`${API_BASE_URL}/api/research`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ topic }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new ApiError(error.title, response.status, error.detail);
  }

  return response.json();
}
```

**Rules:**
- Base URL from environment variable (`VITE_API_URL`)
- Typed return values (no `any`)
- Throw typed errors, don't return error objects
- One file per API domain (e.g., `research.ts`, `auth.ts`)

## Error Handling

### Error Boundaries
Wrap feature areas with error boundaries:

```tsx
import { ErrorBoundary } from "react-error-boundary";

function App() {
  return (
    <ErrorBoundary fallback={<ErrorPage />}>
      <AgentPanel />
    </ErrorBoundary>
  );
}
```

### Loading & Error States
Every data-fetching component must handle three states:

```tsx
function ResearchResults({ topic }: { topic: string }) {
  const { data, isLoading, error } = useResearchResults(topic);

  if (isLoading) return <Skeleton />;
  if (error) return <ErrorMessage message={error.message} />;
  if (!data) return <EmptyState />;

  return <ResultsList results={data} />;
}
```

## Styling

### Tailwind CSS (Recommended)
Use Tailwind utility classes. Extract repeated patterns to components, not CSS:

```tsx
// BAD: repeated class strings
<button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">

// GOOD: extracted component
function PrimaryButton({ children, ...props }: ButtonProps) {
  return (
    <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700" {...props}>
      {children}
    </button>
  );
}
```

## Testing React Components

### Component Tests with Testing Library
```tsx
import { render, screen, fireEvent } from "@testing-library/react";

test("UserCard calls onSelect with email when clicked", () => {
  const onSelect = vi.fn();
  render(<UserCard name="Alice" email="alice@test.com" onSelect={onSelect} />);

  fireEvent.click(screen.getByText("Alice"));
  expect(onSelect).toHaveBeenCalledWith("alice@test.com");
});
```

### Hook Tests
```tsx
import { renderHook, act } from "@testing-library/react";

test("useAgentStream starts in non-streaming state", () => {
  const { result } = renderHook(() => useAgentStream("test"));
  expect(result.current.isStreaming).toBe(false);
  expect(result.current.chunks).toEqual([]);
});
```

## Build & Dev Commands

```bash
# Development
cd frontend && npm run dev       # Start Vite dev server

# Build
cd frontend && npm run build     # Production build

# Test
cd frontend && npm run test      # Vitest unit tests

# Lint
cd frontend && npm run lint      # ESLint + TypeScript check
```
