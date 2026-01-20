# Codebase Summary Generator

This R script builds a single Markdown file that summarizes an entire project directory.

## What it does

- Prompts for a folder path and validates it.  
- Recursively scans all files (excluding `.git` and `.Rproj.user`).  
- Detects file extensions and classifies them as:  
  - **Code/Text** (e.g., `.r`, `.py`, `.md`, `.sql`, `.js`, `.tex`)  
  - **Non-code/Data** (e.g., `.csv`, `.png`, `.rds`)  
- Lets you optionally exclude specific extensions.  
- Generates a directory tree.  
- For each file:  
  - **Code/Text** → embeds full contents in Markdown code blocks.  
  - **Non-code/Data** → inserts a placeholder with file type and size.  
- Writes everything to `codebase_summary_for_llm.md` in the target folder.

## Use case

Create a compact, LLM-ready snapshot of a codebase with full source context and minimal noise from large or binary files.
