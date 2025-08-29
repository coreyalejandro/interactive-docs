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
