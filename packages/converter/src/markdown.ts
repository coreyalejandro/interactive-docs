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
