import Dexie from "dexie";

export interface DocRecord {
  id: string;
  json: any;
  updatedAt: string;
}

class DocDB extends Dexie {
  docs: Dexie.Table<DocRecord, string>;

  constructor() {
    super("interactive-docs");
    this.version(1).stores({
      docs: "id,updatedAt"
    });
    this.docs = this.table("docs");
  }
}

export const db = new DocDB();

export async function saveDoc(id: string, json: any) {
  await db.docs.put({
    id,
    json,
    updatedAt: new Date().toISOString()
  });
}

export async function loadDoc(id: string) {
  return db.docs.get(id);
}
