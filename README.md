# Artificial-Export

Artificial-Export is a tiny, zero-dependency Bash tool that exports a code project into:

- A **tree view** of the folder structure.
- A **single Markdown file** containing the contents of relevant source files.

The output is designed to be easy to copy-paste into any other LLM so it can “see” your whole project without you manually stitching files together.

---

## Features

- ✅ Single Bash script, no external dependencies beyond standard Unix tools.
- ✅ Works on macOS and Linux (and anywhere with Bash + `find` + `wc`).
- ✅ Generates:
  - `project-tree.txt` – simple tree-like view of your project.
  - `project-export.md` – Markdown file with code and config in fenced blocks.
- ✅ Ignores noisy directories:
  - `.git`, `.idea`, `.vscode`, `target`, `build`, `out`, `node_modules`, `dist`
- ✅ Includes only “interesting” file types by default:
  - `*.java`, `*.kt`, `*.xml`, `*.yml`, `*.yaml`, `*.properties`
  - `*.md`, `*.txt`, `*.html`, `*.js`, `*.ts`, `*.json`
- ✅ Skips very large files (default: larger than **200 KB**).

Perfect for:

- Sharing a project with an LLM for **refactoring** or **architecture review**.
- Getting help debugging without copy-pasting files one by one.
- Quickly producing a “project snapshot” in Markdown.

---

## Requirements

- A Unix-like environment (macOS, Linux, WSL, etc.).
- `bash`
- Standard utilities:
  - `find`
  - `wc`
  - `cat`

No additional packages or languages are required.

---

## Installation

Copy & Paste:

```bash
nano project-export.sh
### Copy & Paste the script, save and exist
```
or

Clonee the repository:

~~~bash
git clone https://github.com/<your-user>/Artificial-Export.git
cd Artificial-Export
~~~

Make the script executable:

~~~bash
chmod +x artificial-export.sh
~~~

(If you named the script differently, adjust the filename accordingly.)

Optionally, add it somewhere in your `PATH`:

~~~bash
# Example: add to /usr/local/bin
sudo cp artificial-export.sh /usr/local/bin/artificial-export
sudo chmod +x /usr/local/bin/artificial-export
~~~

Now you can run it as:

~~~bash
artificial-export /path/to/your/project
~~~

---

## Usage

From the root of the project you want to export:

~~~bash
# From inside the project
./artificial-export.sh .

# Or from anywhere, pointing to the project root
./artificial-export.sh /absolute/path/to/project
~~~

The script will:

- Normalize the root path.
- Walk the project tree, ignoring noisy folders.
- Generate two files in the **project root**:

~~~text
project-tree.txt
project-export.md
~~~

### Example output files

#### `project-tree.txt`

A minimal, indented tree-like representation:

~~~text
[.]
  [src]
    [main]
      [java]
        [com]
          [example]
            [app]
              - Application.java
              - DiscordBotService.java
      [resources]
        - application.yml
  [test]
    [java]
      [com]
        [example]
          [app]
            - ApplicationTest.java
  - pom.xml
  - README.md
~~~

#### `project-export.md`

A Markdown file with all relevant files in fenced blocks:

~~~markdown
# Project export

## FILE: pom.xml
<xml content here>

## FILE: src/main/java/com/example/app/Application.java
<java content here>

## FILE: src/main/resources/application.yml
<yaml content here>
~~~

You can then copy-paste `project-tree.txt` and `project-export.md` (or parts of them) into ChatGPT or another LLM to provide full-project context.

---

## How it works

At a high level, Artificial-Export:

1. **Scans the project root** with `find`, pruning common noisy directories:
   - `.git`, `.idea`, `.vscode`, `target`, `build`, `out`, `node_modules`, `dist`
2. **Builds a simple tree** (`project-tree.txt`) by:
   - Printing directories as `[folder-name]`
   - Printing files as `- filename`
   - Indenting based on path depth
3. **Filters files** for `project-export.md`:
   - Only allowed extensions:
     - `java`, `kt`, `xml`, `yml`, `yaml`, `properties`, `md`, `txt`, `html`, `js`, `ts`, `json`
   - Skips files larger than `200 KB` by default.
4. **Guesses the language tag** for Markdown code fences from the file extension:
   - `java` → ` ```java ` (in the generated file)
   - `xml` → ` ```xml `
   - `yml` / `yaml` → ` ```yaml `
   - `js` → ` ```javascript `
   - `ts` → ` ```typescript `
   - `json` → ` ```json `
   - others → no explicit language (plain ` ``` `).

---

## Configuration

This first version is intentionally simple.  
If you want to tweak behavior, you can edit `artificial-export.sh` directly:

### Max file size

Controls which files are skipped because they are too large:

~~~bash
MAX_FILE_SIZE=$((200 * 1024)) # 200 KB
~~~

### Allowed extensions

Defines which files are exported into `project-export.md`:

~~~bash
ALLOWED_EXTS="java kt py xml yml yaml properties md txt html js ts json"
~~~

### Ignored directories

Configured in the `IGNORE_FIND_EXPR` variable:

~~~bash
IGNORE_FIND_EXPR='( -name .git -o -name .idea -o -name .vscode -o -name target -o -name build -o -name out -o -name node_modules -o -name dist )'
~~~

You can add or remove directory names there as needed.

---

## Working with other languages / extensions

Artificial-Export is designed to be easy to customize for **any language or file type**.

There are **two simple steps** to support a new extension:

1. **Add the extension to `ALLOWED_EXTS`**  
2. **Teach `guess_lang` how to map that extension to a Markdown language tag** (optional, but recommended for syntax highlighting).

### 1. Adding a new extension

Open `artificial-export.sh` and locate this line:

~~~bash
ALLOWED_EXTS="java kt py xml yml yaml properties md txt html js ts json"
~~~

If you want to support, for example, **C#** and **Rust**, you can change it to:

~~~bash
ALLOWED_EXTS="java kt py xml yml yaml properties md txt html js ts json cs rs"
~~~

Now files like `Something.cs` and `main.rs` will be picked up and included in `project-export.md`.

> Note: if you only add the extension here, the files will still be exported, but the code block in Markdown will not have a specific language tag (so it will be plain code fence).

### 2. Mapping the extension to a code block language

To get nice syntax highlighting in Markdown, edit the `guess_lang` function.  
Find this block:

~~~bash
guess_lang() {
  # Guess code block language for Markdown fenced code blocks based on extension
  local ext="$1"
  case "$ext" in
    java) echo "java" ;;
    kt) echo "kotlin" ;;
    xml) echo "xml" ;;
    yml|yaml) echo "yaml" ;;
    properties) echo "" ;;
    md|txt) echo "" ;;
    html) echo "html" ;;
    js) echo "javascript" ;;
    ts) echo "typescript" ;;
    json) echo "json" ;;
    py) echo "python" ;;
    *) echo "" ;;
  esac
}
~~~

You can extend it with your own mappings.  
For example, to support **C#** and **Rust**:

~~~bash
guess_lang() {
  # Guess code block language for Markdown fenced code blocks based on extension
  local ext="$1"
  case "$ext" in
    java) echo "java" ;;
    kt) echo "kotlin" ;;
    xml) echo "xml" ;;
    yml|yaml) echo "yaml" ;;
    properties) echo "" ;;
    md|txt) echo "" ;;
    html) echo "html" ;;
    js) echo "javascript" ;;
    ts) echo "typescript" ;;
    json) echo "json" ;;
    py) echo "python" ;;
    cs) echo "csharp" ;;   # C#
    rs) echo "rust" ;;     # Rust
    *) echo "" ;;
  esac
}
~~~

This pattern works for any language (PHP, Go, Ruby, etc.)—just add the extension to ALLOWED_EXTS and a small case to guess_lang.

---
## Limitations

This is intentionally a **minimal** tool:

- No chunking by size (for now):
  - `project-export.md` can be large for very big repositories.
  - If needed, you can manually split it or add chunking logic later.
- Filters and size limit are hard-coded:
  - You can tweak them directly inside `artificial-export.sh`.
- Only file-based context:
  - It does not run code, parse ASTs, or understand frameworks.
  - It just exports structure + contents in a clean format.

---

## Contributing

Feel free to:

- Open issues for bugs or feature ideas.
- Submit pull requests to improve the script, filters, or documentation.

---
