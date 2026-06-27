# Open Source Repo Shortlist

Last reviewed: June 26, 2026

This shortlist is optimized for:

- high-quality repositories with real adoption
- active or recent contribution surfaces
- alignment with Andrew's Python, TypeScript, React, full-stack, and debugging skills
- realistic first-contribution paths instead of random high-star vanity targets

## Top Picks

### 1. `rtk-ai/rtk`

- Repo: [rtk-ai/rtk](https://github.com/rtk-ai/rtk)
- Stars: `66.2k`
- Forks: `4.1k`
- Stack: Rust, CLI tooling, cross-platform behavior, docs
- Why it is strong:
  - extremely high star signal
  - active issue tracker
  - fresh good-first-issue queue
  - visible Windows and CLI bugs that reward careful debugging
- Best issue entry points:
  - [#2627](https://github.com/rtk-ai/rtk/issues/2627) `rtk diff` reports identical files when they differ only by CRLF vs LF
  - [#2471](https://github.com/rtk-ai/rtk/issues/2471) `rtk init` drops `kubectl get` in Copilot mode
  - [#2503](https://github.com/rtk-ai/rtk/issues/2503) Windows hook documentation clarification
- Recommendation:
  - best repo for maximum impact-per-contribution if you are willing to work in Rust or docs/tooling

### 2. `cherrypy/cheroot`

- Repo: [cherrypy/cheroot](https://github.com/cherrypy/cheroot)
- Stars: `201`
- Forks: `101`
- Stack: Python, HTTP server internals, tests, typing
- Why it is strong:
  - mature infrastructure project
  - respected Python OSS surface
  - cleaner engineering contribution path than many flashy repos
  - local clone already available
- Best issue entry points:
  - [#384](https://github.com/cherrypy/cheroot/issues/384) add type hints
- Caveat from local history review:
  - local history already contains Python 3.14 support commits and changelog fragments tied to `#767`
  - local history also shows prior work related to `#756`
  - that makes both issues weaker first-PR targets than they appeared from the issue list alone
- Recommendation:
  - still a high-quality Python repo, but the currently obvious issue entry points are weaker than `rtk`

### 3. `supabase/supabase`

- Repo: [supabase/supabase](https://github.com/supabase/supabase)
- Stars: `105k`
- Forks: `12.9k`
- Stack: TypeScript, React, Postgres, platform/product engineering
- Why it is strong:
  - strongest star and ecosystem signal in your current stack
  - highly relevant to your React/TypeScript/Supabase background
  - massive real-world usage
- Current visible contribution issue:
  - [#6435](https://github.com/supabase/supabase/issues/6435) allow newlines in SMS OTP template
- Recommendation:
  - excellent long-term target for stack alignment, but weaker current starter-issue surface than `rtk` or `cheroot`

### 4. `WordPress/gutenberg`

- Repo: [WordPress/gutenberg](https://github.com/WordPress/gutenberg)
- Stars: `11.7k`
- Forks: `4.8k`
- Stack: JavaScript, TypeScript, build tooling, editor/platform workflows
- Why it is strong:
  - very large real-world impact
  - stable contributor pipeline
  - active curated issues
- Best visible issue entry points:
  - [#78203](https://github.com/WordPress/gutenberg/issues/78203) remove custom `job_status` output in favor of native result
  - [#76579](https://github.com/WordPress/gutenberg/issues/76579) original PRs may not be tagged properly after manual cherry-pick
  - [#76576](https://github.com/WordPress/gutenberg/issues/76576) improve manual `git cherry-pick` instructions
- Recommendation:
  - strong target if you want contributor credibility in a big JS ecosystem, especially for tooling/process improvements

### 5. `hoppscotch/hoppscotch`

- Repo: [hoppscotch/hoppscotch](https://github.com/hoppscotch/hoppscotch)
- Stars: `79.6k`
- Forks: `5.9k`
- Stack: TypeScript, web tooling, product engineering, API tooling
- Why it is strong:
  - very high star count
  - highly relevant web/product/tooling space
  - practical developer-tool audience
- Visible contribution issue:
  - [#4136](https://github.com/hoppscotch/hoppscotch/issues/4136) revisit existing unit tests for the CLI
- Recommendation:
  - strong option if you want a high-star TypeScript/product repo with a test-quality entry point

## Secondary Picks

### 6. `TanStack/query`

- Repo: [TanStack/query](https://github.com/TanStack/query)
- Stars: `49.8k`
- Forks: `3.9k`
- Stack: TypeScript, React, data fetching, ecosystem library work
- Why it is strong:
  - elite React/TS ecosystem reputation
  - very useful brand signal if you can land a contribution
- Caveat:
  - current contribution page did not surface an easy starter issue in this pass
- Recommendation:
  - keep on the list, but not the fastest first move

### 7. `fastapi/fastapi`

- Repo: [fastapi/fastapi](https://github.com/fastapi/fastapi)
- Stars: `99.7k`
- Forks: `9.5k`
- Stack: Python, APIs, typing, backend frameworks
- Why it is strong:
  - huge Python/backend signal
  - strong match for your Flask/API experience
- Caveat:
  - a search pass surfaced issue `#10236` with `good first issue` labeling, but that issue is now closed
  - no especially clear current live starter issue surfaced during this pass
- Recommendation:
  - high-prestige target, but still not as immediately actionable as `rtk`, `hoppscotch`, or `gutenberg`

### 8. `adbar/htmldate`

- Repo: [adbar/htmldate](https://github.com/adbar/htmldate)
- Stars: `153`
- Forks: `31`
- Stack: Python, parsing, CLI, testing, docs
- Why it is decent:
  - approachable Python utility
  - local clone already available
- Visible contribution issues:
  - [#8](https://github.com/adbar/htmldate/issues/8) test htmldate on further web pages and report bugs
  - [#6](https://github.com/adbar/htmldate/issues/6) improve documentation clarity and consistency
- Recommendation:
  - lower signal than `cheroot`, but good if you specifically want a lighter Python contribution

### 9. `vercel/next.js`

- Repo: [vercel/next.js](https://github.com/vercel/next.js)
- Stars: `140k`
- Forks: `31.3k`
- Stack: React, framework internals, SSR/build/runtime behavior
- Why it is strong:
  - elite prestige signal in your strongest ecosystem
  - clear long-term brand value if you land a contribution
- Visible contribution issues:
  - [#41281](https://github.com/vercel/next.js/issues/41281) inconsistent error messaging in `getStaticPaths`
  - [#38863](https://github.com/vercel/next.js/issues/38863) POST request succeeds for pages with `next dev`
  - [#20924](https://github.com/vercel/next.js/issues/20924) misleading `next-head-count is missing` error
- Caveat:
  - the surfaced issues look older and not obviously starter-scoped
- Recommendation:
  - high-prestige target, but not the cleanest first contribution path

### 10. `refinedev/refine`

- Repo: [refinedev/refine](https://github.com/refinedev/refine)
- Stars: `35k`
- Forks: `3.1k`
- Stack: React, TypeScript, admin/product framework work
- Why it is interesting:
  - excellent stack match
  - meaningful React ecosystem signal
- Caveat:
  - current contribution page explicitly shows no curated good-first issues
- Recommendation:
  - good repo to watch, but weaker immediate entry point than `hoppscotch`

### 11. `TheOdinProject/curriculum`

- Repo: [TheOdinProject/curriculum](https://github.com/TheOdinProject/curriculum)
- Stars: `12.7k`
- Forks: `16.4k`
- Stack: web development curriculum, docs/content/community contribution
- Why it is interesting:
  - respected web-dev learning ecosystem
  - could support writing/docs/content improvements if you want non-code OSS signal
- Caveat:
  - no current curated good-first issues surfaced on the contribution page
- Recommendation:
  - lower priority for code-first contribution goals

### 12. `httpie/cli`

- Repo: [httpie/cli](https://github.com/httpie/cli)
- Stars: `38.2k`
- Forks: `4k`
- Stack: Python, CLI tooling, API developer tooling
- Why it is strong:
  - very good Python/dev-tool signal
  - practical product with a real user base
  - nice fit if you want Python plus tooling rather than backend framework internals
- Caveat:
  - current contribution page shows no curated good-first issues
- Recommendation:
  - strong Python watchlist repo, but not an obvious first PR target today
- Extra note:
  - the contributing guide explicitly says documentation improvements and tests for existing behavior are likely to be merged, so `httpie` is a good fallback if you want a documentation-or-test-heavy Python contribution

### 13. `Textualize/textual`

- Repo: [Textualize/textual](https://github.com/Textualize/textual)
- Stars: `36.4k`
- Forks: `1.2k`
- Stack: Python, UI framework, terminal/web app framework
- Why it is strong:
  - high-quality modern Python project
  - distinctive ecosystem and strong brand among Python developers
- Caveat:
  - current contribution page shows no curated good-first issues
- Recommendation:
  - excellent prestige Python repo to watch, but weaker immediate entry surface

### 14. `fastapi/typer`

- Repo: [fastapi/typer](https://github.com/fastapi/typer)
- Stars: `19.7k`
- Forks: `921`
- Stack: Python, CLI tooling, type hints
- Why it is strong:
  - respected Python CLI library
  - aligned with tooling-oriented Python work
- Caveat:
  - current contribution page shows no curated good-first issues
- Recommendation:
  - good Python watchlist repo, but not a top immediate target

### 15. `encode/starlette`

- Repo: [encode/starlette](https://github.com/encode/starlette)
- Stars: `12.4k`
- Forks: `1.2k`
- Stack: Python, ASGI/web framework internals
- Why it is strong:
  - respected web framework infrastructure project
  - excellent signal for backend/Python credibility
- Caveat:
  - current contribution page shows no curated good-first issues
- Recommendation:
  - high-quality Python framework repo to watch, not the best first contribution target from current evidence

## Action Buckets

### Pursue Now

These are the strongest current contribution targets based on repo quality plus issue quality.

1. `rtk-ai/rtk`
2. `hoppscotch/hoppscotch`
3. `WordPress/gutenberg`

### Clone Next

These are worth preparing locally, but only after checking that the issue still needs work.

1. `cherrypy/cheroot`
2. `supabase/supabase`

### Watch Weekly

These are strong repos with real prestige, but the current issue surface is weaker or less clearly starter-scoped.

1. `cherrypy/cheroot`
2. `TanStack/query`
3. `fastapi/fastapi`
4. `httpie/cli`
5. `Textualize/textual`
6. `fastapi/typer`
7. `encode/starlette`

### Prestige Watchlist

These are excellent long-term brand-name targets, but not the cleanest first-contribution paths from the current evidence.

1. `vercel/next.js`
2. `supabase/supabase`
3. `fastapi/fastapi`
4. `TanStack/query`

## High-Confidence Targets After Re-Check

If the question is "which repos look best right now, not just in theory?", the strongest current set is:

1. `rtk-ai/rtk`
2. `hoppscotch/hoppscotch`
3. `WordPress/gutenberg`
4. `cherrypy/cheroot`

Why this grouping is stronger than the rest:

- `rtk` currently has multiple fresh open issues, including `#2627`, marked `good first issue` and opened on June 25, 2026.
- `hoppscotch` currently has an open `good first issue` on CLI test stabilization (`#4136`) with no linked branches or pull requests.
- `gutenberg` still exposes a curated contribution page where the listed issues are explicitly described as `good first issue` selections for first-time contributors.
- `cheroot` still has an open `good first issue` (`#384`), but local history review makes it a weaker first move than the three above.

## Best Three To Act On Now

If you want the shortest path from research to a real contribution, these are the best current bets:

### Top Candidate Matrix

Quick comparison for the repos most worth acting on immediately:

| Repo | Visibility Signal | Setup Friction | Issue Clarity | Time to First Useful PR | Best Fit |
| --- | --- | --- | --- | --- | --- |
| `rtk-ai/rtk` | High | Low | Very high | Fast | bug-fix oriented debugging |
| `hoppscotch/hoppscotch` | High | Medium | High | Medium | TypeScript testing/tooling |
| `WordPress/gutenberg` | High | Medium | Medium-high | Medium | structured JS ecosystem contribution |
| `cherrypy/cheroot` | Medium | Low | Medium | Medium | Python infrastructure credibility |

How to read this:

- `rtk` is the best choice if you want the fastest credible path to a merged technical fix.
- `hoppscotch` is the best choice if you want your contribution to stay close to TypeScript and test quality work.
- `gutenberg` is the best choice if you want a large-name ecosystem repo with explicit newcomer guidance.
- `cheroot` is still respectable, but the issue surface is less crisp than the top three.

### 1. `rtk-ai/rtk`

- Best for:
  - highest-visibility bug fix with fresh issue activity
- Why now:
  - `#2627` is fresh, open, marked `good first issue`, and matches the current local implementation pattern in the cloned repo
- Expected effort:
  - medium engineering effort
  - lower ambiguity than most framework/library issues
- First step:
  - reproduce `#2627` locally in the existing `rtk` clone and confirm the CRLF/LF behavior with a focused failing test

### 2. `hoppscotch/hoppscotch`

- Best for:
  - a strong TypeScript/testing contribution in a high-star developer-tool repo
- Why now:
  - `#4136` is still open, labeled `good first issue`, and currently shows no linked branches or pull requests
  - the local shallow clone confirms the CLI lives in `packages/hoppscotch-cli`
  - the package already runs tests through `vitest`, but the test tree still contains `jest.mock(...)` usage and explicit skipped tests, which matches the issue description closely
- Expected effort:
  - medium effort with more repo setup than `rtk`
  - more test-maintenance oriented than bug-fix oriented
- First step:
  - clone the repo, locate the disabled CLI tests referenced by `#4136`, and estimate whether the work is mostly Vitest migration, flaky assertion cleanup, or CI wiring

### 3. `WordPress/gutenberg`

- Best for:
  - a structured first contribution path in a large JavaScript ecosystem project
- Why now:
  - the repo still maintains a curated contributor queue and current issues such as `#78203` and `#76579` remain open with `good first issue` labeling
  - the local shallow clone confirms the relevant automation surface is real: `build-plugin-zip.yml` already uses `needs.build.result`, and the repo includes dedicated cherry-pick automation under `.github/workflows/cherry-pick-wp-release.yml`
- Expected effort:
  - small-to-medium effort if you choose workflow/tooling issues
  - likely more process and repo-orientation overhead than `hoppscotch`
- First step:
  - inspect the current `good first issue` queue and prefer GitHub Actions or build-tooling tasks like `#78203` before broader product-facing issues

## Final Recommendation

If you want one clear answer for what to do next, use this:

- Pick `rtk-ai/rtk` if your priority is the strongest immediate contribution opportunity.
- Pick `hoppscotch/hoppscotch` if your priority is staying close to TypeScript and test/tooling work.
- Pick `WordPress/gutenberg` if your priority is contributor credibility in a large JavaScript ecosystem with a curated onboarding path.
- Pick `cherrypy/cheroot` only if you specifically want Python infrastructure signal and are comfortable with a less crisp issue surface.

Scenario-based recommendation:

- Fastest path to a solid PR: `rtk-ai/rtk`
- Best TypeScript-first path: `hoppscotch/hoppscotch`
- Best large-ecosystem newcomer path: `WordPress/gutenberg`
- Best Python-specific fallback: `cherrypy/cheroot`
- Best long-term prestige watch targets: `supabase/supabase`, `vercel/next.js`, `fastapi/fastapi`

## Personal Recommendation

For Andrew specifically:

1. Start with `rtk` if you want the best mix of issue quality, repo visibility, and realistic path to a meaningful PR.
2. Start with `hoppscotch` if you want the cleanest high-star TypeScript/testing contribution path.
3. Keep `gutenberg` in the top tier if you want a large JS ecosystem repo with a more structured first-contribution path.
4. Keep `supabase` as the most stack-aligned prestige repo to monitor for a better issue surface.
5. Keep `next.js` as the highest-prestige React ecosystem repo on the list, but treat it as a longer-shot target.
6. Keep `cheroot`, `httpie`, `textual`, `typer`, and `starlette` as Python credibility targets to revisit when a stronger issue appears.

## Best First PR Targets

These are ranked not just by repo quality, but by whether the issue itself looks like a strong use of time.

### 1. `rtk-ai/rtk` issue `#2627`

- Issue: [rtk diff reports "Files are identical" when files differ only in line endings (CRLF vs LF)](https://github.com/rtk-ai/rtk/issues/2627)
- Why it ranks first:
  - very fresh issue (`opened on Jun 25, 2026`)
  - crisp reproduction steps already provided
  - concrete bug with observable behavior
  - strong Windows relevance
  - high-star repo means good visibility if fixed well
- Tradeoff:
  - requires Rust work
- Best for:
  - strongest impact signal if you can handle a debugging-heavy CLI fix

### 2. `hoppscotch/hoppscotch` issue `#4136`

- Issue: [Revisit existing unit tests for the CLI](https://github.com/hoppscotch/hoppscotch/issues/4136)
- Why it is promising:
  - high-star TypeScript ecosystem repo
  - visible testing/CLI quality work
  - relevant if you want to show test discipline and tooling improvement
- Tradeoff:
  - older issue (`opened on Jun 20, 2024`)
  - more maintenance-oriented than product/bug-fix oriented
  - the local shallow clone is enough for issue triage, but full setup will still take more effort than `rtk`
- Best for:
  - TypeScript/tooling contribution if you want a modern web-dev-adjacent target

### 3. `cherrypy/cheroot` issue `#384`

- Issue: [Add type hints](https://github.com/cherrypy/cheroot/issues/384)
- Why it still belongs on the board:
  - respected Python infrastructure repo
  - local clone already available
  - good fit if you want Python/library signal
- Tradeoff:
  - lower repo-visibility payoff than `rtk` or `hoppscotch`
  - the currently obvious issue surface is weaker than it first appeared
  - higher chance of spending time validating scope before writing code
- Best for:
  - Python-focused follow-up after you land momentum elsewhere

### 4. `supabase/supabase` issue `#6435`

- Issue: [Allow newlines in SMS OTP template](https://github.com/supabase/supabase/issues/6435)
- Why it is lower:
  - stack-aligned and prestigious repo
  - feature request is understandable
- Tradeoff:
  - old issue (`opened on Sep 20, 2021`)
  - weaker signal that it is still the best current entry point
  - less confidence that it is a fast, clean first contribution
- Best for:
  - long-term interest in Supabase, not first priority

## Current Recommendation

If you want one repo to pursue first:

1. Choose `rtk` if you want the strongest immediate PR target.
2. Choose `hoppscotch` if you want the best TypeScript-first contribution path.
3. Choose `gutenberg` if you want a large, structured JavaScript ecosystem project with curated first issues.
4. Treat `cheroot` as a Python watch target, not the default first move.
5. Treat `supabase` and `next.js` as strategic prestige targets rather than immediate first-PR targets.

## Execution Order

If the goal is to build momentum fast without wasting time:

1. Attempt `rtk #2627` first.
2. If you want a TypeScript lane in parallel, clone `hoppscotch` and inspect `#4136`.
3. If you want a non-Rust path with real contributor onboarding, inspect the current `gutenberg` contribution queue next.
4. Re-check `supabase`, `fastapi`, and `cheroot` once a week for fresher issues with clearer scope.
5. Only spend time on `next.js` after you already have at least one merged OSS contribution in a strong repo.

## Python-Side Takeaway

Current evidence suggests an important pattern:

- several of the best Python prestige/tooling repos (`fastapi`, `starlette`, `httpie`, `textual`, `typer`) are strong long-term targets
- but many of them currently do **not** expose curated good-first issues on their GitHub contribution pages
- so if your goal is **immediate contribution momentum**, the strongest live targets remain `rtk` and `hoppscotch`
- if your goal is **long-term Python ecosystem credibility**, the best watchlist repos are:
  1. `fastapi/fastapi`
  2. `httpie/cli`
  3. `Textualize/textual`
  4. `encode/starlette`
  5. `fastapi/typer`

## Feasibility Notes

- `rtk #2627` looks especially strong because the local code still reads files with `read_to_string(...).lines()`, which naturally erases CRLF vs LF distinctions. That means the reported behavior is consistent with the current implementation and likely fixable.
- `hoppscotch #4136` looks technically real because the local CLI package already mixes a `vitest` runner with older `jest`-style mocking patterns and explicit skipped tests, so there is a concrete migration/stabilization surface to work on.
- `gutenberg` is more contributor-process heavy than `rtk`, but the local clone shows the exact workflow/cherry-pick files referenced by the current issues, which makes the curated queue more trustworthy.
- `cheroot #767` looks weaker as a first target because the local history already includes:
  - commits declaring Python 3.14 support
  - changelog fragments explicitly tied to `#767`
- `cheroot #756` also looks less attractive as a first target because the local history already includes prior fixes related to file descriptor handling.
