library(tidyverse)
library(fs)
library(stringr)

# --- CONFIGURATION ---
# Comprehensive list of code and text extensions for full content inclusion
CODE_EXTENSIONS <- c(
  "r", "rmd", "qmd", "rnw", "py", "sh", "sql", "js", "html", "css",
  "cpp", "h", "hpp", "c", "java", "tex", "bib", "md", "txt", "yaml",
  "yml", "toml", "json", "stan", "jl", "rproj"
)

# --- FUNCTIONS ---
get_clean_path <- function() {
  cat("Please paste the folder path: ")
  raw_path <- readline()
  
  # Normalize slashes and remove "Copy as path" artifacts
  clean_path <- raw_path %>%
    str_replace_all("\\\\", "/") %>%
    str_replace_all('"', "") %>% 
    str_trim()
  
  if (!dir_exists(clean_path)) {
    stop("Error: The directory does not exist. Check the path and try again.")
  }
  
  return(path_real(clean_path))
}

generate_tree <- function(root_path, ignore_list = NULL) {
  # Recursively list all files and folders relative to root
  files <- dir_ls(root_path, recurse = TRUE)
  
  # Filter out ignored extensions if provided
  if (!is.null(ignore_list)) {
    files <- files[!str_to_lower(path_ext(files)) %in% ignore_list]
  }
  
  rel_paths <- path_rel(files, start = root_path)
  return(paste(rel_paths, collapse = "\n"))
}

# --- MAIN EXECUTION ---
main <- function() {
  target_dir <- get_clean_path()
  output_file <- path(target_dir, "codebase_summary_for_llm.md")
  
  # Identify all files early to analyze extensions
  initial_files <- dir_ls(target_dir, recurse = TRUE, type = "file") %>%
    keep(~ !str_detect(.x, "/\\.git/|/\\.Rproj\\.user/"))
  
  detected_exts <- initial_files %>% 
    path_ext() %>% 
    str_to_lower() %>% 
    unique() %>% 
    keep(~ .x != "")
  
  # Categorize detected extensions
  is_code <- detected_exts %in% CODE_EXTENSIONS
  code_types <- detected_exts[is_code]
  non_code_types <- detected_exts[!is_code]
  
  # Prompt user for exclusions with professional categorization
  cat("\nAnalysis complete. I have categorized the files in this directory:\n")
  cat("---------------------------------------------------------------\n")
  cat("Code/Text Files (Content will be included):\n ", 
      if(length(code_types) > 0) paste(code_types, collapse = ", ") else "None", "\n\n")
  cat("Non-Code/Data Files (Metadata only will be included):\n ", 
      if(length(non_code_types) > 0) paste(non_code_types, collapse = ", ") else "None", "\n")
  cat("---------------------------------------------------------------\n")
  
  cat("\nWould you like to exclude any of these extensions from the summary?\n")
  cat("Enter extensions to ignore, separated by commas (e.g., 'csv, txt'), or press Enter to proceed:\n")
  
  exclude_input <- readline()
  ignore_list <- if (nchar(exclude_input) > 0) {
    str_split(exclude_input, ",")[[1]] %>% str_trim() %>% str_to_lower()
  } else {
    NULL
  }
  
  cat("\nProcessing directory:", target_dir, "\n")
  
  # 1. Prepare introductory context for the LLM
  intro_text <- paste0(
    "# Codebase Summary\n\n",
    "This file is a consolidated summary of the codebase at: `", target_dir, "`.\n",
    "It is structured for LLM ingestion to provide full context in one prompt.\n\n",
    "## Included Sections\n",
    "1. Directory tree structure.\n",
    "2. Source code for scripts/text files.\n",
    "3. Placeholders for binary/data files to optimize token usage.\n\n",
    "## Directory Structure\n\n```\n", 
    generate_tree(target_dir, ignore_list), 
    "\n```\n\n---\n"
  )
  
  # 2. Filter files based on user input
  all_files <- as.character(initial_files) %>%
    setdiff(as.character(output_file))
  
  if (!is.null(ignore_list)) {
    all_files <- all_files[!str_to_lower(path_ext(all_files)) %in% ignore_list]
  }
  
  # 3. Process each file based on its extension
  file_contents <- map_chr(all_files, function(f) {
    rel_f <- path_rel(f, start = target_dir)
    ext <- str_to_lower(path_ext(f))
    
    cat("Adding:", rel_f, "\n")
    header <- paste0("\n## FILE: ", rel_f, "\n")
    
    if (ext %in% CODE_EXTENSIONS) {
      content <- tryCatch(
        read_file(f),
        error = function(e) paste("[Error reading file content]")
      )
      return(paste0(header, "```", ext, "\n", content, "\n```\n"))
    } else {
      info <- file_info(f)
      return(paste0(header, "*[Non-code/Data file: ", ext, " | Size: ", format(info$size), "]*\n"))
    }
  })
  
  # 4. Save consolidated file
  final_output <- paste0(intro_text, paste(file_contents, collapse = "\n"))
  write_file(final_output, output_file)
  
  cat("\nSuccess! Summary generated at:", output_file, "\n")
}

# Execute script
main()