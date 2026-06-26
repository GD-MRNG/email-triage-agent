# n8n — How It Works

## The Core Idea

A computation can be represented as a graph of nodes, where each node does one thing and passes its output to the next.

Each node receives data, transforms it in some way, and emits data. The transformation can be anything — making an HTTP request, filtering a list, calling an API, evaluating a condition, formatting a string. The node doesn't care what came before it or after it. It just does its one thing.

The mental model: **n8n is a runtime for function composition, where the functions are integrations and the composition is visual.**

---

## Key Concepts

**Triggers**
Every workflow has a starting point. Triggers are either time-based (run at 9am every day) or event-based (run when an HTTP request arrives). Everything downstream of the trigger is deterministic.

```js
// Conceptual sketch — what a webhook trigger looks like under the hood
app.post('/webhook/email-triage', (req, res) => {
  const triggerOutput = [{ json: req.body }]  // normalised into the standard data shape
  engine.run(workflow, triggerOutput)           // handed off to the execution engine
})

// A cron trigger looks different on the surface, but produces the same shape
cron.schedule('0 9 * * *', () => {
  const triggerOutput = [{ json: { firedAt: new Date().toISOString() } }]
  engine.run(workflow, triggerOutput)
})
```

**Branching**
A node can evaluate its input and route execution down different paths depending on the result. This turns a linear pipeline into a decision tree — where most of the expressive power comes from.

```js
// Conceptual sketch — what a Switch node is doing
function switchNode(input) {
  const classification = input[0].json.classification  // read a field from incoming JSON

  switch (classification) {
    case 'urgent':     return { branch: 0, data: input }
    case 'actionable': return { branch: 1, data: input }
    case 'fyi':        return { branch: 2, data: input }
    default:           return { branch: 3, data: input }  // fallback
  }
  // the engine routes execution to whichever downstream nodes
  // are connected to the matching branch output
}
```

**Data model**
Every node passes an array of JSON objects to the next node. No type system, no schema enforcement — just JSON flowing through a graph. You can connect anything to anything, but you're responsible for knowing what shape the data is in at each step.

```js
// Every node receives and returns this shape — always an array of items
const input = [
  { json: { from: 'alice@example.com', subject: 'Urgent: contract renewal' } },
  { json: { from: 'bob@example.com',   subject: 'FYI: new policy doc' } },
]

// A node that adds a field — still returns the same shape
function setNode(input) {
  return input.map(item => ({
    json: {
      ...item.json,
      processedAt: new Date().toISOString(),  // added field
    }
  }))
}

// output: same array structure, with new field on each item
```

**Integration**
What n8n is really doing is making integration cheap. The hard part of connecting two systems is usually authentication, API quirks, and data transformation. Pre-built nodes handle the first two; the graph handles the third.

```js
// Without n8n — you handle auth, HTTP, errors, retries yourself
const token = await getOAuthToken(clientId, clientSecret)
const res = await fetch('https://api.example.com/messages', {
  headers: { Authorization: `Bearer ${token}` }
})
const data = await res.json()

// With n8n — auth is stored as a credential, injected at runtime
// Your node just calls the SDK or HTTP node with a named credential
// The engine handles token refresh, injection, and encryption
execute(credentials: { apiToken: string }, input: Item[]) {
  return callApi(credentials.apiToken, input[0].json.query)
}
```

---

## How It's Implemented

n8n is a Node.js application. That choice is load-bearing — almost everything about how it works follows from it.

**Execution engine**
The core runtime walks a workflow graph. When a trigger fires, the engine traverses the node graph in dependency order, determines the execution sequence, and runs each node in turn. The output of each node becomes the input to the next.

**Nodes**
TypeScript classes that implement a common interface. Each has an `execute()` method containing the actual logic — an HTTP call, a database query, an SDK call. The engine doesn't know or care what's inside; it calls `execute()` and expects JSON back.

**Credentials**
Stored encrypted in the database (SQLite by default, Postgres in production), and injected into a node at execution time. The node asks for a credential by type; the engine fetches, decrypts, and passes it in. This is why you can swap credentials without touching the workflow itself.

**Workflow definition**
Just JSON — the same JSON you export when you download a workflow file. It describes the graph: which nodes exist, how they're connected, what parameters each node has. At execution time the engine deserialises this and walks it. Importing a workflow is trivial because you're just loading a JSON document.

**Trigger types**
Implemented differently depending on type, but normalised into the same execution model once they fire:
- Webhook triggers register an Express route on startup
- Polling triggers run on a scheduler
- Event-based triggers use websockets or long-polling

**The UI**
A separate Vue.js frontend that talks to the Node.js backend over a REST API. It's a graph editor — it reads and writes workflow JSON. The visual canvas is a rendering of the same data structure the engine executes. There's no translation step between what you see and what runs.

---

## The Practical Takeaway

n8n is less exotic than it looks. Strip away the visual interface and you have a Node.js process that reads a JSON config, makes a series of HTTP calls in a defined order, and passes data between them. The sophistication is in the execution engine's handling of branching, error paths, and parallel execution — not in any fundamentally novel architecture.