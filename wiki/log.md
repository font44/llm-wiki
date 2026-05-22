---
title: "Log"
created: 2026-05-22
updated: 2026-05-22
tags: []
---

# Template

Append-only stream of everything the user says that isn't an ingest, a query, a lint, or an explicit `living/` update. Newest entries at the top. Each entry:

```
## [YYYY-MM-DD HH:MM] short heading
free-text body
```

During lint, recurring topics in this file get clustered and (with user approval) promoted into pages elsewhere in `wiki/`. Promoted entries are replaced here by a one-line pointer (`## [HH:MM] → [[path/to/page]]`).
