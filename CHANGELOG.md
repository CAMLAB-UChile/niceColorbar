# Changelog

All notable changes to niceColorbar are documented here. Versions follow
[Semantic Versioning](https://semver.org/).

## 1.2.2 — 2026-09-19

### Fixed
- High-resolution PNG/TIFF/PDF export could shear off part of a text glyph
  (e.g. one axis tick label) due to a MATLAB rasterizer defect at certain
  resolution/figure-geometry combinations. Raster exports above 300 DPI now
  render at a confirmed-clean 300 DPI and are bicubic-upscaled to the
  requested resolution instead of rendering natively at high DPI.
- `saveAsPDF` with the default `PdfRender = "image"` embedded its raster
  content as JPEG with no quality control, making it visibly blurrier than
  the PNG/TIFF export of the same figure (most noticeable against a
  light/white background). It now embeds the raster losslessly
  (zlib/FlateDecode, the same compression family PNG uses) via a
  hand-written PDF writer instead of going through `exportgraphics`'s JPEG
  encoder.

## 1.2.1 — 2026-09-17

### Fixed
- A `niceColorbar` saved via `saveAsFIG`/`session()`'s `save.fig` and
  reopened lost its live auto-refresh/resize handling entirely (state that
  drives it lives in memory and never survives `.fig` serialization), so the
  colorbar silently drifted out of position on the next resize/maximize/dock.
  `colorbar()` now snapshots enough state into the figure to rebuild a fully
  live instance the moment the `.fig` is reopened.
- A related `resizeHub` bug where a stale registry entry could survive under
  a figure handle MATLAB later recycles for a new/reloaded figure, causing
  double-registration.

## 1.2.0 — 2026-09-13

### Added
- `cobalt` theme mode: a second, explicit-only dark theme with no `'auto'`
  detection of its own, selectable via `ThemeMode` or `session()`'s new
  `cobalt` command.
- `Box` property (`'on'`/`'off'`, default `'on'`) controlling the axes' box
  outline — previously forced on unconditionally. Toggle live via
  `session()`'s new `box.on`/`box.off` commands.
- `saveAsTIFF` method for one-line TIFF export, alongside PNG/PDF/FIG;
  `save.tiff` command in `session()`.
- `simsolid` diverging colormap.
- `handleSessionCommand`/`sessionCommandNames` exposed as reusable public
  static methods, so other interactive sessions built on top of
  `niceColorbar` can list/handle the same commands alongside their own.

### Fixed
- `saveAsPNG`/`saveAsTIFF` cropping flush against the outermost content,
  clipping the Title/Logo/tick labels at the edge — both now export with a
  small, fixed padding.
- `saveAsPDF` with the default `PdfRender = "image"` paging to the source
  figure's own size instead of the actual content, leaving the plot
  floating in a mostly-blank page; also fixed a thin black border left by a
  sub-point rounding gap introduced while fixing the page sizing.
- A timer race (`StartDelay cannot be set while Timer is running`) that
  could abort a figure's resize refresh when a rapid resize event landed
  while the previous settle-timer callback was still finishing.

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
