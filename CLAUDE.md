# CLAUDE.md

Claude-Code-specific workflow notes for **System Stats**. Full project context, architecture,
conventions and safety rules live in `AGENTS.md` — read that first; this file only adds
Claude-Code-specific operating instructions and is intentionally short.

## Session hygiene

- Start new, unrelated tasks with `/clear` rather than continuing a long thread.
- Use `/compact` proactively once a session has done substantial exploration but still has
  more work ahead in the same task.
- Don't re-paste large chunks of `AGENTS.md` or file contents back into the conversation —
  reference them by path instead.

## Reading code

- `main.qml` is a single file — read the relevant block (search for the function or the
  representation) instead of the whole file once you know where to look.
- Don't re-read a file you already read earlier in the same session unless it may have changed.

## Producing changes

- Default output for code changes: a **diff/patch**, not full rewritten files.
- When asked a question (see `AGENTS.md` "Working style") — investigate, answer concisely,
  propose options. A short sketch per option is enough until the developer picks one.
- Keep explanations proportional to the ask.

## Verification

- After every change: `qmllint`, `kpackagetool6 -u`, restart plasmashell, check the journal
  (commands in `AGENTS.md`). Say plainly what you could not see — you have no screenshot of
  the panel or desktop.
- Don't paste full journal output — quote only the relevant lines.

## Token-cost awareness

- `AGENTS.md` is kept compact on purpose (current state only, no history) — when updating it,
  edit existing sentences instead of appending history.
- The German-language convention applies to code/output, not to your own reasoning.
