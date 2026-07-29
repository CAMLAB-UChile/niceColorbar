# Changelog

All notable changes to niceColorbar are documented here. Versions follow
[Semantic Versioning](https://semver.org/).

## 1.1.0 — 2026-07-29

### Added
- `TickLabelsAutoScale` / `TickLabelsAutoScaleDecimals`: auto-scaled tick
  labels with a common `×10ⁿ` exponent annotation above the bar, matching
  MATLAB's classic axis exponent behavior. On a 3-D axes, the plot's own Z
  ruler is kept in lockstep (same exponent, same decimal count).
- `PdfRender` and `ExportResolution` properties, giving control over
  `saveAsPDF`'s rasterized/vector `ContentType` and the DPI used by
  `saveAsPNG`/`saveAsPDF`.
- `autoscale.on` / `autoscale.off` commands in `session()`.
- README: new Features, Autoscale feature, Author, and How to cite sections;
  a custom colormap reference table; completed API/Properties/Interactive
  session tables; Quick start code synced to `QuickStart.m`.

### Fixed
- Docked-figure rendering corruption caused by multiple `niceColorbar`
  instances racing separate per-instance resize timers on a shared figure
  (now a single shared timer per figure).
- `Title`/`Logo` swap and mirroring bug introduced by the top/bottom `Side`
  layout.
- Z-axis tick label decimal count not following
  `TickLabelsAutoScaleDecimals` while `TickLabelsAutoScale` is on.
- `\color[rgb]{r,g,b}` tags using space-separated values instead of the
  comma-separated syntax MATLAB's TeX interpreter actually requires — latent
  since 1.0.0, only surfaced once a 3-D axes routed the Logo/Title through
  the stricter `annotation('textbox', ...)` renderer.
- `hide.all`/`show.all` layout flash on 3-D colorbars.
- A flaky 3-D overlap regression test.

## 1.0.0 — 2026-07-26

Initial release: styled `colorbar` replacement with six size/style presets,
LaTeX-capable multi-line `Title`, corner `Logo` with per-segment coloring,
light/dark theme awareness (`ThemeMode`), property-driven auto-refresh, 2-D
and 3-D plot support with interactive rotation, one instance per
subplot/figure, `Side` placement, capped color limits
(`setCappedLimits`/`resetLimits`), PNG/PDF/FIG export, and the keyboard-driven
`session()` console.
