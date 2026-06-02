# Web Build CI

## Goal

Add CI steps that build a testable web version of the game on every push and PR, matching the setup already in `../wip`. Each PR gets a live preview URL posted as a comment; merges to main deploy to the live GH Pages site.

## Affected files

- `package.json` — new
- `scripts/build_web.sh` — new
- `web-template/controls.js` — new
- `.github/workflows/web.yml` — new
- `.github/workflows/ci.yml` — unchanged

## What changes

### `package.json`
New file. Declares `love.js@11.4.1` as a dev dependency and a `build` script alias.

### `scripts/build_web.sh`
New file. Identical logic to `wip/scripts/build_web.sh` with one change: the `love.js` title argument is `"plant game 3d"` instead of `"plant game"`.

Steps: zip game files → run `npx love.js` → copy `web-template/controls.js` into output → inject `<script>` tag into `index.html` → delete the `.love` archive.

### `web-template/controls.js`
New file. Verbatim copy from `wip/web-template/controls.js`. Renders an on-screen d-pad (arrow keys) and E / F / Esc buttons. Arrow key events satisfy wip-3d's `{"up","w"}` / `{"down","s"}` / `{"left","a"}` / `{"right","d"}` bindings, so no key-map changes are needed.

### `.github/workflows/web.yml`
New file. Verbatim copy of `wip/.github/workflows/web.yml` with one change: the PR preview comment URL is updated from `iyung.github.io/wip/` to `iyung.github.io/wip-3d/`.

Workflow jobs:
- **build** — runs on every push and open PR; zips + love.js builds, uploads `web/` as an artifact
- **deploy** — runs on `main` push only; publishes artifact to `gh-pages`
- **deploy-pr** — runs on open PR; publishes artifact to `gh-pages/pr-{number}/` and posts or updates a preview comment
- **cleanup-pr** — runs on PR close; removes the `pr-{number}/` directory from `gh-pages`

## What stays the same

- `conf.lua` — no changes; headless flag handling and window config are unaffected
- `lua/` — no changes
- `.github/workflows/ci.yml` — existing test job is untouched; `web.yml` is additive

## Open questions

None.
