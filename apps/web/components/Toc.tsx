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
