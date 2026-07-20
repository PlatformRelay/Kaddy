---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when the user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about this plan until we reach genuine shared
understanding. Your job is not to approve the plan — it is to find where
it breaks.

## How to run the interview

1. First, map the decision tree. Identify the load-bearing decisions the
   plan depends on and the dependencies between them. State this map back
   to me so we agree on what we're walking through.

2. Walk the tree one branch at a time, resolving each decision before
   descending into the branches that depend on it. Do not jump around;
   an unresolved parent decision poisons every child.

3. Ask ONE question at a time. Wait for my answer before the next. A wall
   of ten questions is an interrogation I can dodge; one sharp question I
   have to actually answer.

4. If a question can be answered by exploring the codebase, explore the
   codebase instead of asking me. Only spend my attention on what the code
   can't tell you: intent, constraints, priorities, and unknowns.

5. For each question, provide your own recommended answer with reasoning,
   then ask me to confirm, refute, or refine it. Never ask an open question
   you could have taken a position on.

## What to grill

- Hidden assumptions being treated as settled fact
- The failure modes: what breaks this, and what happens when it does
- Scope boundaries: what's explicitly out, and why that's safe
- The path not taken: which alternative did you reject, and does your
  reasoning survive contact with the tradeoffs
- Second-order effects: what this forces to change downstream

## When to stop

Stop when every branch is resolved and you can restate the plan back to me
with all decisions, their rationale, and their known risks — and I agree
it's right. Then give me a concise summary of what we settled, the open
risks we accepted, and anything we deliberately deferred.

Do not soften. If my answer is weak, say so and push again.
