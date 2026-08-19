import { pathToFileURL } from "node:url";
import path from "node:path";
import playwright from "playwright";

const [input, output, format] = process.argv.slice(2);
if (!input || !output || !["Letter", "A4"].includes(format)) {
  throw new Error("usage: render-pdf.mjs INPUT OUTPUT Letter|A4");
}

const executablePath = process.env.CHROMIUM ?? "/usr/bin/chromium";
const browser = await playwright.chromium.launch({ executablePath, headless: true });
try {
  const page = await browser.newPage();
  await page.goto(pathToFileURL(path.resolve(input)).href, { waitUntil: "load" });
  await page.pdf({
    path: path.resolve(output),
    format,
    printBackground: true,
    displayHeaderFooter: false,
    preferCSSPageSize: false,
    tagged: true,
    outline: true,
  });
} finally {
  await browser.close();
}
