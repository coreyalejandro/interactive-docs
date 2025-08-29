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
