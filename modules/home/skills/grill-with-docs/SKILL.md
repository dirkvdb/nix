---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design against the codebase, recording resolved domain terms and important decisions in docs.
disable-model-invocation: true
---

Read the repository's existing `CONTEXT.md`, `CONTEXT-MAP.md`, and relevant ADRs before questioning the user. Inspect the codebase when facts are needed; do not ask the user for facts that can be looked up.

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it. Work in **rounds**. The **frontier** is every decision whose prerequisites are already settled. Ask the whole frontier in one round, number each question, and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like so:

```
❓ **Q1** - **<question title>**: <question body, including choices where useful>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, including choices where useful>

➡️ <your recommended answer>
```

Each round the user's answers reshape the tree. Recompute the frontier after every response. A question whose answer depends on another question still open in this round belongs to a later round.

Actively build the project's domain model as decisions become clear:

- Challenge terms that conflict with `CONTEXT.md` and propose precise canonical terms for vague or overloaded language.
- Use concrete edge-case scenarios to test boundaries between concepts.
- Check claims about behavior against the code and surface contradictions.
- When a domain term is resolved, update the appropriate `CONTEXT.md` immediately. Keep it free of implementation details.
- Create an ADR only for a hard-to-reverse, surprising trade-off with meaningful alternatives. Create ADR directories lazily and follow the repository's existing format.

Dispatch a sub-agent to investigate environment or codebase facts when useful, without blocking unrelated frontier questions. The decisions are the user's: ask them and wait.

The session is done when the frontier is empty: every branch of the design tree was visited and nothing remains silently assumed. Do not implement anything until the user confirms that a shared understanding has been reached.
