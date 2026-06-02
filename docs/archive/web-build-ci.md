# Web Build CI Checklist

- [x] Task A — `package.json` — create with `name: "plant-game-3d"`, `scripts.build: "bash scripts/build_web.sh"`, and `devDependencies: { "love.js": "11.4.1" }`
- [x] Task B — `scripts/build_web.sh` — copy from `wip/scripts/build_web.sh`; change the `love.js` title argument from `"plant game"` to `"plant game 3d"`; all other logic identical
- [x] Task C — `web-template/controls.js` — verbatim copy of `/root/wip/web-template/controls.js`
- [x] Task D — `.github/workflows/web.yml` — copy from `/root/wip/.github/workflows/web.yml`; update the PR preview comment URL from `iyung.github.io/wip/` to `iyung.github.io/wip-3d/`
