"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import { track } from "@telemetry/index";
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
