import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import playwright from "playwright";

const here = path.dirname(fileURLToPath(import.meta.url));
const base = process.env.REPORT_URL ?? "http://127.0.0.1:8765/.omo/ulw-research/20260713-120115/REPORT.html";
const outDir = path.join(here, "visual-qa");
await fs.mkdir(outDir, { recursive: true });
const browser = await playwright.chromium.launch({ executablePath: process.env.CHROMIUM ?? "/usr/bin/chromium", headless: true });
const results = [];

for (const viewport of [
  { name: "mobile", width: 375, height: 812 },
  { name: "tablet", width: 768, height: 1024 },
  { name: "desktop", width: 1280, height: 900 },
]) {
  const context = await browser.newContext({ viewport: { width: viewport.width, height: viewport.height }, deviceScaleFactor: 1 });
  const page = await context.newPage();
  const consoleErrors = [];
  const pageErrors = [];
  page.on("console", (message) => { if (message.type() === "error") consoleErrors.push(message.text()); });
  page.on("pageerror", (error) => pageErrors.push(String(error)));
  const response = await page.goto(base, { waitUntil: "networkidle" });
  await page.screenshot({ path: path.join(outDir, `${viewport.name}-full.png`), fullPage: true });
  await page.screenshot({ path: path.join(outDir, `${viewport.name}-top.png`) });
  const metrics = await page.evaluate(() => {
    const links = [...document.querySelectorAll("a[href]")];
    const fragments = links.map((anchor) => anchor.getAttribute("href")).filter((href) => href?.startsWith("#"));
    const missingFragments = fragments.filter((href) => !document.getElementById(decodeURIComponent(href.slice(1))));
    const overflow = [...document.querySelectorAll("body *")]
      .filter((element) => element.scrollWidth > element.clientWidth + 1)
      .filter((element) => !["PRE", "TABLE", "NAV"].includes(element.tagName) && !element.classList.contains("table-region"))
      .slice(0, 20)
      .map((element) => ({ tag: element.tagName, id: element.id, className: String(element.className), clientWidth: element.clientWidth, scrollWidth: element.scrollWidth }));
    const ids = [...document.querySelectorAll("[id]")].map((element) => element.id);
    const duplicateIds = [...new Set(ids.filter((id, index) => ids.indexOf(id) !== index))];
    const localLinks = [...new Set(links
      .map((anchor) => new URL(anchor.href, location.href))
      .filter((url) => ["http:", "https:"].includes(url.protocol) && url.origin === location.origin && !url.hash)
      .map((url) => url.href))];
    const unsafeSchemes = links
      .map((anchor) => anchor.getAttribute("href") ?? "")
      .filter((href) => /^(javascript|data|file):/i.test(href));
    const tables = [...document.querySelectorAll("table")];
    const tableSemanticFailures = tables.map((table, index) => ({
      index,
      caption: table.querySelectorAll(":scope > caption").length,
      unscopedColumns: table.querySelectorAll("thead th:not([scope='col'])").length,
      rows: table.querySelectorAll("tbody tr").length,
      scopedRows: table.querySelectorAll("tbody tr > th[scope='row']:first-child").length,
      wrapped: Boolean(table.closest(".table-region[role='region'][tabindex='0']")),
      described: Boolean(table.closest(".table-region")?.getAttribute("aria-describedby")),
      labelled: Boolean(table.closest(".table-region")?.getAttribute("aria-labelledby")),
    })).filter((entry) => entry.caption !== 1 || entry.unscopedColumns || entry.rows !== entry.scopedRows || !entry.wrapped || !entry.described || !entry.labelled);
    return {
      title: document.title,
      lang: document.documentElement.lang,
      h1Count: document.querySelectorAll("h1").length,
      mainCount: document.querySelectorAll("main").length,
      navCount: document.querySelectorAll("nav").length,
      tableCount: tables.length,
      externalLinkCount: links.filter((anchor) => {
        const url = new URL(anchor.getAttribute("href"), location.href);
        return ["http:", "https:"].includes(url.protocol) && url.origin !== location.origin;
      }).length,
      fragmentLinkCount: fragments.length,
      missingFragments: [...new Set(missingFragments)],
      bodyOverflow: document.documentElement.scrollWidth - document.documentElement.clientWidth,
      overflow,
      reportTextLength: document.querySelector("main")?.innerText.length ?? 0,
      tableCaptionCount: document.querySelectorAll("table > caption").length,
      columnHeaderCount: document.querySelectorAll('th[scope="col"]').length,
      rowHeaderCount: document.querySelectorAll('th[scope="row"]').length,
      tableRegionCount: document.querySelectorAll('.table-region[role="region"][tabindex="0"]').length,
      visibleTableHintCount: [...document.querySelectorAll(".table-hint")].filter((hint) => getComputedStyle(hint).display !== "none").length,
      duplicateIds,
      localLinks,
      unsafeSchemes,
      tableSemanticFailures,
      hasRequiredContent: ["141 observations", "58 canonical claims", "P0 — before another unattended install", "closing-context-audit.md", "Emacs"].every((text) => document.body.innerText.includes(text)),
    };
  });
  const localLinkResults = [];
  for (const url of metrics.localLinks) {
    const localResponse = await context.request.get(url, { failOnStatusCode: false });
    localLinkResults.push({ url, status: localResponse.status() });
  }
  await page.keyboard.press("Tab");
  const firstFocus = await page.evaluate(() => ({ tag: document.activeElement?.tagName, className: document.activeElement?.className, text: document.activeElement?.textContent?.trim() }));
  await page.keyboard.press("Enter");
  const skipHash = await page.evaluate(() => location.hash);
  results.push({ viewport, status: response?.status(), consoleErrors, pageErrors, metrics, localLinkResults, firstFocus, skipHash });
  await context.close();
}

await browser.close();
await fs.writeFile(path.join(outDir, "browser-qa.json"), JSON.stringify(results, null, 2));
const failed = results.some((result) =>
  result.status !== 200
  || result.consoleErrors.length
  || result.pageErrors.length
  || result.metrics.title !== "Nix configuration portability and immediate-usability review"
  || result.metrics.lang !== "en-CA"
  || result.metrics.h1Count !== 1
  || result.metrics.mainCount !== 1
  || result.metrics.navCount !== 1
  || result.metrics.tableCount !== 4
  || result.metrics.reportTextLength < 60000
  || result.metrics.tableCaptionCount !== 4
  || result.metrics.tableRegionCount !== 4
  || result.metrics.visibleTableHintCount !== 4
  || result.metrics.missingFragments.length
  || result.metrics.bodyOverflow > 1
  || result.metrics.overflow.length
  || result.metrics.duplicateIds.length
  || result.metrics.unsafeSchemes.length
  || result.metrics.tableSemanticFailures.length
  || !result.metrics.hasRequiredContent
  || result.localLinkResults.some((link) => link.status !== 200)
  || result.firstFocus.className !== "skip-link"
  || result.skipHash !== "#report"
);
console.log(JSON.stringify(results, null, 2));
process.exitCode = failed ? 1 : 0;
