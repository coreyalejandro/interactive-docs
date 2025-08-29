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
