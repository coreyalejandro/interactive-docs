"use client";

import React, { useState } from "react";
import { convertMarkdownStringToAst } from "../../packages/converter/src/markdown";
import { convertPdfToAst } from "../../packages/pdf/src/convert";

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
      <input 
        type="file" 
        accept=".md,.pdf" 
        onChange={handleFile}
        aria-label="Select markdown or PDF file to import"
      />
      {busy && <p className="mt-2 text-sm">Converting…</p>}
      {error && <p className="mt-2 text-sm text-red-600">{error}</p>}
    </section>
  );
}
