export type PluginCapability = 
  | "block" 
  | "inline" 
  | "panel" 
  | "toolbar" 
  | "exporter" 
  | "importer";

export interface DocPlugin {
  id: string;
  name: string;
  version: string;
  capabilities: PluginCapability[];
  styles?: Record<string, string>;
  
  init(ctx: any): Promise<void>;
  render(node: any, ctx: any): HTMLElement | Promise<HTMLElement>;
  panel?(ctx: any): HTMLElement | Promise<HTMLElement>;
  toolbarItems?(): any[];
  onEvent?(event: any, ctx: any): void;
  serialize?(node: any): any;
  deserialize?(data: any): any;
  dispose?(): void;
}

export interface PluginManifest {
  id: string;
  name: string;
  version: string;
  entry: string;
  sandbox: "iframe" | "worker" | "none";
  permissions?: ("fs.read"|"fs.write"|"net.fetch")[];
}

export function registerPlugin(_manifest: PluginManifest, _module: DocPlugin): void {
  // Placeholder registration; will be extended in Step 2.
}
