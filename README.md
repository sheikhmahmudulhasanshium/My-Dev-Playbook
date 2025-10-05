# 📖 My-Dev-Playbook

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A personal and growing collection of practical scripts, utilities, and "developer life hacks" designed to automate repetitive tasks and streamline my workflow.

---

## 🎯 About This Playbook

In the day-to-day life of a developer, we often encounter small, repetitive tasks that consume valuable time and energy. This repository is my personal playbook for tackling those challenges—a curated set of proven, simple, and effective scripts that I frequently use to get the job done faster.

The goal is not to reinvent the wheel, but to have a reliable, go-to resource of pragmatic solutions for real-world problems.

---

## 🎮 The Plays at a Glance

-   [**Play #1: The Simple File Merger**](#️-play-1-the-simple-file-merger)
-   [**Play #2: The Secure Advanced File Merger**](#️-play-2-the-secure-advanced-file-merger)
-   [**Play #3: The AI-Powered Git Context Builder**](#️-play-3-the-ai-powered-git-context-builder)
-   [**Play #4: The File-Aware Smart Chunker**](#️-play-4-the-file-aware-smart-chunker)
-   [**Play #5: The Intelligent Project Mapper**](#️-play-5-the-intelligent-project-mapper)
-   [**Play #6: The Phoenix Setup**](#️-play-6-the-phoenix-setup-role-based--hardware-aware)
-   [**Play #7: The .env Key Architect**](#️-play-7-the-env-key-architect)
-   [**Play #8: The AI Prompt Architect**](#️-play-8-the-ai-prompt-architect)
-   [**Play #9: Git Guardian**](#️-play-9-git-guardian)

---

## 🤖 The Plays in Detail

### ▶️ Play #1: The Simple File Merger

A lightweight yet powerful script to find all files of a specific type (e.g., `.ts`, `.js`) within a directory and its subdirectories, and combine them into a single output file.

<details>
<summary>💡 <b>When would I use this?</b></summary>
<br>
<ul>
<li>Pasting an entire React component folder (<code>.tsx</code>, <code>.css</code>, <code>.test.ts</code>) into an AI chat for refactoring.</li>
<li>Combining all SQL migration scripts into a single file for a sequential review with a colleague.</li>
<li>Merging multiple <code>.css</code> files into one for a simple project without setting up a complex build tool.</li>
</ul>
</details>

#### ✨ Key Features:
-   **🔄 Recursive Search:** Automatically finds files in all subfolders.
-   **📝 Traceable Output:** Prepends each file's content with a comment containing its original relative path.
-   **📂 Preserves Content:** Faithfully copies all content, including comments and formatting.
-   **🔌 Dependency-Free:** Runs natively on Windows using PowerShell or a standard Batch file.

#### 📁 Files:
-   **PowerShell Version:** [`merge_files.ps1`](./plays/01-file-merger/merge_files.ps1)
-   **Batch File Version:** [`merge_files.bat`](./plays/01-file-merger/merge_files.bat)

#### 🚀 How to Use This Play:
-   Double-click `merge_files.bat` or run `.\merge_files.ps1` from a PowerShell terminal.

---

### ▶️ Play #2: The Secure Advanced File Merger

An intelligent script that can be run from any directory. It asks for your project folder path, analyzes its structure, and guides you through a secure merge process. The perfect tool for creating a safe "context dump" for AI models or code reviews.

<details>
<summary>💡 <b>When would I use this?</b></summary>
<br>
<ul>
<li>Creating a comprehensive "context dump" of an entire codebase for an AI to analyze, while automatically stripping out API keys from <code>.env</code> files.</li>
<li>Archiving a project and wanting a single, searchable text file of the source code, ignoring build artifacts and <code>node_modules</code>.</li>
<li>Providing a new developer with a single-file overview of a project's source code for them to study, without sending a large <code>.zip</code> file.</li>
</ul>
</details>

#### ✨ Key Features:
-   **📍 Run From Anywhere:** No need to `cd` into your project directory. The script asks for the target folder path.
-   **🔒 Sanitizes `.env` Files:** Automatically detects and sanitizes secrets in `.env` files to prevent leaks.
-   **🤖 Robust Filtering:** Interactively suggests ignores and can automatically apply rules from your `.gitignore`.
-   **✨ Enhanced UI:** Provides a visual spinner and progress bar for a professional user experience.

#### 📁 File:
-   **PowerShell Version:** [`merge_files_advanced.ps1`](./plays/02-file-merger-advanced/merge_files_advanced.ps1)

#### 📝 A Note on Tooling:
> **Why is there no `.bat` version for this play?**
>
> The advanced features of this script—such as its interactive UI, robust filtering, and file sanitization—rely heavily on capabilities native to PowerShell. Creating an equivalent in a traditional Batch file would be extremely complex and unreliable. This is a great example of choosing the right tool for the job.

#### 🚀 How to Use This Play:
-   Run `.\merge_files_advanced.ps1` from a PowerShell terminal.

---

### ▶️ Play #3: The AI-Powered Git Context Builder

Acts as the perfect assistant for your AI, packaging all your uncommitted work into a comprehensive prompt file. Paste the result into any AI chat to get a high-quality, human-readable summary of your work.

<details>
<summary>💡 <b>When would I use this?</b></summary>
<br>
<ul>
<li>Generating a high-quality commit message or pull request summary by feeding all your uncommitted changes to an AI.</li>
<li>Getting a "second opinion" on your code changes before committing them, asking an AI for potential bugs or improvements.</li>
<li>Summarizing your work-in-progress for a daily stand-up meeting or for a team member who is taking over the task.</li>
</ul>
</details>

#### ✨ Key Features:
-   **🗣️ Human-in-the-Loop:** Asks for your high-level goal to provide crucial "intent" context to the AI.
-   **🏗️ Full Project Context:** Includes the project's directory structure and detailed `git diff` of all changes.
-   **🤖 Expert Prompt Engineering:** The output is a perfectly structured prompt that tells the AI to act like a senior developer.
-   **🔒 Preserves Code Integrity:** Includes a critical instruction for the AI *not* to change relative path imports.
-   **🚫 No API Keys Needed:** Creates a local text file, allowing you to use any free, web-based AI chat.

#### 📁 File:
-   **PowerShell Version:** [`git_context_builder.ps1`](./plays/03-ai-git-context-builder/git_context_builder.ps1)

#### 🚀 How to Use This Play:
-   Run `.\git_context_builder.ps1` from a PowerShell terminal **inside your Git repository**.

---

### ▶️ Play #4: The File-Aware Smart Chunker

Solves the biggest problem when working with AI: context window limits. This intelligent script takes a large merged file and splits it into smaller parts **without ever breaking a single source file in half**.

<details>
<summary>💡 <b>When would I use this?</b></summary>
<br>
<ul>
<li>Submitting a large codebase (e.g., 200KB of merged code) to an AI with a limited context window (like standard ChatGPT) without manually splitting files.</li>
<li>Ensuring the AI receives complete, unbroken files in each chunk, preventing syntax errors or incomplete logic caused by naive splitting.</li>
</ul>
</details>

#### ✨ Key Features:
-   **🔍 Smart Input Suggestions:** Can't remember the exact filename? Just type part of it, and the script will find it.
-   **📦 File-Aware Chunking:** Guarantees that no single file is ever split across multiple chunks, preserving code integrity.
-   **🧠 Smart Presets:** Choose an AI type (Standard or Advanced), and the script intelligently sizes the chunks.
-   **⚠️ Oversized File Warnings:** If a single file is larger than the chunk size, it will be isolated and you'll be warned.
-   **🤖 AI State Management:** Includes carefully engineered prompts in each part to prevent the AI from giving a premature summary.

#### 📁 File:
-   **PowerShell Version:** [`file_chunker.ps1`](./plays/04-ai-context-chunker/file_chunker.ps1)

#### 🚀 How to Use This Play:
1.  First, use **Play #1** or **Play #2** to create a merged file (e.g., `merged.txt`).
2.  Run `.\file_chunker.ps1` from a PowerShell terminal.
3.  When prompted, enter the name of your merged file.
4.  Choose the AI preset that matches your model.
5.  The script will create an `output_chunks` folder with numbered files, ready for your AI chat.

---

### ▶️ Play #5: The Intelligent Project Mapper

A powerful utility that goes beyond a simple `tree` command to generate insightful, visually appealing, and documentation-ready maps of any project's architecture.

<details>
<summary>💡 <b>When would I use this?</b></summary>
<br>
<ul>
<li>Quickly understanding the architecture of a new repository you've just cloned, without manually exploring every folder.</li>
<li>Generating a clean, high-level directory map for your project's <code>README.md</code> or technical documentation.</li>
<li>Planning a refactor by visualizing the project structure and identifying key areas like services, controllers, and modules.</li>
</ul>
</details>

#### ✨ Key Features:
-   **🧠 Intelligent Summaries:** Can automatically detect and summarize folder contents (e.g., `auth/ (2 services, 1 module)`).
-   **⚙️ Granular Filtering:** Choose from multiple intensity levels, filter by file extension, and limit map depth.
-   **🌐 Framework Aware:** Intelligently ignores heavy directories like `node_modules`, `.next`, and `.git` by default.
-   **📝 Self-Documenting Output:** Every saved map automatically includes an execution log of all user choices.
-   **💾 Safe & Universal:** Can be run from any directory. It asks for your project path and uses UTF-8 to ensure all characters render perfectly.

#### 📁 File:
-   **PowerShell Version:** [`project_mapper.ps1`](./plays/05-intelligent-project-mapper/project_mapper.ps1)

#### 🚀 How to Use This Play:
-   Run `.\project_mapper.ps1` from a PowerShell terminal.

---

### ▶️ Play #6: The Phoenix Setup (Role-Based & Hardware-Aware)

Starting fresh on a new PC can be a drag. This script is your personal phoenix, raising your development environment from the ashes with role-based profiles and hardware-aware suggestions.

<details>
<summary>💡 <b>When would I use this?</b></summary>
<br>
<ul>
<li>Setting up a new development machine from scratch and wanting to install all your essential tools (Git, Node, VS Code, Docker) in one go.</li>
<li>Helping a new team member get their machine provisioned quickly with a standard "Full-Stack" or "Frontend" profile.</li>
<li>Quickly restoring your development environment after reinstalling Windows.</li>
</ul>
</details>

#### ✨ Key Features:
-   **🚀 Role-Based Profiles:** Choose a profile like **Frontend** or **Backend** to get a curated toolset for your job.
-   **💡 Hardware-Aware:** Automatically detects your system's RAM and provides warnings before installing heavy apps like Docker.
-   **✔️ Categorized & Optional Tools:** Menus are grouped logically, making it easy to install just what you need.
-   **🔒 Effortless Admin Elevation:** The `.bat` launcher automatically requests administrator privileges.
-   **📝 Failsafe Logging:** Creates a detailed `setup-log.txt` in your Documents folder if any installation fails.

#### 📁 Files:
-   **Launcher:** [`run_setup.bat`](./plays/06-new-machine-initializer/run_setup.bat) *(Use this to start)*
-   **PowerShell Script:** [`phoenix_setup.ps1`](./plays/06-new-machine-initializer/phoenix_setup.ps1)

#### 🚀 How to Use This Play:
1.  Place both `run_setup.bat` and `phoenix_setup.ps1` in the same folder.
2.  **Double-click `run_setup.bat`**.
3.  When the UAC prompt appears, click **"Yes"** to grant administrator permissions.
4.  The PowerShell script will then open and guide you through the setup menu.

---

### ▶️ Play #7: The .env Key Architect

Tired of thinking up secure, random passwords for your `.env` files? This play is your dedicated cryptographer, designed to quickly generate multiple, high-entropy secrets, perfectly formatted for your project's configuration.

<details>
<summary>💡 <b>When would I use this?</b></summary>
<br>
<ul>
<li>Scaffolding a new project and needing to generate multiple secure keys for <code>DATABASE_URL</code>, <code>JWT_SECRET</code>, and <code>API_KEY</code>.</li>
<li>Quickly creating a single, cryptographically strong 48-character secret to replace a compromised key.</li>
<li>Avoiding the use of weak, easy-to-guess passwords in your local development configuration files.</li>
</ul>
</details>

#### ✨ Key Features:
-   **🔐 Complexity Presets:** Choose from **Easy**, **Strong**, or **Insane** for one-click security.
-   **✍️ Fully Customizable:** Define the exact length and character types you need.
-   **📦 Batch Generation:** Generate as many secrets as you need in a single session.
-   **📝 `.env` Ready:** Automatically formats each secret as a `VARIABLE_NAME=key...` pair.
-   **💾 Safe Append:** Safely **appends** your new keys to a file, never overwriting existing secrets.

#### 📁 File:
-   **PowerShell Version:** [`env_key_architect.ps1`](./plays/07-env-key-architect/env_key_architect.ps1)

#### 🚀 How to Use This Play:
-   Run `.\env_key_architect.ps1` from a PowerShell terminal and follow the on-screen prompts.

---

### ▶️ Play #8: The AI Prompt Architect

Stop getting generic answers from your AI. This script acts as your personal prompt engineering expert, guiding you through targeted questions to build a master prompt for any new project or debugging task.

<details>
<summary>💡 <b>When would I use this?</b></summary>
<br>
<ul>
<li>Planning a new application from scratch and wanting the AI to act as a solution architect, providing a full plan, tech stack advice, and security recommendations.</li>
<li>Debugging a complex issue and needing to provide the AI with perfectly structured context (code, logs, dependencies) to get a useful, non-generic answer.</li>
<li>Requesting a complete project package from an AI, including not just code, but also an SRS document, branding ideas, and a cost analysis report.</li>
</ul>
</details>

#### ✨ Key Features:
-   **🤖 Solution Architect Mode:** Asks deep architectural questions about security, authentication, and project deliverables.
-   **🌐 Terminal-Aware:** Asks for your terminal (PowerShell, CMD, Bash) so the AI provides commands that will actually run.
-   **🚀 New Project Scaffolding:** For new projects, it asks about tech stack, goals, and even suggests free-tier services.
-   **🔍 Existing Project Debugging:** For existing work, it prompts you for crucial context like package lists and error messages.
-   **✅ Guidelines & Constraints:** Define what the AI should and should not do to give it precise guardrails.
-   **🎓 Expert-Engineered Output:** The final prompt is perfectly structured for superior results from any LLM.

#### 📁 Files:
-   **PowerShell Version:** [`ai_prompt_architect.ps1`](./plays/08-ai-prompt-architect/ai_prompt_architect.ps1)
-   **Batch File Version:** [`ai_prompt_architect.bat`](./plays/08-ai-prompt-architect/ai_prompt_architect.bat)

#### 🚀 How to Use This Play:
-   Double-click `ai_prompt_architect.bat` for an easy start, or run `.\ai_prompt_architect.ps1` from PowerShell.

---

### ▶️ Play #9: Git Guardian

Your interactive command-line partner for simplifying complex Git workflows, from initializing a new project to debugging errors with AI assistance.

<details>
<summary>💡 <b>When would I use this?</b></summary>
<br>
<ul>
<li>Setting up Git and GitHub authentication for the first time on a new machine.</li>
<li>Creating a new local project and pushing it to a new GitHub repository in one seamless operation.</li>
<li>Performing daily Git tasks like pulling, branching, and pushing changes without having to remember all the specific commands.</li>
<li>Quickly getting help with a confusing Git error by generating a perfectly formatted prompt for an AI.</li>
<li>Safely resetting a local repository to a clean state after a major mistake, without accidentally deleting the wrong folder.</li>
</ul>
</details>

#### ✨ Key Features:
-   ** interactivo Menu-Driven UI:** Guides you through common Git tasks with a simple numerical menu, eliminating the need to memorize commands.
-   **Automated Setup & Auth:** Checks and configures your Git identity and GitHub CLI authentication, perfect for first-time setup.
-   **End-to-End Workflows:** Covers the entire repository lifecycle, from initialization and cloning to daily management and even "nuking" a local repo safely.
-   **Built-in 'Git Doctor':** Generates a comprehensive, context-aware prompt to help you debug Git errors using any AI chat model.
-   **Safety First:** Includes multiple confirmation steps for destructive actions like the 'Nuke' feature to prevent mistakes.
-   **Dual-Version Support:** Provides both a simple Batch file for easy launching and a more powerful PowerShell version for an enhanced experience.

#### 📁 Files:
-   **PowerShell Version:** [`git_guardian.ps1`](./plays/09-git-guardian/git_guardian.ps1)
-   **Batch File Version:** [`git_guardian.bat`](./plays/09-git-guardian/git_guardian.bat)

#### 🚀 How to Use This Play:
-   Use the combined script file that works for your preferred terminal (Batch or PowerShell). Run it from inside the project directory you want to manage.

---

## ⚙️ How to Use The Plays

Each play is designed to be as straightforward as possible.

1.  Navigate to the directory of the play you want to use (e.g., `.../plays/08-ai-prompt-architect/`).
2.  **Look for a `.bat` file first.** If one exists, **double-click it**. This is always the easiest way to start.
3.  **If there is no `.bat` file**, open a PowerShell terminal in that folder and run the `.ps1` script by typing its name (e.g., `.\project_mapper.ps1`).
4.  Follow the on-screen prompts.

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