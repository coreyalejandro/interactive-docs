import "./../styles/globals.css";
import { ReactNode } from "react";
import { ThemeProvider } from "next-themes";

export const metadata = {
  title: "Interactive Docs",
  description: "Markdown/PDF → Interactive Web Docs with Self-Improvement"
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="min-h-dvh bg-white text-neutral-900 dark:bg-neutral-950 dark:text-neutral-100">
        <ThemeProvider attribute="class" defaultTheme="dark" enableSystem>
          <main className="mx-auto max-w-6xl p-4">{children}</main>
        </ThemeProvider>
      </body>
    </html>
  );
}
