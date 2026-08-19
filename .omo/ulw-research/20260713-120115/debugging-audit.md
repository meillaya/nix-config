# Runtime debugging audit

**Surface:** static HTML report served over HTTP, Chromium print-to-PDF, and external citation resolution  
**Runtime:** Node.js 24.16.0, Playwright, Chromium 150, Python HTTP server  
**Audited build:** `REPORT.html` and `REPORT.pdf` generated after `SYNTHESIS.md`

## Hypothesis matrix

| ID | Hypothesis | Distinguishing runtime probe | Result |
|---|---|---|---|
| H1 | Long inline Nix identifiers widen the mobile document unless prose and inline code may wrap. | At a 375 px viewport, measure document/element overflow on the current CSS, then inject the old no-wrap behavior and measure again. | **Confirmed and toggled:** current `0/0` px; no-wrap variant `172/188` px. |
| H2 | A network-backed missing favicon is the source of the otherwise unexplained console 404. | Load the current data favicon in one fresh context and a route-mutated `/missing-favicon.ico` in another. | **Confirmed and toggled:** current `[]`; missing variant records one HTTP 404 console error. |
| H3 | The original GitHub secret-removal citation moved. | Resolve both URLs with redirects enabled. | **Confirmed and toggled:** old URL HTTP 404; current official URL HTTP 200. |
| H4 | Chromium ignores the obsolete `--print-to-pdf-no-header` spelling, leaving local paths in the PDF. | Render identical HTML using the obsolete flag and Playwright's `displayHeaderFooter: false`, then inspect extracted text/annotations. | **Confirmed and toggled:** obsolete flag exposes a local footer; current Letter/A4 PDFs expose no local path or `file://` annotation. |
| H5 | In-place table postprocessing corrupts an already-processed report on rerun. | Process the shipped HTML to a second file and compare SHA-256 plus wrapper/caption counts. | **Former behavior confirmed, repair verified:** the atomic idempotent processor now returns the identical SHA-256 with exactly four wrappers/captions. |
| H6 | Repository-relative citations work from `file://` but fail when the report directory is the HTTP publication root. | Request every non-fragment same-origin link through the exact QA URL before and after moving cited source snapshots beside the report. | **Confirmed and repaired:** seven former links returned 404; all 28 current local links return 200 at every viewport. |
| H7 | Browser error recovery hides invalid paired end tags on HTML void inputs. | Validate the generated HTML and count literal `</input>` strings. | **Confirmed and repaired:** deterministic HTML5 build plus normalization yields zero end tags and `xmllint --html --noout` exits 0. |

## Minimal repairs

1. `report.css` permits wrapping in prose and inline code while retaining local scrolling for `pre`, tables, and navigation.
2. `report-template.html` declares a data favicon, which remains offline and causes no network request.
3. `SYNTHESIS.md` uses the current official GitHub secret-removal URL.
4. PDF generation uses Playwright's typed `displayHeaderFooter: false` option and strips local bundle links only from the print copy, preventing author-specific annotations.
5. Report generation starts from a fresh Pandoc HTML5 file, validates derived counts/revision, and atomically applies an idempotent table transform.
6. Exact repository citations use adjacent content-hashed source snapshots; browser QA fails on any non-200 same-origin artifact link.
7. Browser QA now fails on every semantic/accessibility metric it records rather than merely serializing them.

## Red-to-green evidence

```text
H1 current: documentOverflow=0, maxElementOverflow=0
H1 old behavior: documentOverflow=172, maxElementOverflow=188

H2 current: no console errors
H2 missing favicon: one 404 console error

H3 old URL: 404
H3 new URL: 200

H4 obsolete print flag: file URL count=1
H4 current Letter/A4 PDFs: local path and file URL count=0

H5 postprocess before/after SHA-256: identical
H5 wrappers/captions: 4/4

H6 former repository links: 7 HTTP 404
H6 current local bundle links: 28/28 HTTP 200

H7 invalid input end tags: 0
H7 xmllint HTML validation: exit 0
```

## Manual browser and document QA

- Playwright loaded the actual HTTP surface at 375×812, 768×1024, and 1280×900.
- Every run returned HTTP 200 with no console or page errors, exactly one H1, one main landmark, one contents navigation, four tables, 86 valid fragment links, zero missing fragments, zero body/element overflow, and a working first-tab skip link to `#report`.
- Fresh full-page and top screenshots were captured after the final source edit.
- The 32-page Letter PDF and 30-page A4 proof are tagged, unencrypted, and contain no NUL or Unicode replacement characters in extracted text.
- Fresh representative Letter pages 1, 2, 3, 16, 24, and 32 plus A4 pages 1, 15, and 30 were rasterized and inspected for clipping, table layout, code blocks, pagination, and unwanted browser chrome.
- All 24 unique external citations embedded in the rendered report returned HTTP 2xx or 3xx after redirects.

## Partial-evidence boundary

The report itself records physical and external operations that cannot be performed from this workstation: real laptop WLAN enumeration, destructive installs on each declared hardware class, native Mac activation, Secure Boot, and provider-side credential rotation. Those are not marked green. Their required commands and acceptance evidence remain explicit in the synthesis.

## Cleanup receipt

Temporary mutation script, alternate PDFs, extracted temporary page text, and the root debug journal were removed after their observed results were copied here. The production Git tree remained unchanged.
