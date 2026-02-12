---
name: project-mapper
description: Analyzes project structure and documents 'What', 'How', and 'Why' for each file.
---

# Project Mapper Skill

This skill provides a standardized way to analyze and document software projects. It focuses on reverse-engineering the purpose of files and directories to create comprehensive documentation.

## Core Analysis Framework

For every file or component analyzed, answer these three questions:

1.  **What is it?** (Identity & Responsibility)
    *   Is it a service, a utility, a configuration, a UI component?
    *   What is its single responsibility?

2.  **How does it work?** (Mechanism & Flow)
    *   What key libraries/patterns does it use?
    *   Who calls it? Who does it call?
    *   Does it interact with DB, API, or FileSystem?

3.  **Why does it exist?** (Rationale & Value)
    *   What problem does it solve?
    *   Why was it implemented this way? (e.g., performance, security, loose coupling)

## Documentation Structure

When documenting the full project, use this hierarchy:

### 1. High-Level Architecture
*   Diagram of major components (Frontend, Backend, Agent, DB).
*   Data flow summary.

### 2. Directory Map
*   Tree structure with one-line summaries for directories.

### 3. File Inventory (The "Deep Dive")
*   Grouped by component (e.g., `backend/internal/api`).
*   Table or list format:
    *   **File**: Path/Name
    *   **What**: Brief description.
    *   **How**: Key implementation details.
    *   **Why**: Architectural justification.

## Execution Steps

1.  **Scan**: List all files to understand the footprint.
2.  **Categorize**: Group files by domain (API, UI, Core, Config).
3.  **Analyze**: Read specific files to extract the "How" and "Why".
4.  **Synthesize**: Write the `PROJECT_MAP.md` artifact.
