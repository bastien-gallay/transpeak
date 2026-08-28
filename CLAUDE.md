# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## What this repo is

Transpeak is a "prompt distribution" project, built on the same shape as
its sibling [Glance](../glance): a single source prompt (`prompt.md`)
defining an answer format, plus three surface-specific derivatives.

- `claude-code/transpeak-style.md` — the Claude Code **output style**
  (select it in `/config`). The primary surface: output styles are part
  of the system prompt, so the directive is re-presented every turn. Its
  frontmatter sets `keep-coding-instructions: true` so the style adds
  formatting rules rather than replacing Claude Code's coding
  instructions.
- `claude-code/transpeak.md` — the `/transpeak` slash command
  (session-scoped, asks for an acknowledgement line). One-shot.
- `claude-ai/transpeak-style.md` — the Claude.ai custom style text (no
  session framing, since it is selected from the picker).

There are **no tests and no package manager**. The only build step is
`build.sh`. All "code" here is Markdown.

## The format in one paragraph

Answers whose content is relational — options, procedures, scope, cause,
state — are expressed as types and expressions rather than paragraphs.
Two tiers: an inline formula (tier 1, one relation is enough) and a
fenced typed block (tier 2, three elements and a nameable relation).
Prose keeps the *why*. Four hard rules make the code readable rather
than merely present: it need not compile, identifiers name concepts not
claims, no comments, no logic inside strings. A deletion test decides
whether a block should exist at all: cut the block, and if nothing is
lost it was decoration.

## Architecture: source → derived

    prompt.md — canonical; body between transpeak:body:start/end markers
    │
    ├── claude-code/transpeak-style.md.tmpl ─build.sh─▶ …-style.md
    ├── claude-code/transpeak.md.tmpl       ─build.sh─▶ transpeak.md
    └── claude-ai/transpeak-style.md.tmpl   ─build.sh─▶ …-style.md

Each `*.md.tmpl` is a per-surface wrapper containing a `{{BODY}}`
placeholder that `build.sh` replaces with the marked region of
`prompt.md`.

The body has four sections, and a new rule belongs to exactly one:

- **`## Trigger`** — when the format fires *at all*. Anything that can
  turn an answer back into prose goes here.
- **`## Always`** — hard constraints on any transpiled output,
  whichever tier. The four rules above live here.
- **`## Tier 1`** / **`## Tier 2`** — form-specific mechanics: the
  symbol set, the marker, the shape catalogue.

If a rule would change *whether* to transpile, it is a trigger rule; if
it changes *how the code looks* regardless of tier, it is an Always
rule. Putting a trigger rule under a tier is the failure mode to watch:
it lets the other tier escape it.

## Editing workflow

1. Edit the body inside the markers in `prompt.md`.
2. Run `./build.sh` to regenerate all three derived files.
   `./build.sh --check` fails on drift — use it in pre-commit / CI.
3. Re-paste the Claude.ai style by hand after a change; `install.sh`
   only symlinks the Claude Code surfaces.

Never edit a generated file (`claude-code/transpeak.md`,
`claude-code/transpeak-style.md`, `claude-ai/transpeak-style.md`)
directly — the next `./build.sh` overwrites it.

## Conventions

- Markdown must pass `markdownlint` (per user global instructions).
  `.markdownlint.json` disables MD041 (slash commands and style texts
  open with prose by design) and MD046. `build.sh` lints only
  `prompt.md` and the generated files — run `markdownlint` yourself on
  `README.md` and `CLAUDE.md`.
- Keep the prompt body wrapped at ~72 columns and ASCII diagrams under
  80, as Glance's own content rule requires.

## Field evidence

The only measurement this repo has. Four transpeak blocks were extracted
from real sessions on 2026-08-28 (a client docs repository, 26
substantive responses, 2 sessions). What they showed, and what each
finding changed:

- **4 blocks out of 4 were end-of-session reports** — the one content
  type the format handles worst. One block listed five wrap phases with
  three figures each, and a markdown table six lines below restated the
  same five phases. Produced the session-report exclusion and the
  deletion test in `## Trigger`.
- **4 blocks out of 4 were F#**, and no `match` consumed the unions in
  half of them. The old resolution order opened on "the dominant
  language of the current project"; a docs repository has none, so every
  answer fell through to the same fallback. Produced *Choosing the
  language* and the `match` gate.
- **The blocks stopped after `/wrap` was invoked.** The slash command
  had been injected once; a skill prompt landing later buried it. This
  is the "wish, not a mechanism" trap below, observed rather than
  reasoned. Nothing in the prompt can fix it — it is a surface choice.
- Rules already in `## Always` were violated unnoticed: comments in two
  blocks, a claim in a string (`debt: "+33 lines, no trim"`), and an
  expression past the readable limit
  (`Broke 5 of 10 |> AllFixedBeforePublish`). Only the last one produced
  a new clause; the other two were already forbidden, which is a
  reminder that adding a rule is not the same as making it bite.

Before adding a rule, prefer measuring again over reasoning again.

## Traps

- **The marker must stay outside the fence.** `🧩 answer.transpeak` is a
  line above the code block, not a second token in the info string. A
  fence tagged `fsharp answer` loses syntax highlighting on some
  renderers, and highlighting is half of why the block reads faster than
  the paragraph it replaced. This was the reason the earlier
  `module Answer` wrapper idea was dropped too: it forced a construct
  into every block, including blocks that had no module to speak of.
- **🧩 has not been checked on a real terminal.** Glance keeps
  `docs/glyph-legibility.md` because a human sat down and tested glyphs
  at terminal font sizes. Nothing equivalent has been done for 🧩 here.
  If it renders as tofu on some setup, the fallback is the text token
  alone (`answer.transpeak`), which carries the whole meaning already.
- **Only one output style is active at a time.** Transpeak and Glance
  are both output styles and cannot both be selected. Do not "fix" this
  by merging the two prompts — they have different triggers, and the
  merged body would let one relax the other. The documented answer is a
  `CLAUDE.md` pointer for whichever one loses the slot.
- **`build.sh` deviates from Glance's on purpose.** Its `mktemp` calls
  pass an explicit `"${TMPDIR:-/tmp}/transpeak.XXXXXX"` template.
  Argument-less BSD `mktemp` ignores `TMPDIR` and fails with "Operation
  not permitted" inside a sandbox; Glance carries that as a known
  artifact, this repo fixed it. Do not "restore parity".
- **"For the rest of this session" is a wish, not a mechanism.** A slash
  command's text is injected once, as a user message; a compaction can
  drop it. A directive that must hold for a session belongs in an output
  style, `CLAUDE.md`, or a hook.
- **The output style exists; the `/output-style` command does not.**
  Verified by Glance on Claude Code 2.1.218: the picker moved into
  `/config`, and `/output-style` returns *Unknown command*. Re-check the
  binary before writing an invocation into the README.
- **The format's own rules apply to this repo's files.** When a rule in
  `prompt.md` seems to condemn something a file here does deliberately,
  suspect the rule first — that is how the "no comments" rule was found
  to need its one provenance exception.
