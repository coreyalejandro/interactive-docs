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
