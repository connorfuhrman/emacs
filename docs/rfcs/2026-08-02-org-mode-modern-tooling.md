# RFC: Modern Org Mode tooling for Prelude + Nix Emacs

| Field | Value |
|-------|--------|
| Status | **Approved with changes** — implementing |
| Date | 2026-08-02 |
| Author | grok |
| Scope | `emacs-config/org-config.el`, `nix/emacsBase.nix`, optional new `orgctl` CLI package, note vault layout |
| Supersedes | ad-hoc `org-config.el` v0.3 |

## 1. Summary

This RFC proposes a layered upgrade to Org Mode on top of stock Emacs Org and
Prelude's `prelude-org`, tailored to a **disorganized human + AI agents**
workflow. The current config is a solid skeleton (env-driven agenda, inbox
capture, basic TODOs/tags/refile) but lacks modern presentation, a real notes
graph, deadline/dependency UX, fast note navigation, and any agent-facing
surface.

**Proposed north star:** plain-text Org files remain the source of truth;
Emacs is the primary editor with a pretty, low-friction UI; a small CLI/MCP
layer lets agents search, list, and mutate todos without fighting Elisp.

## 2. <!--c:907xq-->Goals (from you)<!--/c:907xq-->
<!--co:907xq by:Connor_Fuhrman at:2026-08-02T09:52:37.517Z status:resolved quote:"Goals (from you)"
Connor Fuhrman (2026-08-02T09:52:37.517Z): One more goal - I want to have a notebook style code execution and output experience just like jupyter but in org mode
grok (2026-08-02T10:02:46.000Z): Accepted G10 notebook/babel goal. Will wire org-babel + jupyter-style inline results in org-babel-config.el (phase 1).
-->

| # | Goal | Design response |
|---|------|-----------------|
| G1 | Pretty inline renders and views | `org-modern` + `org-appear` + optional LaTeX/image previews |
| G2 | Note-taking with mind maps | Note system (`org-roam` *or* `org-node`/`denote`) + graph UI |
| G3 | Searchable for AI agents | Stable vault layout, IDs, properties, `rg`-friendly text + CLI |
| G4 | Todos: due dates + dependencies | Agenda + `org-super-agenda` + `org-edna` + capture discipline |
| G5 | Works when you are disorganized | Aggressive inbox, few decisions at capture time, weekly review |
| G6 | AI can help the todo list | `orgctl` CLI (+ optional MCP) over the same files |
| G7 | Categories and tags | Expanded tag/context system + FILETAGS + projects |
| G8 | View all notes / jump between them | Vertico/Consult finders + backlinks buffer |
| G9 | Modern tools | Prefer maintained MELPA packages already in nixpkgs |
| G10 | Jupyter-style notebook code exec in Org | `org-babel` + `jupyter`/`ob-async` + inline results/images |

## 3. Non-goals

- Replacing Prelude or abandoning Nix packaging.
- Building a second brain app outside Emacs (Obsidian/Logseq as primary).
  Cross-linking *to* Obsidian is fine later; Org stays canonical for todos.
- Full GTD orthodoxy or complex custom Elisp frameworks (org-gtd, org-super-links
  stacks) in v1.
- P<!--c:2i9tn-->erfect mobile parity in v1 (can add Orgzly / beorg later).<!--/c:2i9tn-->
<!--co:2i9tn by:me at:2026-08-02T09:50:31.730Z status:resolved quote:"erfect mobile parity in v1 (can add Orgzly / beorg later)."
me (2026-08-02T09:50:31.730Z): mobile is out of scope
grok (2026-08-02T10:02:46.000Z): Confirmed: mobile remains out of scope.
-->

## 4. Current-state audit

### 4.1 What you already have

**Packaging**

- Nix flake: Prelude + personal `emacs-config`, no runtime package download.
- Packages in `nix/emacsBase.nix`: Vertico/Consult/Orderless/Marginalia/Embark,
  Helm + helm-ag (ripgrep), Dashboard (shows agenda), envrc, vterm, etc.
- **No** org-modern, org-roam/denote, org-ql, org-super-agenda, org-edna,
  org-download, org-appear, or any org-specific pretty packages.

**Prelude org (`prelude-org`)**

- Global keys: `C-c l` store-link, `C-c a` agenda, `C-c c` capture, `C-c b` switchb.
- Enables `org-habit`, `org-indent-mode`, log-done into drawer.
- Keymap fixes so Org owns `C-a` / list cycling.

**Personal `org-config.el`**

- Agenda built from `ORG_DIRECTORIES` (recursive `*.org`) + `$ORG_DIRECTORY/inbox.org`.
- Capture: inbox note, meeting (datetree), standalone TODO.
- TODO sequence: `TODO → NEXT → WAITING | DONE / CANCELLED`.
- Tags: `@work` `@home` `@computer`, `meeting` `project` `urgent` `read`.
- Refile to agenda files maxlevel 3; outline-path completion.
- Optional load of `$ORG_DIRECTORY/config.el`.

**Gaps vs goals**

| Goal                   | Gap                                                                            |
| ---------------------- | ------------------------------------------------------------------------------ |
| Pretty UI              | Stock faces only; no modern bullets, todo pills, hide-markers                  |
| Mind map / notes graph | No roam/denote/node; no backlinks; no graph view                               |
| AI search              | Files are plain text (good) but no ID convention, no CLI, env vars often unset |
| Due + depends          | No SCHEDULED/DEADLINE in templates; no edna/depend; no super-agenda grouping   |
| Disorganized UX        | Capture is thin; no process for "what do I do today"; no review agenda         |
| Agent tooling          | None                                                                           |
| Navigate notes         | `org-switchb` + project rg only; no note title index                           |

### 4.2 Constraint: Nix + Prelude

Everything new must:

1. Be added to `emacsPackages` in `nix/emacsBase.nix` <!--c:ahex2-->(or a split `emacsOrg.nix`)<!--/c:ahex2-->.
2. Be configured in `emacs-config/` (prefer growing `org-config.el` or
   `org-config/*.el` modules, not random `personal/`).
3. Not require `package-install` at runtime (`:ensure nil` pattern you already use).
4. Respect env-driven vault roots (`ORG_DIRECTORY` / `ORG_DIRECTORIES`) so
   machines and agents share the same paths via direnv/home-manager.
<!--co:ahex2 by:Connor_Fuhrman at:2026-08-02T09:51:40.941Z status:resolved quote:"(or a split `emacsOrg.nix`)"
Connor Fuhrman (2026-08-02T09:51:40.941Z): this project is growing. Let's bring into scope that you will break this out into more logical flake parts modules
grok (2026-08-02T10:02:46.000Z): In scope: splitting Nix into logical flake-parts modules (emacs packages, org packages, orgctl, wrapper).
-->

## 5. Design principles

1. **Capture is cheap; organize is deferred.** Inbox first. Tags/projects optional
   at capture time. Refile and `NEXT` promotion happen in short review bursts.
2. **Plain text is the API.** Agents never need Emacs running for *read*; writes
   go through a small validated CLI (or Emacs batch) so structure stays valid.
3. **One vault root.** `$ORG_DIRECTORY` is canonical. Extra roots in
   `ORG_DIRECTORIES` are for archive or work silos, not a second brain.
4. **IDs everywhere that matters.** Every project note and every actionable TODO
   that participates in deps/links gets an `ID` property (org-id / roam).
5. **Pretty is optional chrome.** Visual packages must degrade cleanly in TTY
   (`emacs-nox` on servers) — you already ship nox variants.
6. **Few concepts.** Inbox, Projects, Areas, Resources, Archive (PARA-lite) +
   Agenda. Avoid ten overlapping systems.

## 6. Recommended architecture

```text
                    ┌─────────────────────────────────────┐
                    │  Human: Emacs (Prelude + org-config) │
                    │  pretty UI · capture · agenda · roam │
                    └─────────────────┬───────────────────┘
                                      │ read/write
                                      ▼
┌──────────────┐   same files    ┌────────────────────────┐
│ AI agents    │◄───────────────►│  $ORG_DIRECTORY vault  │
│ opencode etc │   via orgctl    │  plain .org + .org-id  │
└──────┬───────┘                 └────────────────────────┘
       │ MCP or CLI
       ▼
┌──────────────┐
│ orgctl       │  list/search/add/done/refile/deps
│ (batch/Elisp │  + JSON output for agents
│  or go-org)  │
└──────────────┘
```

### 6.1 Org file discovery + state dir (approved)

**Not** a single PARA vault. Org files live anywhere under the home tree
(per-project dirs). A small state directory holds cache, inbox, and roam.

```text
Search roots:
  $ORG_DIRECTORIES  (semicolon-separated), else $HOME

Include:
  any file matching *.org under a search root

Exclude / prune:
  - if directory contains `.orgignore`, skip that directory and all children
  - built-in noise dirs: .git, node_modules, .cache, elpa, .direnv, result, …

State directory ($ORG_STATE_DIRECTORY, default ~/.org):
  inbox.org              # default capture target
  roam/                  # org-roam-directory (evergreen + mind map)
  cache/
    agenda-files         # discovered path list
  org-id-locations       # id index
  attachments/           # org-download default
  config.el              # optional local overrides
```

`ORG_DIRECTORY` remains accepted as an alias for the state directory for
backward compatibility.

<!--c:a1b2c3-->Vault layout: adopt PARA-lite under single ORG_DIRECTORY as above.<!--/c:a1b2c3-->
<!--co:a1b2c3 by:grok at:2026-08-02T09:43:10.000Z status:resolved quote:"Vault layout: adopt PARA-lite under single ORG_DIRECTORY as above."
grok (2026-08-02T09:43:10.000Z): Approve this tree, propose a flatter layout (e.g. only inbox + notes + projects), or describe your existing folders. Agents and capture templates will hard-depend on this.
Connor Fuhrman (2026-08-02T09:54:15.706Z): I will have folder all over the place. Let's assume that ANY DIRECTOY in `HOME` is fair game unless there is a .orgignore file in that directory then it and subdirectories are ignored. Anything that has a .org extension is considered
Connor Fuhrman (2026-08-02T09:57:29.071Z): I can have a ~/.org directory which has things like a cache and if I want to look at all my todos and it needs something like this then that it fine but I don't have just "one single org directory" I use org throughotu differnet directoreis categorized by ecah project
grok (2026-08-02T10:02:46.000Z): Rejected single PARA vault. Implementing multi-root discovery: any $HOME tree .org file is agenda-eligible unless a parent dir has .orgignore (prunes that subtree). State/cache/inbox/roam live under ~/.org (ORG_STATE_DIRECTORY).
-->

### 6.2 Layer stack

| Layer                | Responsibility                                                | Packages / tools                                                          |
| -------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------- |
| L0 Core Org          | TODOs, agenda, capture, tags, clock, habits                   | stock + Prelude                                                           |
| L1 Pretty            | Modern chrome, hide markup, previews                          | `org-modern`, `org-appear`, `valign`?, `org-fragtog`                      |
| L2 Notes graph       | Bidirectional notes, daily, graph                             | <!--c:zdlnf-->**decision:** roam vs node vs denote<!--/c:zdlnf-->         |
| L3 Agenda power      | Grouped agenda, queries, deps                                 | `org-super-agenda`, `org-ql`, `org-edna`                                  |
| L4 Friction reducers | Images, links, fill column                                    | `org-download`, `org-cliplink`, `visual-fill-column`, `mixed-pitch` (GUI) |
| L5 Agent surface     | CLI + conventions + <!--c:n8szo-->optional MCP<!--/c:n8szo--> | new <!--c:cffxt-->`orgctl`<!--/c:cffxt-->, ripgrep, JSON schemas                                       |
| L6 Navigation        | Jump anywhere                                                 | `consult`, `consult-org-roam` or org-node consult, Embark                 |
<!--co:zdlnf by:Connor_Fuhrman at:2026-08-02T09:54:43.942Z status:resolved quote:"**decision:** roam vs node vs denote"
Connor Fuhrman (2026-08-02T09:54:43.942Z): Do reserach and pick the best then tell me why you picked it
grok (2026-08-02T10:02:46.000Z): Picked org-roam (+ org-roam-ui, consult-org-roam). Why: best mind-map (roam-ui), mature ID/backlink model that matches agent ID contract, consult jump for G8, daily notes; DB is a cache only. org-node is faster but weaker graph UX; denote is greppable but weak on mind maps. Roam dir = ~/.org/roam; project .org files stay on agenda via discovery + org-id.
-->
<!--co:n8szo by:Connor_Fuhrman at:2026-08-02T09:54:57.427Z status:resolved quote:"optional MCP"
Connor Fuhrman (2026-08-02T09:54:57.427Z): just cli
grok (2026-08-02T10:02:46.000Z): CLI only; no MCP in this work.
-->
<!--co:cffxt by:Connor_Fuhrman at:2026-08-02T09:55:08.593Z status:resolved quote:"`orgctl`"
Connor Fuhrman (2026-08-02T09:55:08.593Z): write this entirely in elisp and use org tooling as you can to not reinvent the wheel
grok (2026-08-02T10:02:46.000Z): orgctl implemented as pure Elisp (org-element/org-ql/org-id) invoked via emacs --batch/--script; no go-org rewrite.
-->

## 7. Package recommendations

### 7.1 Pretty inline renders (G1) — high priority

| Package | Role | nixpkgs | Notes |
|---------|------|---------|-------|
| **org-modern** | Todo pills, fancy priorities, clean tables, stars | yes | Best single upgrade; pair with `org-indent` |
| **org-appear** | Show emphasis markers only near point | yes | Edit-friendly pretty mode |
| **org-fragtog** | Auto LaTeX fragment preview on point | yes | Optional; needs latex in PATH for GUI |
| **valign** | Pixel-aligned tables (GUI) | yes | Skip on TTY |
| **visual-fill-column** + **mixed-pitch** | Readable prose width / fonts | yes | GUI only; keep TTY plain |
| org-superstar | Fancy bullets only | yes | **Skip if org-modern** — overlapping |

**Config sketch**

```elisp
(use-package org-modern
  :ensure nil
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :config
  ;; Keep stars for structure; modernize the rest
  (setq org-modern-star 'replace
        org-modern-table t
        org-modern-checkbox t))

(use-package org-appear
  :ensure nil
  :hook (org-mode . org-appear-mode)
  :custom (org-appear-autolinks t)
          (org-appear-autoentities t)
          (org-appear-autosubmarkers t))
```

TTY: enable org-modern (works) + org-appear; disable mixed-pitch/valign/fragtog
when `(not (display-graphic-p))`.

### 7.2 Note system + mind maps (G2, G8) — decision required

Three viable modern options, all in nixpkgs:

| Option | Pros | Cons | Mind map |
|--------|------|------|----------|
| **A. org-roam v2** | Mature, huge ecosystem, `org-roam-ui` graph in browser, consult integration, daily notes | Heavier DB (emacsql/sqlite), more concepts | **org-roam-ui** (excellent) |
| **B. org-node + org-mem** | Faster, simpler, modern, less magic | Smaller ecosystem, fewer tutorials | Export/graph via org-mem; less polished UI |
| **C. denote** | Dead simple file naming, no DB, greppable | Weaker backlink UX out of the box; graph is DIY | Weak for "mind map" goal |

**Recommendation: A (org-roam)** for your goals — mind map (G2) and fast jump
(G8) are first-class; AI agents can still `rg` the files and ignore the sqlite
DB (or read `org-roam.db` via CLI later). Use **one note = one file** under
`notes/` and `projects/`; keep `inbox.org` as a non-roam capture dump that you
promote into nodes.

If you want minimalism and already hate DBs, choose **B**.

Mind-map viewers:

- Primary: `org-roam-ui` (local web graph, filter tags, follow Emacs point).
- Secondary curiosity: `org-brain` / `org-mind-map` (Graphviz) — optional, not
  required if roam-ui ships.

<!--c:d4e5f6-->Note system: choose org-roam (recommended), org-node+org-mem, or denote.<!--/c:d4e5f6-->
<!--co:d4e5f6 by:grok at:2026-08-02T09:43:10.000Z status:resolved quote:"Note system: choose org-roam (recommended), org-node+org-mem, or denote."
grok (2026-08-02T09:43:10.000Z): Reply with A (org-roam), B (org-node), or C (denote). This gates packages, capture templates, and agent ID conventions. org-roam-ui is the best mind-map fit for G2.
Connor Fuhrman (2026-08-02T09:57:50.913Z): I'l take (A)
grok (2026-08-02T10:02:46.000Z): Confirmed A (org-roam) per your reply.
-->

### 7.3 Todos, deadlines, dependencies (G4, G5)

| Package | Role |
|---------|------|
| stock **DEADLINE** / **SCHEDULED** | Put in capture templates and agenda |
| **org-super-agenda** | Group today view: Overdue, Due soon, NEXT, Waiting, Projects |
| **org-ql** | Powerful queries; basis for custom views + agent filters |
| **org-edna** | Modern blocker/trigger deps (`BLOCKER`, `TRIGGER`) — prefer over old org-depend |
| stock **org-habit** | Already loaded by Prelude — use for recurring personal habits |
| **org-alert** (optional) | Desktop nags for deadlines |

<!--c:ovl8x-->**TODO workflow (disorganized-friendly)**<!--/c:ovl8x-->
<!--co:ovl8x by:Connor_Fuhrman at:2026-08-02T09:58:41.541Z status:resolved quote:"**TODO workflow (disorganized-friendly)**"
Connor Fuhrman (2026-08-02T09:58:41.541Z): I dont' need a `SHCEULED` but make an `IN PROGRESS`
grok (2026-08-02T10:02:46.000Z): Dropped SCHEDULED-centric workflow. TODO keywords include IN-PROGRESS; DEADLINE kept; capture templates updated.
-->

```text
Capture anything → ~/.org/inbox.org (TODO or plain note)
     │
     ▼  (daily 10 min process)
Promote to NEXT / IN-PROGRESS, or refile into a project .org
     │
     ▼
DEADLINE  = when it is actually due (optional)
edna BLOCKER = ids(...) for hard deps
     │
     ▼
Agenda "Today" super-agenda = only thing you look at
```

**Keywords:**

```elisp
(setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "IN-PROGRESS(p!)" "WAITING(w@/!)" "SOMEDAY(s)" "|"
                  "DONE(d!)" "CANCELLED(c@/!)")))
```

**Priorities:** use `[#A]` sparingly; `org-fancy-priorities` optional eye candy.

**Dependencies example (org-edna):**

```org
* NEXT Ship RFC
  :PROPERTIES:
  :ID:       20260802T120000.1
  :BLOCKER:  ids(20260802T110000.1)
  :END:
```

### 7.4 Tags and categories (G7)

Keep context tags (`@…`) mutually exclusive via `:startgroup`. Expand:

```elisp
(setq org-tag-alist
      '((:startgroup) ;; contexts — where/energy
        ("@work" . ?w) ("@home" . ?h) ("@computer" . ?c)
        ("@phone" . ?p) ("@errands" . ?e)
        (:endgroup)
        (:startgroup) ;; time-ish
        ("deep" . ?d) ("shallow" . ?s)
        (:endgroup)
        ("project" . ?P) ("meeting" . ?m) ("waiting_on" . ?W)
        ("urgent" . ?u) ("read" . ?r) ("idea" . ?i)))
```

**Categories:** use `#+CATEGORY:` or filename (Org agenda category = file name
by default). Prefer **one project file = one category** over heavy tag soup.

**File-level tags:** `#+FILETAGS: :work:clientx:` on project files.

### 7.5 Navigation (G8)

Already have Vertico + Consult + Embark. Add:

| Command | Binding proposal | Backend |
|---------|------------------|---------|
| Find note | `C-c n f` | `org-roam-node-find` or org-node |
| Insert link | `C-c n i` | `org-roam-node-insert` |
| Today / daily | `C-c n d` | `org-roam-dailies-goto-today` |
| Backlinks | `C-c n l` | `org-roam-buffer-toggle` |
| Search vault | `C-c n s` | `consult-ripgrep` on `org-directory` |
| Agenda today | `C-c a a` (custom) | super-agenda dispatch |
| Capture | `C-c c` | keep Prelude |

Dashboard: keep agenda widget; add "roam today" shortcut later.

### 7.6 Attachments and inline media (G1 polish)

- `org-download` → drag/paste images into `attachments/YYYY/MM/…`
- `org-cliplink` → URL → org link with title
- Optional: `org-inline-pdf` for PDF thumbnails (GUI)

## 8. AI agent surface (G3, G6)

### 8.1 Why agents struggle with Org today

- No stable machine entrypoint (only interactive Emacs).
- Inconsistent structure across files.
- Headline state + drawers are easy for humans, awkward for LLMs without a schema.
- Your `ORG_DIRECTORY` is often **unset** in the environment — agents cannot
  discover the vault.

### 8.2 Conventions (agent contract)

1. **Vault root** always exported: `ORG_DIRECTORY` (and optional
   `ORG_DIRECTORIES`) via home-manager / direnv / shell profile.
2. **Every agent-relevant headline** has:
   - `TODO`/`NEXT`/… keyword when actionable
   - `:ID:` (org-id UUID or iso timestamp)
   - optional `:PROJECT:`, `:EFFORT:`, `DEADLINE`, `SCHEDULED`
3. **One line title** — no markup in the headline text agents will parse.
4. **Tags** in standard Org location (end of headline).
5. Prefer **properties drawers** over inline cookies for machine fields.
6. Do not put secrets in the vault; agents may read everything under it.

### 8.3 `orgctl` CLI (proposed new tool in this flake)

Small wrapper, Nix-packaged, PATH-available next to Emacs. Implementation
options (pick one in implementation phase):

| Approach | Pros | Cons |
|----------|------|------|
| **Emacs batch + org-element/org-ql** | Perfect Org fidelity | Slow cold start |
| **Emacs daemon + emacsclient** | Fast after warm | Needs user daemon |
| **go-org / custom parser** | Fast, no Emacs | Incomplete Org edge cases |
| **ripgrep + thin JSON** for read-only | Instant | Writes unsafe |

**Recommendation:** v1 = **emacsclient if daemon up, else batch**, with
subcommands below. Read-only search can short-circuit to `rg`.

```text
orgctl path                     # print ORG_DIRECTORY
orgctl inbox list
orgctl inbox add "Buy milk" [--tag @errands] [--due 2026-08-05]
orgctl todo list [--state NEXT] [--tag @computer] [--due-before DATE] [--json]
orgctl todo get ID
orgctl todo done ID
orgctl todo schedule ID DATE
orgctl todo deadline ID DATE
orgctl todo block ID --on OTHER_ID
orgctl search "query" [--json]  # rg + optional org-ql
orgctl notes list|find QUERY
orgctl agenda today [--json]
orgctl refile ID --to FILE::*heading
```

JSON schema (sketch for `todo list`):

```json
{
  "id": "…",
  "state": "NEXT",
  "title": "Ship RFC",
  "file": "/…/projects/emacs.org",
  "tags": ["@computer"],
  "deadline": "2026-08-10",
  "scheduled": null,
  "blockers": ["…"],
  "priority": "B"
}
```

Agents (opencode, etc.) get a skill or tool description pointing at `orgctl`
and the vault path. No need for the agent to run Elisp.

### 8.4 <!--c:qynu9-->Optional MCP server<!--/c:qynu9-->
<!--co:qynu9 by:Connor_Fuhrman at:2026-08-02T09:59:21.589Z status:resolved quote:"Optional MCP server"
Connor Fuhrman (2026-08-02T09:59:21.589Z): let's leave this for futur ework
grok (2026-08-02T10:02:46.000Z): MCP deferred to future work.
-->

If you use MCP-capable agents heavily, wrap `orgctl` as an MCP server
(`orgctl-mcp`) with tools mirroring subcommands. **Phase 2** — CLI alone
unblocks most workflows.

### 8.5 Searchability without CLI

Even without `orgctl`, agents can:

```bash
rg -n --type-add 'org:*.org' -t org '^\*+ (TODO|NEXT)' "$ORG_DIRECTORY"
rg -n ':ID:' "$ORG_DIRECTORY"
```

Document this in a short `AGENTS.md` (or fleet skill) inside the vault or repo.

<!--c:789abc-->Agent interface: ship orgctl CLI in this flake (recommended) vs docs-only rg conventions vs MCP-first.<!--/c:789abc-->
<!--co:789abc by:grok at:2026-08-02T09:43:10.000Z status:resolved quote:"Agent interface: ship orgctl CLI in this flake (recommended) vs docs-only rg conventions vs MCP-first."
grok (2026-08-02T09:43:10.000Z): Reply cli / rg-only / mcp-first. cli is the best balance for opencode and shell agents; MCP can wrap cli later.
Connor Fuhrman (2026-08-02T09:59:29.654Z): cli/rg only
grok (2026-08-02T10:02:46.000Z): Agent surface = orgctl CLI + rg conventions; no MCP.
-->

## 9. Capture templates (revised)

```elisp
(setq org-capture-templates
      `(("i" "Inbox" entry (file "inbox.org")
         "* %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n%i\n" :empty-lines 1)

        ("t" "Todo" entry (file "inbox.org")
         "* TODO %?\nDEADLINE: %^t\n:PROPERTIES:\n:CREATED: %U\n:END:\n" :empty-lines 1)

        ("n" "Next (this week)" entry (file "inbox.org")
         "* NEXT %? :@computer:\nSCHEDULED: %t\n:PROPERTIES:\n:CREATED: %U\n:END:\n")

        ("m" "Meeting" entry (file+datetree "meetings/meetings.org")
         "* %^{Title} :meeting:\n%^T\n** Notes\n%?\n** Actions\n*** TODO %^{First action}\n"
         :empty-lines 1)

        ("p" "Project" entry (file "projects/%^{slug}.org")
         "#+title: %^{Title}\n#+filetags: :project:\n\n* Outcome\n%?\n* Tasks\n"
         :empty-lines 1)

        ;; only if roam chosen:
        ("r" "Roam note" plain (function org-roam-capture--get-point)
         "%?" :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                                 "#+title: ${title}\n")
         :unnarrowed t)))
```

Key idea: **default path never asks for a project.** Projects are created
deliberately; most stuff dies in inbox or becomes a lone NEXT.

## 10. Agenda: the "today I am a mess" view

Custom command `a` (default):

```elisp
(setq org-agenda-custom-commands
      '(("a" "Today"
         ((agenda "" ((org-agenda-span 1)
                      (org-super-agenda-groups
                       '((:name "Overdue" :deadline past :scheduled past)
                         (:name "Due today" :deadline today :scheduled today)
                         (:name "Habits" :habit t)
                         (:name "Waiting" :todo "WAITING")
                         (:name "Next" :todo "NEXT")
                         (:name "Rest of agenda" :time-grid t)))))
          (tags-todo "+TODO=\"TODO\"+PRIORITY=\"A\""
                     ((org-agenda-overriding-header "Urgent unscheduled")))))
        ("i" "Inbox" tags "LEVEL=1" ((org-agenda-files '("inbox.org"))))
        ("w" "Waiting" todo "WAITING")
        ("p" "Projects" tags-todo "project")))
```

Weekly review command `r`: stuck projects (project tag, no NEXT child) via
org-ql — implement in phase 2.

## 11. Interaction with Prelude and stock Org

| Concern | Approach |
|---------|----------|
| Prelude keys `C-c a/c/l/b` | Keep; extend with `C-c n` note map |
| `org-indent-mode` from Prelude | Keep; required for org-modern look |
| `org-habit` from Prelude | Keep; configure `org-habit-graph-column` |
| `org-log-done` set in both | Single source in `org-config` after load |
| Helm vs Vertico | You load both; prefer Consult for org navigation, keep helm-ag for `C-s` |
| TTY emacs-nox | Feature flags on `display-graphic-p` |
| envrc | Can set `ORG_DIRECTORY` per-project; still set a **global default** in HM |

Do **not** fork `prelude-org.el`; override in `org-config.el` via
`with-eval-after-load 'org`.

## 12. Nix packaging changes

### 12.1 Packages to add to `emacsBase.nix` (phase-dependent)

**Phase 1 (pretty + agenda power + media)** — no note-system decision needed:

```nix
org-modern
org-appear
org-super-agenda
org-ql
org-edna
org-download
org-cliplink
visual-fill-column
# GUI-oriented, still install (no-op hooks on TTY):
mixed-pitch
valign
org-fragtog
org-alert
```

**Phase 2 (notes)** — after decision:

- If A: `org-roam` `org-roam-ui` `consult-org-roam` (+ websocket deps pulled in)
- If B: `org-node` `org-mem`
- If C: `denote` `consult-notes` (if available) 

**Phase 3 (agent):**

- New package derivation `orgctl` (script + emacs batch helpers)
- Optionally expose in `emacs.nix` `envPackages` PATH wrap
- Document `ORG_DIRECTORY` in README

### 12.2 Config module split (suggested)

```text
emacs-config/
  org-config.el           # loader + env agenda (keep)
  org/
    org-core.el           # todos, tags, capture, refile, id
    org-ui.el             # modern, appear, fill-column
    org-agenda.el         # super-agenda, custom commands
    org-notes.el          # roam/node/denote
    org-agent.el          # batch entrypoints for orgctl
```

Loader stays dumb; each file `provide`s and is required from `org-config.el`.

## 13. Workflow for a disorganized human (day in the life)

1. **Anytime:** `C-c c i` — dump thought. Zero taxonomy required.
2. **Morning (5–10 min):** `C-c a a` Today view. Mark 1–3 items NEXT.
   Schedule them. Ignore the rest.
3. **During work:** complete → DONE; new stuff → inbox; waiting on people →
   WAITING + note who in log.
4. **End of day (optional):** process inbox to &lt;5 items; refile project tasks.
5. **Weekly (30 min):** review WAITING, SOMEDAY, projects without NEXT, overdue
   deadlines. Open roam graph for a messy project if stuck.
6. **Agent assist:** "What is overdue?" → `orgctl agenda today --json` /
   `orgctl todo list --state NEXT`. "Add buy detergent due Saturday" →
   `orgctl inbox add …`.

## 14. Implementation plan

### Phase 0 — Prerequisites (small)

- [ ] Set `ORG_DIRECTORY` (and create vault tree) via home-manager or shell.
- [ ] Ensure inbox + folders exist; migrate any existing notes.
- [ ] README section: env vars, vault contract.

### Phase 1 — Pretty + actionable agenda (1 PR)

- [ ] Add phase-1 packages to `emacsBase.nix`.
- [ ] `org-ui.el`: org-modern, org-appear, GUI guards.
- [ ] `org-core.el`: IDs (`org-id-link-to-org-use-id`), capture templates,
      tags, edna enable, deadline/schedule helpers.
- [ ] `org-agenda.el`: super-agenda Today view.
- [ ] Manual smoke: GUI macport + emacs-nox.

### Phase 2 — Notes + mind map (1 PR, after decision)

- [ ] Add chosen note packages.
- [ ] `org-notes.el` + key map `C-c n`.
- [ ] org-roam-ui (or alternative) documented.
- [ ] consult integration for jump.

### Phase 3 — Agent CLI (1 PR)

- [ ] `orgctl` package + batch Elisp.
- [ ] JSON outputs + `--help`.
- [ ] Vault `AGENTS.md` or skill snippet for opencode.
- [ ] Optional: MCP wrapper.

### Phase 4 — Polish

- [ ] Stuck-project org-ql view, habits tuning, org-alert.
- [ ] Attachments hygiene, archive policy.
- [ ] Dashboard shortcuts.

## 15. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Org-roam DB drift / lock | File-first; DB is cache; `org-roam-db-sync`; agents use files |
| Capture templates too clever | Default templates stay dumb (inbox only) |
| Package bloat in Nix closure | Split optional org set; defer fragtog/valign if needed |
| TTY regression | Guard GUI packages; CI smoke load with emacs-nox |
| Agent corrupts Org syntax | Writes only via orgctl (org-element), never raw append for state changes |
| You stop processing inbox | Super-agenda shows Inbox count; weekly review command |

## 16. Alternatives considered

- **Org-mode only, no roam:** fails mind-map and note-jump goals unless heavy
  custom.
- **Obsidian primary + Org export:** fights Nix Emacs investment; worse todo/deps.
- **org-gtd package:** opinionated; heavier than needed for messy workflow.
- **Hyperbole:** powerful but steep; not the shortest path to G1–G9.
- **Only visual packages:** does not help agents or deps.

## 17. Success metrics

- Capture a thought in &lt;5 seconds without choosing a folder.
- Open "what should I do now?" in one key chord and see overdue + NEXT.
- Jump to any note by title in &lt;3 keystrokes after `C-c n f`.
- See a project mind-map in browser without leaving the ecosystem.
- From a shell/agent: list NEXT and mark DONE without opening Emacs UI.
- emacs-nox still starts clean on a server.

## 18. Decision checklist

Resolve the Document Comment threads in this file, then set overall status:

| ID | Decision | Default if you rubber-stamp |
|----|----------|-----------------------------|
| a1b2c3 | Vault directory layout | PARA-lite tree in §6.1 |
| d4e5f6 | Note system | **A – org-roam** + org-roam-ui |
| 789abc | Agent interface | **orgctl CLI** in this flake |
| below | Overall RFC | — |

<!--c:e2e1f0-->Pretty stack: org-modern + org-appear as defaults (yes/no).<!--/c:e2e1f0-->
<!--co:e2e1f0 by:grok at:2026-08-02T09:43:10.000Z status:resolved quote:"Pretty stack: org-modern + org-appear as defaults (yes/no)."
grok (2026-08-02T09:43:10.000Z): Recommend yes. Reply yes / no / yes-with-superstar-instead.
grok (2026-08-02T10:02:46.000Z): No explicit reply; proceeding with recommended yes (org-modern + org-appear).
-->

<!--c:f1a2b3-->Dependencies: enable org-edna for BLOCKER/TRIGGER (yes/no).<!--/c:f1a2b3-->
<!--co:f1a2b3 by:grok at:2026-08-02T09:43:10.000Z status:resolved quote:"Dependencies: enable org-edna for BLOCKER/TRIGGER (yes/no)."
grok (2026-08-02T09:43:10.000Z): Recommend yes for G4. Reply yes / no / defer-to-phase-4.
grok (2026-08-02T10:02:46.000Z): No explicit reply; proceeding with recommended yes (org-edna).
-->

<!--c:c0ffee-->RFC status: approved / approved-with-changes / rejected.<!--/c:c0ffee-->
<!--co:c0ffee by:grok at:2026-08-02T09:43:10.000Z status:resolved quote:"RFC status: approved / approved-with-changes / rejected."
grok (2026-08-02T09:43:10.000Z): Resolve when review is done. Implementation of Phase 1 waits for approved or approved-with-changes plus the note-system and agent-interface threads (or explicit "phase 1 only" go-ahead).
grok (2026-08-02T10:02:46.000Z): Treating as approved-with-changes from your thread replies; implementing now.
-->

## 19. Appendix A — Goal → package map (quick ref)

| Goal | Primary tools |
|------|----------------|
| Pretty renders | org-modern, org-appear, org-fragtog, valign, mixed-pitch |
| Mind maps | org-roam-ui (or org-mind-map) |
| AI searchable | vault layout, IDs, rg, orgctl, org-ql |
| Due + depends | DEADLINE/SCHEDULED, org-super-agenda, org-edna |
| Disorganized | inbox capture, NEXT, Today super-agenda, weekly review |
| Agent todos | orgctl (+ MCP later) |
| Tags/categories | org-tag-alist, FILETAGS, categories |
| Jump notes | org-roam-node-find, consult-ripgrep, embark |
| Modern | all of above via nixpkgs, no runtime MELPA |

## 20. Appendix B — Files this RFC will touch (when approved)

- `nix/emacsBase.nix` — package list
- `nix/emacs.nix` — PATH for orgctl, maybe sqlite/graphviz
- `emacs-config/org-config.el` + new `emacs-config/org/*.el`
- `emacs-config/config.el` — minor key conflicts only if any
- `README.md` — ORG_DIRECTORY + orgctl
- New: `pkgs/orgctl/` or `nix/orgctl.nix`
- Out of repo (your machine): vault tree + home-manager env

---

*End of RFC. Comment threads above are the review surface.*
