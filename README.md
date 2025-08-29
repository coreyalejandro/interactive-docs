# Interactive Docs

A modern, local-first document conversion and editing system built with Next.js 14, TypeScript, and a monorepo architecture.

## Features

- **Document Import**: Convert Markdown and PDF files to interactive web documents
- **Local-First Storage**: All data stored locally using IndexedDB
- **Theme Support**: Light/dark mode with system preference detection
- **Search**: Full-text search with match highlighting
- **Table of Contents**: Auto-generated navigation from document headings
- **Markdown Editor**: In-place editing with real-time preview
- **Accessibility**: Dyslexia-aware design with motion reduction support

## Tech Stack

- **Frontend**: Next.js 14 (App Router), React 19, TypeScript
- **Styling**: Tailwind CSS v3, Radix UI components
- **State Management**: Jotai
- **Document Processing**: Unified.js, Remark, PDF.js
- **Storage**: Dexie (IndexedDB wrapper)
- **Editor**: Tiptap
- **Package Manager**: pnpm
- **Monorepo**: Turbo

## Project Structure

```
interactive-docs/
├── apps/
│   └── web/                 # Next.js web application
│       ├── app/            # App Router pages
│       ├── components/     # React components
│       └── styles/         # Global styles
├── packages/
│   ├── converter/          # Document conversion utilities
│   ├── pdf/               # PDF processing
│   ├── plugin-core/       # Plugin system
│   ├── storage/           # Local storage layer
│   └── telemetry/         # Analytics and tracking
└── pnpm-workspace.yaml    # Monorepo configuration
```

## Getting Started

### Prerequisites

- Node.js 18+ 
- pnpm (recommended) or npm

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd interactive-docs
```

2. Install dependencies:
```bash
pnpm install
```

3. Start the development server:
```bash
cd apps/web
pnpm run dev
```

4. Open [http://localhost:3000](http://localhost:3000) in your browser

### Usage

1. **Import Documents**: Click the file upload area and select a `.md` or `.pdf` file
2. **Navigate**: Use the table of contents on the left to jump to sections
3. **Search**: Use the search box to find text within the document
4. **Edit**: Click the editor panel to modify the document in Markdown
5. **Save**: Changes are automatically saved to local storage

## Development

### Available Scripts

- `pnpm run dev` - Start development server
- `pnpm run build` - Build for production
- `pnpm run lint` - Run ESLint
- `pnpm run test` - Run tests
- `pnpm run typecheck` - TypeScript type checking

### Monorepo Commands

From the workspace root:
- `pnpm run dev` - Start web app development server
- `pnpm run build` - Build all packages
- `pnpm run lint` - Lint all packages
- `pnpm run test` - Test all packages

## Architecture

### Document Processing Pipeline

1. **Import**: File upload triggers conversion based on file type
2. **Parse**: Markdown uses Unified.js pipeline, PDFs use PDF.js
3. **Transform**: Convert to internal AST format
4. **Render**: Display in interactive viewer with search and navigation
5. **Edit**: Tiptap editor for Markdown editing
6. **Store**: Save to IndexedDB via Dexie

### Plugin System

The plugin core provides interfaces for:
- Document block rendering
- Inline element processing
- Sidebar panels
- Toolbar items
- Import/export capabilities

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details
