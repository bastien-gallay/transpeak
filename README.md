# Transpeak

> A shared answer format for Claude.ai and Claude Code.
> When an answer has a shape — options, a procedure, a scope, a cause —
> it comes back as types and expressions instead of paragraphs.

## What it does

Most feedback is relational: this *or* that, this *then* that, this *inside*
that, this *because of* that. Prose states relations in sentences; code states
them in structure. Transpeak moves the structure into code and leaves prose
the one job it does better — saying **why**.

Two tiers, and everything they do not claim stays prose:

| Tier | Form                            | Fires when             | Cost      |
|------|---------------------------------|------------------------|-----------|
| 1    | one inline formula, in ticks    | one nameable relation  | near zero |
| 2    | one fenced typed block, marked  | 3+ elements, 1 relation| real      |

Tier 1 looks like this, inline in a sentence:

    scope = allEndpoints \ {legacy, internal}
    ship ← greenCI ∧ ¬pendingMigrations
    latency(n) ≈ O(n²)

Tier 2 looks like this — note the marker line above the fence:

🧩 `answer.transpeak`

```fsharp
type Scope   = SingleAggregateBehindGateway | PublicApiSurface | EverySurface
type Missing = PayloadSize | ClientRoadmap
type Verdict = Migrate of Scope | Stay | NotDecidableYet of Missing

let verdict signals =
    match signals with
    | s when not (s |> hasAny OverFetch) -> NotDecidableYet PayloadSize
    | s when s |> contains NoExperience  -> Migrate SingleAggregateBehindGateway
    | _                                  -> Migrate PublicApiSurface
```

`hasAny OverFetch` does not compile — you cannot pass a union case as a
predicate in F#. That is deliberate, and it is the point of the next section.

## The four rules that make it work

- 🧬 **It does not have to compile.** Syntax stays readable; semantics are
  free. An uninitialised variable whose name carries the meaning is correct
  usage. This is also what makes the block safe: it cannot be pasted by
  mistake.
- 📏 **An identifier names a concept, not a claim.** Four words, no
  conjugated verb. `theTeamNeverUsedKafkaSoStartSmall` is a sentence wearing
  camelCase — the very prose the format exists to remove.
- 🚫 **No comments.** A comment you need is a *detector*: either the naming
  is wrong, or the content was never transpilable. It moves to the prose
  under the block, where it reads better anyway.
- 🎯 **Strings carry data, never logic.** `Verdict of string` is prose
  smuggled through the type system. Use a union case instead — even a
  malformed expression beats a sentence in quotes.

## What it will not transpile

Judgements. *"This refactor is risky: the module is four years old, has no
tests, and its only author left."* Three facts and a recommendation, no
relation to model. `risk = "high"` loses everything. The trigger exists so
that this stays a sentence.

## Surfaces

| Surface     | Mechanism     | How to use                | Persists   |
|-------------|---------------|---------------------------|------------|
| Claude Code | Output style  | `/config` → **Transpeak** | Every turn |
| Claude Code | Slash command | `/transpeak`              | One-shot   |
| Claude.ai   | Custom style  | **Transpeak** in picker   | Every turn |

All three derive from a single source: [`prompt.md`](./prompt.md).

> ⚠️ **Use the output style, not the slash command, for long sessions.**
> A slash command is injected once, as a user message; after a dozen
> exchanges it competes with everything said since, and a compaction can
> drop it. An output style is part of the system prompt and is re-presented
> every turn.
>
> ⚠️ **Only one output style is active at a time.** Transpeak and
> [Glance](../glance) cannot both be the output style. Pick one as the style
> and carry the other as a `CLAUDE.md` pointer (below) or a slash command.

## Install

### Claude Code

```bash
git clone <this-repo> transpeak
cd transpeak
./install.sh
```

Symlinks both Claude Code surfaces, so edits in the repo propagate:

| Repo file                          | Symlinked to                            |
|------------------------------------|-----------------------------------------|
| `claude-code/transpeak.md`         | `~/.claude/commands/transpeak.md`       |
| `claude-code/transpeak-style.md`   | `~/.claude/output-styles/transpeak.md`  |

Use `./install.sh --copy` to copy instead. The output style still has to be
selected once, in `/config` → *Output style*.

### Claude Code — always-on alongside another style

If your output style slot is taken, add a pointer to your user-global
`~/.claude/CLAUDE.md`:

```markdown
- Transpeak: when an answer has a shape (3+ related elements and a nameable
  relation), express it as a typed code block instead of paragraphs, marked
  with a `🧩 answer.transpeak` line above the fence. Full spec:
  ~/Dev/oss/skills/transpeak/prompt.md. No comments, no logic in strings,
  identifiers name concepts not claims, and the code need not compile.
```

### Claude.ai

**Settings → Capabilities → Styles → Create style → Custom
instructions.**
Paste the values from
[`claude-ai/transpeak-style.md`](./claude-ai/transpeak-style.md).
Re-paste after any change to `prompt.md` — the install script only handles
Claude Code.

## Editing

`prompt.md` is the only file to edit. Everything under `claude-code/` and
`claude-ai/` that is not a `.tmpl` is generated:

```bash
./build.sh           # regenerate the three surfaces
./build.sh --check   # exit 1 on drift (use in CI / pre-commit)
```

The shape catalogue in tier 2 is **closed**; tier 1 is **open**. That
asymmetry is intentional — see [`CLAUDE.md`](./CLAUDE.md).

## Related

- [Glance](../glance) — at-a-glance readability. Transpeak takes over where
  Glance stops: Glance chooses the *device* (table, list, diagram), Transpeak
  is the device for relational content.
- [Flair](../flair) — where the single-predicate trigger and the
  data-not-code extension model come from.

## License

MIT — see [LICENSE](./LICENSE).
