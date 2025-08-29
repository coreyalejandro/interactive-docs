#!/usr/bin/env bash
set -euo pipefail

# ---- Safety checks -----------------------------------------------------------
command -v node >/dev/null 2>&1 || { echo "ERROR: Node.js is required."; exit 1; }
command -v npm  >/dev/null 2>&1 || { echo "ERROR: npm is required."; exit 1; }

# Prefer pnpm if present; else use npm
if command -v pnpm >/dev/null 2>&1; then PM=pnpm; else PM=npm; fi

# ---- Project metadata --------------------------------------------------------
APP_NAME="interactive-docs"
ORG="@interactive"
NODE_VERSION="$(node -v)"

echo "Bootstrapping ${APP_NAME} with ${PM} (Node ${NODE_VERSION})"

# ---- Workspace skeleton ------------------------------------------------------
mkdir -p apps/web packages/{converter,pdf,plugin-core,storage,telemetry}
cat > pnpm-workspace.yaml <<YAML
packages:
  - 'apps/*'
  - 'packages/*'
YAML
cat > package.json <<JSON
{
  "name": "${APP_NAME}-workspace",
  "private": true,
  "version": "0.1.0",
  "workspaces": ["apps/*", "packages/*"],
  "scripts": {
    "dev": "next dev -p 3000 -H 0.0.0.0 -w apps/web",
    "build": "turbo run build",
    "lint": "turbo run lint",
    "test": "turbo run test",
    "typecheck": "turbo run typecheck"
  },
  "devDependencies": {
    "turbo": "latest"
  }
}
JSON

# ---- App scaffold ------------------------------------------------------------
mkdir -p apps/web
cd apps/web

# Next.js + TS + Tailwind base
if [ "$PM" = "pnpm" ]; then
  ${PM} init >/dev/null
  ${PM} pkg set name="${ORG}/web"
  ${PM} pkg set type="module"
  ${PM} pkg set scripts.dev="next dev"
  ${PM} pkg set scripts.build="next build"
  ${PM} pkg set scripts.start="next start"
  ${PM} pkg set scripts.lint="eslint ."
  ${PM} pkg set scripts.test="vitest --run"
  ${PM} pkg set scripts.typecheck="tsc --noEmit"
else
  ${PM} init -y >/dev/null
  ${PM} pkg set name="${ORG}/web"
  ${PM} pkg set type="module"
  ${PM} pkg set scripts.dev="next dev"
  ${PM} pkg set scripts.build="next build"
  ${PM} pkg set scripts.start="next start"
  ${PM} pkg set scripts.lint="eslint ."
  ${PM} pkg set scripts.test="vitest --run"
  ${PM} pkg set scripts.typecheck="tsc --noEmit"
fi

${PM} install next@latest react@latest react-dom@latest typescript@latest @types/node@latest @types/react@latest @types/react-dom@latest \
             tailwindcss postcss autoprefixer \
             class-variance-authority clsx tailwind-merge \
             next-themes zod jotai radix-ui react-aria @radix-ui/react-icons \
             @tiptap/react @tiptap/pm @tiptap/starter-kit \
             unified remark-parse remark-frontmatter remark-gfm remark-rehype rehype-raw rehype-slug rehype-autolink-headings rehype-katex \
             katex prismjs \
             pdfjs-dist \
             dexie idb \
             nanoid \
             vitest @vitest/ui @vitest/coverage-v8 jsdom \
             eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin eslint-config-next

# Tailwind config
${PM} exec tailwindcss init -p >/dev/null

# TS config
cat > tsconfig.json <<'JSON'
{
  "extends": ["next/tsconfig"],
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@converter/*": ["../..//packages/converter/src/*"],
      "@pdf/*": ["../..//packages/pdf/src/*"],
      "@plugin-core/*": ["../..//packages/plugin-core/src/*"],
      "@storage/*": ["../..//packages/storage/src/*"],
      "@telemetry/*": ["../..//packages/telemetry/src/*"]
    }
  }
}
JSON

# Tailwind setup
cat > tailwind.config.ts <<'TS'
import type { Config } from "tailwindcss";
const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", "ui-sans-serif", "system-ui"]
      }
    }
  },
  plugins: []
};
export default config;
TS

cat > postcss.config.js <<'JS'
module.exports = { plugins: { tailwindcss: {}, autoprefixer: {} } }
JS

mkdir -p app api components lib public styles
cat > styles/globals.css <<'CSS'
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Dyslexia-aware defaults and motion guard */
:root { scroll-behavior: smooth; }
@media (prefers-reduced-motion: reduce) {
  * { animation-duration: 0.001ms !important; animation-iteration-count: 1 !important; transition-duration: 0.001ms !important; }
}
CSS

# Next config
cat > next.config.mjs <<'MJS'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  experimental: { typedRoutes: true }
};
export default nextConfig;
MJS

# App Router layout + page + basic UI
cat > app/layout.tsx <<'TSX'
import "./../styles/globals.css";
import { ReactNode } from "react";
import { ThemeProvider } from "next-themes";

export const metadata = {
  title: "Interactive Docs",
  description: "Markdown/PDF → Interactive Web Docs with Self-Improvement"
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="min-h-dvh bg-white text-neutral-900 dark:bg-neutral-950 dark:text-neutral-100">
        <ThemeProvider attribute="class" defaultTheme="dark" enableSystem>
          <main className="mx-auto max-w-6xl p-4">{children}</main>
        </ThemeProvider>
      </body>
    </html>
  );
}
TSX

cat > app/page.tsx <<'TSX'
"use client";

import { useState } from "react";
import { DemoUploader } from "@/components/DemoUploader";
import { Viewer } from "@/components/Viewer";
import { ThemeSwitcher } from "@/components/ThemeSwitcher";

export default function HomePage() {
  const [doc, setDoc] = useState<any>(null);
  return (
    <div className="space-y-6">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Interactive Document System</h1>
        <ThemeSwitcher />
      </header>

      <p className="text-sm opacity-80">
        Import a Markdown or PDF file to convert it into an interactive, accessible document. Telemetry runs locally first.
      </p>

      <DemoUploader onLoaded={setDoc} />

      {doc && <Viewer doc={doc} />}
    </div>
  );
}
TSX

# Minimal components: Theme switcher, Uploader, Viewer
cat > components/ThemeSwitcher.tsx <<'TSX'
"use client";
import { useTheme } from "next-themes";

export function ThemeSwitcher() {
  const { theme, setTheme } = useTheme();
  const next = theme === "dark" ? "light" : "dark";
  return (
    <button
      className="rounded-lg border px-3 py-1 text-sm"
      onClick={() => setTheme(next)}
      aria-label="Toggle theme"
    >
      Theme: {theme ?? "system"}
    </button>
  );
}
TSX

cat > components/DemoUploader.tsx <<'TSX'
"use client";

import { useState } from "react";
import { convertMarkdownStringToAst } from "@converter/markdown";
import { convertPdfToAst } from "@pdf/convert";

type Props = { onLoaded: (doc: any) => void };

export function DemoUploader({ onLoaded }: Props) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setBusy(true); setError(null);
    try {
      const ext = file.name.toLowerCase().split(".").pop();
      const text = ext === "md" ? await file.text() : null;
      const buf = ext === "pdf" ? await file.arrayBuffer() : null;

      let ast: any;
      if (ext === "md" && text) ast = await convertMarkdownStringToAst(text);
      else if (ext === "pdf" && buf) ast = await convertPdfToAst(new Uint8Array(buf));
      else throw new Error("Unsupported file type. Use .md or .pdf");

      onLoaded(ast);
    } catch (err: any) {
      setError(err.message || "Conversion failed");
    } finally { setBusy(false); }
  }

  return (
    <section className="rounded-xl border p-4">
      <label className="block text-sm font-medium mb-2">Import .md or .pdf</label>
      <input type="file" accept=".md,.pdf" onChange={handleFile} />
      {busy && <p className="mt-2 text-sm">Converting…</p>}
      {error && <p className="mt-2 text-sm text-red-600">{error}</p>}
    </section>
  );
}
TSX

cat > components/Viewer.tsx <<'TSX'
"use client";

import React from "react";

type Node =
  | { id: string; type: "h1" | "h2" | "h3" | "p"; text: string }
  | { id: string; type: "code"; lang?: string; text: string }
  | { id: string; type: "list"; ordered?: boolean; items: { text: string }[] };

export function Viewer({ doc }: { doc: { title?: string; nodes: Node[] } }) {
  return (
    <article className="prose dark:prose-invert max-w-none">
      {doc.title && <h1>{doc.title}</h1>}
      {doc.nodes?.map((n) => {
        if (n.type === "p") return <p key={n.id}>{n.text}</p>;
        if (n.type === "h1") return <h1 key={n.id}>{n.text}</h1>;
        if (n.type === "h2") return <h2 key={n.id}>{n.text}</h2>;
        if (n.type === "h3") return <h3 key={n.id}>{n.text}</h3>;
        if (n.type === "code") return (
          <pre key={n.id}><code>{n.text}</code></pre>
        );
        if (n.type === "list") return (
          <ul key={n.id}>{n.items.map((it, i) => <li key={i}>{it.text}</li>)}</ul>
        );
        return null;
      })}
    </article>
  );
}
TSX

# ---- Libraries ---------------------------------------------------------------
cd ../../packages/converter
mkdir -p src
cat > package.json <<JSON
{
  "name": "${ORG}/converter",
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "exports": { ".": "./src/index.ts" }
}
JSON
cat > src/index.ts <<'TS'
export * from "./markdown";
TS
cat > src/markdown.ts <<'TS'
import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkGfm from "remark-gfm";
import remarkFrontmatter from "remark-frontmatter";
import remarkRehype from "remark-rehype";

export async function convertMarkdownStringToAst(md: string): Promise<any> {
  const tree = await unified()
    .use(remarkParse).use(remarkFrontmatter).use(remarkGfm).use(remarkRehype)
    .process(md);
  // Minimal normalization → simple AST per spec sample
  const text = String(tree);
  const nodes = text.split("\n").filter(Boolean).map((line, i) => ({
    id: `n${i+1}`,
    type: line.startsWith("# ") ? "h1" : line.startsWith("## ") ? "h2" : "p",
    text: line.replace(/^#+\s*/, "")
  }));
  return { title: nodes.find(n => n.type === "h1")?.text ?? "Document", nodes };
}
TS

cd ../pdf
mkdir -p src
cat > package.json <<JSON
{
  "name": "${ORG}/pdf",
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "exports": { ".": "./src/index.ts" }
}
JSON
cat > src/index.ts <<'TS'
export * from "./convert";
TS
cat > src/convert.ts <<'TS'
import * as pdfjsLib from "pdfjs-dist";

export async function convertPdfToAst(bytes: Uint8Array): Promise<any> {
  // pdf.js in worker-less mode for SSR/dev simplicity
  // @ts-ignore
  pdfjsLib.GlobalWorkerOptions.workerSrc = "//cdnjs.cloudflare.com/ajax/libs/pdf.js/4.2.67/pdf.worker.min.js";
  const loadingTask = pdfjsLib.getDocument({ data: bytes });
  const pdf = await loadingTask.promise;
  const nodes: any[] = [];
  for (let p = 1; p <= pdf.numPages; p++) {
    const page = await pdf.getPage(p);
    const content = await page.getTextContent();
    const text = content.items.map((it: any) => it.str).join(" ").trim();
    if (text) nodes.push({ id: `p${p}`, type: "p", text });
  }
  return { title: "PDF Document", nodes };
}
TS

cd ../plugin-core
mkdir -p src
cat > package.json <<JSON
{
  "name": "${ORG}/plugin-core",
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "exports": { ".": "./src/index.ts" }
}
JSON
cat > src/index.ts <<'TS'
export type PluginCapability = "block" | "inline" | "panel" | "toolbar" | "exporter" | "importer";

export interface DocPlugin {
  id: string;
  name: string;
  version: string;
  capabilities: PluginCapability[];
  styles?: Record<string, string>;
  init(ctx: any): Promise<void>;
  render(node: any, ctx: any): HTMLElement | Promise<HTMLElement>;
  panel?(ctx: any): HTMLElement | Promise<HTMLElement>;
  toolbarItems?(): any[];
  onEvent?(event: any, ctx: any): void;
  serialize?(node: any): any;
  deserialize?(data: any): any;
  dispose?(): void;
}

export interface PluginManifest {
  id: string;
  name: string;
  version: string;
  entry: string;
  sandbox: "iframe" | "worker" | "none";
  permissions?: ("fs.read"|"fs.write"|"net.fetch")[];
}

export function registerPlugin(_manifest: PluginManifest, _module: DocPlugin): void {
  // Placeholder registration; will be extended in Step 2.
}
TS

cd ../storage
mkdir -p src
cat > package.json <<JSON
{
  "name": "${ORG}/storage",
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "exports": { ".": "./src/index.ts" }
}
JSON
cat > src/index.ts <<'TS'
import Dexie from "dexie";

export interface DocRecord { id: string; json: any; updatedAt: string; }

class DocDB extends Dexie {
  docs: Dexie.Table<DocRecord, string>;
  constructor() {
    super("interactive-docs");
    this.version(1).stores({ docs: "id,updatedAt" });
    this.docs = this.table("docs");
  }
}
export const db = new DocDB();

export async function saveDoc(id: string, json: any) {
  await db.docs.put({ id, json, updatedAt: new Date().toISOString() });
}
export async function loadDoc(id: string) {
  return db.docs.get(id);
}
TS

cd ../telemetry
mkdir -p src
cat > package.json <<JSON
{
  "name": "${ORG}/telemetry",
  "version": "0.1.0",
  "type": "module",
  "main": "src/index.ts",
  "exports": { ".": "./src/index.ts" }
}
JSON
cat > src/index.ts <<'TS'
export type TelemetryEvent = {
  ts: string; session: string; user: string; event: string; docId?: string;
  metrics?: Record<string, number>; context?: Record<string, any>;
  privacy?: { pseudonymous: boolean; pii: boolean };
};

const buffer: TelemetryEvent[] = [];

export function track(e: Omit<TelemetryEvent,"ts">) {
  buffer.push({ ts: new Date().toISOString(), ...e });
}
export function flush(): TelemetryEvent[] {
  const out = buffer.splice(0, buffer.length);
  return out;
}
TS

# ---- Done --------------------------------------------------------------------
echo "Bootstrap complete."
echo
echo "Next steps:"
echo "  1) cd apps/web"
echo "  2) ${PM} run dev"
echo "  3) Open http://localhost:3000 and import a .md or .pdf"
