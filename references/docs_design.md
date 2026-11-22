# Documentation design

_The site, its shared design and the examples run at build time._ (Layer 3 reference.)

- Documenter, in the style of the other rcalxrc08 packages; the design is shared (identical copies, edit together):
  `docs/src/assets/style.css` (Dark Quant), `dark.js`, `figures.css`, `site.css` (page headers with kicker, lede and
  section links, numbered sections, cards) and `home.css` (landing page: hero, stat tiles, feature cards, flow, tabbed
  results, quick start steps). Markdown tables need `|:--|` columns.
- `docs/figures.jl` computes the figures at build time, a light and a dark SVG each; the hero is `hero_figure`, the
  zoom of the Newton basins of the complex implied volatility. The home page's stat tiles are timed at build time by
  `hero_stats()` (called from a hidden `@example` block). The sidebar groups Guides and Reference.
- The performance table is measured at build time; the GPU page (`gpu.md`) has a static table measured on an MX150,
  since CI has no GPU.
- The calibration example of `gpu.md` runs at build time on the CPU (the same code runs on CUDA inside a function): an
  SVI-type smile (nonlinear in its parameters) fitted on implied volatilities by Gauss-Newton with `Zygote.jacobian`,
  on prices with deterministic 1% noise so that the residuals do not vanish and the Hessian differs from `JᵀJ`. The
  sensitivities to the quoted prices chain two implicit function theorems: `∂θ*/∂v = H⁻¹Jᵀ` (`H` from
  `ForwardDiff.hessian`) and `∂v/∂m = 1/vega` (the AD rules of `blsimpv`). They are checked against bumping a price,
  re-implying and recalibrating, and against the pseudo-inverse; keep the noise, without it the check cannot tell the
  two apart.
- In top-level loops of `@example` blocks update globals in place (`θ .-= …`, Documenter's soft scope).
- `references.md` holds the bibliography; cite from the text with links to its sections.
- `barriers.md` (Guide 02) has the barrier figure (`barrier_figure`: prices and ForwardDiff deltas against the spot)
  and a Brownian bridge Monte Carlo check run at build time.
- The logo and favicon live in `etc/` and are copied by `make.jl`.
