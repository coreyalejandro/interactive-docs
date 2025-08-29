#!/usr/bin/env bash
set -euo pipefail

# Detect package manager chosen in Step 1
if command -v pnpm >/dev/null 2>&1; then PM=pnpm; else PM=npm; fi
echo "Using ${PM}"

# -----------------------------
# Update: robust MD converter
# -----------------------------
cat > packages/converter/src/markdown.ts <<'TS'
import { unified } from "unified";
import remarkParse from "remark-parse";
import remarkGfm from "remark-gfm";
import remarkFrontmatter from "remark-frontmatter";

type Node =
  | { id: string; type: "h1" | "h2" | "h3" | "p"; text: string }
  | { id: string; type: "code"; lang?: string; text: string }
  | { id: string; type: "list"; ordered?: boolean; items: { text: string }[] };

export async function convertMarkdownStringToAst(md: string): Promise<{ title?: string; nodes: Node[] }> {
  const tree: any = unified().use(remarkParse).use(remarkFrontmatter).use(remarkGfm).parse(md);
  const nodes: Node[] = [];
  let title: string | undefined;
  let i = 0;

  const children: any[] = Array.isArray(tree.children) ? tree.children : [];
  for (const n of children) {
    if (n.type === "heading") {
      const level = n.depth as number;
      const type = (level === 1 ? "h1" : level === 2 ? "h2" : "h3") as "h1" | "h2" | "h3";
      const text = (n.children || []).map((c: any) => c.value ?? "").join("").trim();
      const id = `n${++i}`;
      nodes.push({ id, type, text });
      if (!title && type === "h1") title = text;
    } else if (n.type === "paragraph") {
      const text = (n.children || []).map((c: any) => c.value ?? "").join("").trim();
      if (text) nodes.push({ id: `n${++i}`, type: "p", text });
    } else if (n.type === "code") {
      nodes.push({ id: `n${++i}`, type: "code", lang: n.lang || "text", text: n.value || "" });
    } else if (n.type === "list") {
      const items = (n.children || []).map((li: any) => {
        const t = (li.children || []).flatMap((c: any) =>
          c.type === "paragraph" ? (c.children || []).map((cc: any) => cc.value ?? "") : []
        ).join("").trim();
        return { text: t };
      });
      nodes.push({ id: `n${++i}`, type: "list", ordered: !!n.ordered, items });
    }
  }

  return { title: title || "Document", nodes };
}
TS

# -----------------------------
# New components: TOC, Search, Editor
# -----------------------------
cat > apps/web/components/Toc.tsx <<'TSX'
"use client";
type Node = { id: string; type: "h1" | "h2" | "h3" | "p" | "code" | "list"; text?: string };
export function Toc({ doc }: { doc: { nodes: Node[] } }) {
  const items = (doc.nodes || []).filter(n => n.type === "h1" || n.type === "h2" || n.type === "h3") as any[];
  function go(id: string) {
    const el = document.getElementById("h-" + id);
    if (el) el.scrollIntoView({ behavior: "smooth", block: "start" });
  }
  return (
    <nav aria-label="Table of contents" className="sticky top-4 max-h-[80dvh] overflow-auto space-y-1 text-sm">
      <div className="font-semibold mb-2">Contents</div>
      {items.map((n) => (
        <button
          key={n.id}
          onClick={() => go(n.id)}
          className="block w-full text-left truncate rounded px-2 py-1 hover:bg-neutral-100 dark:hover:bg-neutral-900"
          style={{ paddingLeft: n.type === "h1" ? 8 : n.type === "h2" ? 16 : 24 }}
        >
          {n.text}
        </button>
      ))}
    </nav>
  );
}
TSX

cat > apps/web/components/SearchBox.tsx <<'TSX'
"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import { track } from "@telemetry";
export function SearchBox({ onChange }: { onChange: (q: string) => void }) {
  const [q, setQ] = useState("");
  const countRef = useRef(0);

  // announce match count changes
  useEffect(() => {
    const marks = document.querySelectorAll("article mark");
    countRef.current = marks.length;
    track({ session: "local", user: "anon", event: "search.changed", metrics: { matches: marks.length } });
  }, [q]);

  function next() {
    const marks = Array.from(document.querySelectorAll("article mark"));
    if (!marks.length) return;
    const i = (Number((window as any).__matchIndex || 0) + 1) % marks.length;
    (window as any).__matchIndex = i;
    (marks[i] as HTMLElement).scrollIntoView({ behavior: "smooth", block: "center" });
  }

  return (
    <div className="flex items-center gap-2">
      <input
        value={q}
        onChange={(e) => { setQ(e.target.value); onChange(e.target.value); }}
        placeholder="Search…"
        className="w-full rounded border px-2 py-1 text-sm"
        aria-label="Search document text"
      />
      <button onClick={next} className="rounded border px-2 py-1 text-sm">Next</button>
    </div>
  );
}
TSX

cat > apps/web/components/EditorPanel.tsx <<'TSX'
"use client";

import { useEffect, useMemo, useState } from "react";
import { convertMarkdownStringToAst } from "@converter/markdown";
import { saveDoc, loadDoc } from "@storage";
import { track } from "@telemetry";

type Doc = { title?: string; nodes: any[] };

function astToMarkdown(doc: Doc): string {
  const lines: string[] = [];
  for (const n of doc.nodes || []) {
    if (n.type === "h1") lines.push(`# ${n.text}`);
    else if (n.type === "h2") lines.push(`## ${n.text}`);
    else if (n.type === "h3") lines.push(`### ${n.text}`);
    else if (n.type === "p") lines.push(n.text);
    else if (n.type === "code") lines.push("```" + (n.lang || "") + "\n" + n.text + "\n```");
    else if (n.type === "list") lines.push(...(n.items || []).map((it: any) => `- ${it.text}`));
  }
  return lines.join("\n\n");
}

export function EditorPanel({ doc, onDoc }: { doc: Doc; onDoc: (d: Doc) => void }) {
  const [open, setOpen] = useState(false);
  const [md, setMd] = useState("");

  useEffect(() => { setMd(astToMarkdown(doc)); }, [doc]);

  async function save() {
    const next = await convertMarkdownStringToAst(md);
    onDoc(next as any);
    await saveDoc("current", next);
    track({ session: "local", user: "anon", event: "editor.save", docId: "current" });
  }
  async function load() {
    const row = await loadDoc("current");
    if (row?.json) onDoc(row.json);
  }

  return (
    <aside className="space-y-2">
      <button className="rounded border px-2 py-1 text-sm" onClick={() => setOpen(!open)}>
        {open ? "Close Editor" : "Open Editor"}
      </button>
      <div className="flex gap-2">
        <button className="rounded border px-2 py-1 text-sm" onClick={save}>Save</button>
        <button className="rounded border px-2 py-1 text-sm" onClick={load}>Load</button>
      </div>
      {open && (
        <textarea
          value={md}
          onChange={(e) => setMd(e.target.value)}
          className="h-[50dvh] w-full rounded border p-2 text-sm font-mono"
          aria-label="Markdown editor"
        />
      )}
    </aside>
  );
}
TSX

# -----------------------------
# Viewer: add anchors + highlights
# -----------------------------
cat > apps/web/components/Viewer.tsx <<'TSX'
"use client";
import React from "react";

type Node =
  | { id: string; type: "h1" | "h2" | "h3" | "p"; text: string }
  | { id: string; type: "code"; lang?: string; text: string }
  | { id: string; type: "list"; ordered?: boolean; items: { text: string }[] };

function escapeRegExp(s: string) { return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"); }
function Marked({ text, q }: { text: string; q: string }) {
  if (!q) return <>{text}</>;
  const parts = text.split(new RegExp(`(${escapeRegExp(q)})`, "ig"));
  return (
    <>
      {parts.map((p, i) =>
        p.toLowerCase() === q.toLowerCase() ? <mark key={i}>{p}</mark> : <React.Fragment key={i}>{p}</React.Fragment>
      )}
    </>
  );
}

export function Viewer({ doc, q }: { doc: { title?: string; nodes: Node[] }, q: string }) {
  return (
    <article className="prose dark:prose-invert max-w-none">
      {doc.title && <h1 id={"h-title"}>{doc.title}</h1>}
      {doc.nodes?.map((n) => {
        if (n.type === "p") return <p key={n.id}><Marked text={n.text} q={q} /></p>;
        if (n.type === "h1") return <h1 id={"h-" + n.id} key={n.id}><Marked text={n.text} q={q} /></h1>;
        if (n.type === "h2") return <h2 id={"h-" + n.id} key={n.id}><Marked text={n.text} q={q} /></h2>;
        if (n.type === "h3") return <h3 id={"h-" + n.id} key={n.id}><Marked text={n.text} q={q} /></h3>;
        if (n.type === "code") return (
          <pre key={n.id} className="relative">
            <button
              className="absolute right-2 top-2 rounded border px-2 py-1 text-xs"
              onClick={() => navigator.clipboard.writeText(n.text)}
              aria-label="Copy code"
            >Copy</button>
            <code>{n.text}</code>
          </pre>
        );
        if (n.type === "list") return (
          <ul key={n.id}>{n.items.map((it, i) => <li key={i}><Marked text={it.text} q={q} /></li>)}</ul>
        );
        return null;
      })}
    </article>
  );
}
TSX

# -----------------------------
# Page: wire TOC + Search + Editor + Telemetry
# -----------------------------
cat > apps/web/app/page.tsx <<'TSX'
"use client";

import { useState } from "react";
import { DemoUploader } from "@/components/DemoUploader";
import { Viewer } from "@/components/Viewer";
import { ThemeSwitcher } from "@/components/ThemeSwitcher";
import { Toc } from "@/components/Toc";
import { SearchBox } from "@/components/SearchBox";
import { EditorPanel } from "@/components/EditorPanel";
import { track } from "@telemetry";

export default function HomePage() {
  const [doc, setDoc] = useState<any>(null);
  const [q, setQ] = useState("");

  function onLoaded(d: any) {
    setDoc(d);
    track({ session: "local", user: "anon", event: "import.complete", docId: "current", context: { source: "uploader" } });
  }

  return (
    <div className="space-y-6">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Interactive Document System</h1>
        <ThemeSwitcher />
      </header>

      <p className="text-sm opacity-80">
        Import a Markdown or PDF file to convert it into an interactive, accessible document. Telemetry runs locally first.
      </p>

      <DemoUploader onLoaded={onLoaded} />

      {doc && (
        <div className="grid grid-cols-12 gap-4">
          <aside className="col-span-3 hidden md:block">
            <SearchBox onChange={setQ} />
            <div className="h-4" />
            <Toc doc={doc} />
          </aside>
          <main className="col-span-12 md:col-span-6">
            <Viewer doc={doc} q={q} />
          </main>
          <aside className="col-span-12 md:col-span-3">
            <EditorPanel doc={doc} onDoc={setDoc} />
          </aside>
        </div>
      )}
    </div>
  );
}
TSX

echo "Step 2 files written."
