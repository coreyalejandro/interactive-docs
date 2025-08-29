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
