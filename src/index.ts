export type TelemetryEvent = {
  ts: string; session: string; user: string; event: string; docId?: string;
  metrics?: Record<string, number>; context?: Record<string, any>;
  privacy?: { pseudonymous: boolean; pii: boolean };
};

const buffer: TelemetryEvent[] = [];

export function track(e: Omit<TelemetryEvent,"ts">) {
  buffer.push({ ts: new Date().toISOString(), ...e });
}
export function flush(): TelemetryEvent[] {
  const out = buffer.splice(0, buffer.length);
  return out;
}
