# markitdown dockerized

Dockerized CLI wrapper for Microsoft [MarkItDown](https://github.com/microsoft/markitdown) — a
lightweight Python utility for converting files and office documents to Markdown.

## Table of contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [LLM / OCR configuration](#llm--ocr-configuration)
- [Usage](#usage)
- [Command reference](#command-reference)
- [Supported formats](#supported-formats)
- [Installed dependencies](#installed-dependencies)
- [Notes](#notes)
- [Claude Code skill](#claude-code-skill)
- [Credits](#credits)

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (Engine or Desktop)
- No Python or other tools required on the host

---

## Setup

### 1. Clone this repository

```bash
git clone <this-repo-url>
cd markitdown
```

### 2. Configure LLM credentials (optional)

Open `docker-compose.yml` and fill in the `environment` section if you want LLM-powered OCR for
embedded images in PDF, DOCX, PPTX, and XLSX files. See [LLM / OCR configuration](#llm--ocr-configuration)
for details. Skip this step if you don't need OCR.

### 3. Build the image

```bash
make install
```

To build from a specific upstream tag or branch instead of `main`:

```bash
docker compose build --build-arg MARKITDOWN_REF=v0.1.5
```

### 4. Verify the installation

```bash
./markitdown.sh --help
```

---

## LLM / OCR configuration

The [markitdown-ocr](https://github.com/microsoft/markitdown/blob/main/packages/markitdown-ocr/README.md)
plugin is always loaded. It activates LLM Vision OCR — extracting text from embedded images and
scanned pages — only when an LLM client is configured. Without configuration, it silently falls back
to the standard built-in converter.

Configure the LLM by editing the `environment` block in `docker-compose.yml`:

| Variable | Required for OCR | Description |
|---|---|---|
| `OPENAI_API_KEY` | Yes | API key for the LLM provider |
| `LLM_MODEL` | Yes | Model name passed to `--llm-model` |
| `OPENAI_BASE_URL` | Only for non-OpenAI providers | Base URL of the OpenAI-compatible endpoint |

When both `OPENAI_API_KEY` and `LLM_MODEL` are non-empty, `--llm-client openai --llm-model $LLM_MODEL`
are automatically prepended to every invocation. To disable OCR, leave either variable empty.

### Using Claude (Anthropic)

```yaml
environment:
  OPENAI_API_KEY: "sk-ant-..."
  OPENAI_BASE_URL: "https://api.anthropic.com/v1"
  LLM_MODEL: "claude-opus-4-6"
```

### Using OpenAI

```yaml
environment:
  OPENAI_API_KEY: "sk-..."
  LLM_MODEL: "gpt-4o"
```

### Using another OpenAI-compatible provider

```yaml
environment:
  OPENAI_API_KEY: "..."
  OPENAI_BASE_URL: "https://your-provider/v1"
  LLM_MODEL: "model-name"
```

---

## Usage

All examples below use `./markitdown.sh`. The script is a thin wrapper around
`docker compose run --rm markitdown` and forwards all arguments unchanged.

### Show help

```bash
./markitdown.sh --help
```

### Convert a file — output to stdout

```bash
./markitdown.sh /data/input.pdf
```

Redirect to a local file:

```bash
./markitdown.sh /data/input.pdf > output.md
```

### Convert a file — write output file

```bash
./markitdown.sh /data/input.pdf -o /data/output.md
```

The output file will inherit the ownership and permissions of the input file automatically.

### Pipe content into the container

```bash
cat input.pdf | docker compose run --rm -T markitdown > output.md
```

### Convert a URL

```bash
./markitdown.sh https://example.com/page > output.md
```

### Convert a YouTube video (fetches transcript)

```bash
./markitdown.sh https://www.youtube.com/watch?v=VIDEO_ID > output.md
```

### Convert with Azure Document Intelligence

Requires an [Azure Document Intelligence](https://learn.microsoft.com/azure/ai-services/document-intelligence/)
resource endpoint:

```bash
./markitdown.sh /data/input.pdf -d -e "https://your-resource.cognitiveservices.azure.com/"
```

### List installed plugins

```bash
./markitdown.sh --list-plugins
```

---

## Command reference

| Option | Description |
|---|---|
| `[file_or_url]` | Path inside the container (e.g. `/data/file.pdf`) or a URL |
| `-o FILE` | Write output to `FILE` instead of stdout |
| `-d` | Use Azure Document Intelligence for conversion |
| `-e ENDPOINT` | Azure Document Intelligence endpoint URL (used with `-d`) |
| `--llm-client CLIENT` | LLM client to use for image descriptions and OCR (e.g. `openai`) |
| `--llm-model MODEL` | LLM model name (e.g. `gpt-4o`, `claude-opus-4-6`) |
| `--use-plugins` | Enable installed third-party plugins (**always passed automatically**) |
| `--list-plugins` | List installed plugins and exit |
| `--help` | Show help and exit |

> `--use-plugins` is always injected by the container entrypoint — you do not need to pass it
> manually. `--llm-client` and `--llm-model` are also injected automatically when `OPENAI_API_KEY`
> and `LLM_MODEL` are set in `docker-compose.yml`.

---

## Supported formats

| Format | Notes |
|---|---|
| PDF | Text extraction; full-page OCR for scanned PDFs when LLM is configured |
| Word (DOCX) | Text, headings, tables, images |
| PowerPoint (PPTX) | Slides, shapes, images |
| Excel (XLSX / XLS) | Sheets and tables |
| Images (PNG, JPG, …) | EXIF metadata; LLM image description when configured |
| Audio (WAV, MP3) | EXIF metadata; speech transcription via `ffmpeg` |
| HTML | Structure preserved as Markdown |
| CSV / JSON / XML | Converted to readable Markdown |
| ZIP | Iterates and converts all contents |
| YouTube URLs | Fetches and formats the video transcript |
| EPub | Chapter text and structure |
| Outlook messages | Email body and metadata |

---

## Installed dependencies

| Component | Version / Notes |
|---|---|
| Python | 3.13 slim |
| ffmpeg | System package — required for audio transcription |
| exiftool | System package — image and audio metadata |
| `markitdown[all]` | All optional format extras: pptx, docx, xlsx, xls, pdf, outlook, az-doc-intel, audio-transcription, youtube-transcription |
| `markitdown-sample-plugin` | Bundled upstream sample plugin |
| `markitdown-ocr` | LLM Vision OCR plugin for images in PDF/DOCX/PPTX/XLSX |
| `openai` | OpenAI-compatible SDK used by markitdown-ocr |

---

## Notes

- The container working directory is `/data`. Mount your local directory to `/data` to access files:
  `-v "$(pwd):/data"` (plain Docker) or the `volumes` entry in `docker-compose.yml`.
- MarkItDown performs file and URL I/O with the privileges of the running process. Do not pass
  untrusted files, paths, or URLs without validation first.
- The image does not require Python, MarkItDown, or any other tool on the host — only Docker.

### Output file ownership

When writing output via `-o`, the container runs as root internally. The entrypoint automatically
matches the output file's ownership (user:group) and permissions to those of the input file after
conversion completes.

When redirecting stdout to a file (`> output.md`), the output file is created by the host shell
under your current user — no special handling is needed.

---

## Claude Code skill

A [Claude Code](https://claude.ai/claude-code) skill is included so that AI agents can automatically
invoke markitdown whenever they need to convert a supported document to Markdown — without any manual
prompting.

### What it does

When Claude encounters a task that involves converting a file or URL to Markdown (e.g. "extract text
from this PDF", "convert this Word document", "turn this into markdown"), it automatically loads the
`convert-documents-to-markdown` skill and uses `markitdown.sh` to perform the conversion.

### Installation

Run the install-skill target:

```bash
make install-skill
```

It will prompt for the skills directory, defaulting to `~/.claude/skills`. Press Enter to accept
the default or type a custom path:

```
Skills directory [/home/you/.claude/skills]:
Skill installed to /home/you/.claude/skills/convert-documents-to-markdown/
```

Claude Code picks up skills from `~/.claude/skills/` automatically — no further configuration
required.

### Skill location

```
skills/
  convert-documents-to-markdown/
    SKILL.md
```

---

## Credits

- **[MarkItDown](https://github.com/microsoft/markitdown)** — the underlying conversion tool, developed and maintained by [Microsoft](https://github.com/microsoft). Licensed under the MIT License.
- **[markitdown-ocr](https://github.com/microsoft/markitdown/tree/main/packages/markitdown-ocr)** — LLM Vision OCR plugin for MarkItDown. Part of the MarkItDown project.
