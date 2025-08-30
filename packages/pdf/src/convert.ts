export async function convertPdfToAst(bytes: Uint8Array): Promise<any> {
  // Only run on client side
  if (typeof window === 'undefined') {
    throw new Error('PDF conversion only available on client side');
  }

  // Dynamic import to avoid SSR issues
  const pdfjsLib = await import("pdfjs-dist");
  
  // pdf.js in worker-less mode for SSR/dev simplicity
  // @ts-ignore
  pdfjsLib.GlobalWorkerOptions.workerSrc = "//cdnjs.cloudflare.com/ajax/libs/pdf.js/4.2.67/pdf.worker.min.js";
  
  const loadingTask = pdfjsLib.getDocument({ data: bytes });
  const pdf = await loadingTask.promise;
  
  const nodes: any[] = [];
  
  for (let p = 1; p <= pdf.numPages; p++) {
    const page = await pdf.getPage(p);
    const content = await page.getTextContent();
    const text = content.items.map((it: any) => it.str).join(" ").trim();
    
    if (text) {
      nodes.push({
        id: `p${p}`,
        type: "p",
        text
      });
    }
  }
  
  return {
    title: "PDF Document",
    nodes
  };
}
