# 📖 My-Dev-Playbook

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A personal and growing collection of practical scripts, utilities, and "developer life hacks" designed to automate repetitive tasks and streamline my workflow.

---

## 🎯 About This Playbook

In the day-to-day life of a developer, we often encounter small, repetitive tasks that consume valuable time and energy. This repository is my personal playbook for tackling those challenges—a curated set of proven, simple, and effective scripts that I frequently use to get the job done faster.

The goal is not to reinvent the wheel, but to have a reliable, go-to resource of pragmatic solutions for real-world problems.

---

## 🎮 The Plays

Here are the currently available "plays" in the playbook. Each one is designed to solve a specific problem.

### ▶️ Play #1: The Simple File Merger

A lightweight yet powerful script to find all files of a specific type (e.g., `.ts`, `.js`, `.css`) within a directory and its subdirectories, and combine them into a single output file.

#### ✨ Key Features:
-   **🔄 Recursive Search:** Automatically finds files in all subfolders.
-   **📝 Traceable Output:** Prepends each file's content with a comment containing its original relative path.
-   **📂 Preserves Content:** Faithfully copies all content, including comments (`//`, `/**/`) and formatting.
-   **🔌 Dependency-Free:** Runs natively on Windows using PowerShell or a standard Batch file.

#### 📁 Files:
-   **PowerShell Version:** [`merge_files.ps1`](./plays/01-file-merger/merge_files.ps1)
-   **Batch File Version:** [`merge_files.bat`](./plays/01-file-merger/merge_files.bat)

---

### ▶️ Play #2: The Advanced File Merger

An intelligent, interactive script that analyzes a project directory and guides you through merging only the files you need. It's perfect for creating a comprehensive "context dump" for AI models, project archiving, or code reviews.

#### ✨ Key Features:
-   **📊 Project Analysis:** Starts with a summary of file types and the heaviest folders.
-   **🤖 Smart Filtering:** Interactively suggests ignoring common folders like `node_modules` and automatically respects rules from your `.gitignore` file.
-   **🎯 User-Controlled Selection:** You have the final say on which file extensions to include.
-   **📄 Formatted Markdown Output:** Creates a clean, human-readable `.md` file that can easily be converted to PDF or DOCX.

#### 📁 File:
-   **PowerShell Version:** [`merge_files_advanced.ps1`](./plays/02-file-merger-advanced/merge_files_advanced.ps1)

#### 📝 A Note on Tooling:
> **Why is there no `.bat` version for this play?**
>
> The advanced features of this script—such as interactive prompts, file system analysis, and parsing `.gitignore` files—rely heavily on capabilities that are native to PowerShell. Creating an equivalent in a traditional Batch file would be extremely complex, slow, and unreliable. This is a great example of choosing the right tool for the job, and for this task, PowerShell is the clear and superior choice.

---

### ▶️ Play #3: The AI-Powered Git Context Builder

Ever come back to a project and forget the "why" behind your changes? This script acts as the perfect assistant for your AI, packaging all your uncommitted work into a comprehensive prompt file. You can then paste this into any AI chat to get a high-quality, human-readable summary of your work.

#### ✨ Key Features:
-   **🗣️ Human-in-the-Loop:** It asks for your high-level goal to provide crucial "intent" context to the AI.
-   **🏗️ Full Project Context:** It includes the project's directory structure and the detailed line-by-line code changes (`git diff`).
-   **🤖 Expert Prompt Engineering:** The output file is a perfectly structured prompt that tells the AI to act like a senior developer and answer the key questions: the "what," "why," and "how."
-   **🔒 Preserves Code Integrity:** Includes a critical instruction for the AI *not* to change relative path imports, ensuring its suggestions don't break the project structure.
-   **🚫 No API Keys Needed:** It creates a local text file, allowing you to use any free, web-based AI chat without needing to sign up for APIs or manage keys.

#### 📁 File:
-   **PowerShell Version:** [`git_context_builder.ps1`](./plays/03-ai-git-context-builder/git_context_builder.ps1)

---

### ▶️ Play #4: The File-Aware Smart Chunker

Solves the biggest problem when working with AI: context window limits. This intelligent script takes a large merged file and splits it into smaller parts **without ever breaking a single source file in half**. It preserves code integrity by packing whole files into chunks, ensuring the AI receives clean, complete context.

#### ✨ Key Features:
-   **🔍 Smart Input Suggestions:** Can't remember the exact filename? Just type part of it. The script will find the most likely match and ask you to confirm, just like a search engine.
-   **📦 File-Aware Chunking:** The script's primary feature. It understands the file boundaries within your merged document and guarantees that no single file is ever split across multiple chunks.
-   **🧠 Smart Presets:** You don't need to know about "tokens." Just choose the type of AI you're using (Standard or Advanced), and the script intelligently packs files into appropriately sized chunks.
-   **⚠️ Oversized File Warnings:** If a single file is larger than the recommended chunk size, the script will isolate it and warn you, so you're always in control.
-   **🤖 AI State Management:** Includes carefully engineered prompts in each part to prevent the AI from giving a premature summary.

#### 📁 File:
-   **PowerShell Version:** [`file_chunker.ps1`](./plays/04-ai-context-chunker/file_chunker.ps1)

#### 🚀 How to Use This Play:
1.  First, use **Play #1** or **Play #2** to create a merged file (e.g., `merged.txt`).
2.  Run the `file_chunker.ps1` script.
3.  When prompted, enter the full or partial name of your merged file.
4.  Choose the AI preset that matches your model.
5.  The script will create an `output_chunks` folder with numbered files, ready for you to copy and paste into your AI chat.

---

## ⚙️ How to Use The Plays

Each script is designed to be run from the root of the project you are working on.

### Option A: PowerShell (Recommended for all plays)
1.  Copy the desired `.ps1` script from this playbook into the root directory of your target project.
2.  In your project's folder, hold down `Shift` + `Right-Click` on an empty space and select **"Open PowerShell window here"**.
3.  Execute the script by typing its name (e.g., `.\file_chunker.ps1`) and pressing **Enter**.
4.  Follow any on-screen instructions.

### Option B: Windows Batch File (For simple plays like Play #1)
1.  Copy the desired `.bat` file (e.g., `merge_files.bat`) into the root directory of your target project.
2.  Double-click the `.bat` file to execute it.

---

## 🚀 Future Vision

This playbook is a living project. I plan to continuously add new scripts and utilities as I develop solutions for new challenges. The long-term vision is to potentially evolve some of these utilities into a user-friendly web-based application.

## 🤝 Contributing

While this is a personal collection, suggestions and contributions are welcome! If you have an idea for a new "play" or an improvement to an existing one, feel free to open an issue or submit a pull request.

1.  **Fork** the Project
2.  **Create** your Feature Branch (`git checkout -b feature/AmazingPlay`)
3.  **Commit** your Changes (`git commit -m 'Add some AmazingPlay'`)
4.  **Push** to the Branch (`git push origin feature/AmazingPlay`)
5.  **Open** a Pull Request

## 📜 License

Distributed under the MIT License. See `LICENSE` file for more information.

## ✉️ Contact

**Sheikh Mahmudul Hasan Shium**

[![GitHub Badge](https://img.shields.io/badge/-GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sheikhmahmudulhasanshium/)