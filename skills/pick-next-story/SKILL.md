---
name: pick-next-story
description: Return the single next backlog item for kaddy without starting the full agent loop.
---

# pick-next-story — kaddy

1. Read [docs/ROADMAP.md](../docs/ROADMAP.md) and [agent-context/BACKLOG.md](../agent-context/BACKLOG.md).
2. Respect lane dependencies in BACKLOG (E2 spike front-loaded after E1 cluster; E7 after E4+E5).
3. Skip epics marked **cuttable** (E0, E10) unless operator explicitly requests them.
4. Return one story: ID, OpenSpec change path, Given/When/Then summary, gate commands, disjoint paths for worktree.
5. If blocked on operator (INBOX decision), say so and stop.
