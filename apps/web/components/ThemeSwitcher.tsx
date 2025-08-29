"use client";
import React from "react";
import { useTheme } from "next-themes";

export function ThemeSwitcher() {
  const { theme, setTheme } = useTheme();
  const next = theme === "dark" ? "light" : "dark";
  return (
    <button
      className="rounded-lg border px-3 py-1 text-sm"
      onClick={() => setTheme(next)}
      aria-label="Toggle theme"
    >
      Theme: {theme ?? "system"}
    </button>
  );
}
