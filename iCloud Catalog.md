---
date: 2026-04-19
tags:
  - homelab
  - ai
  - icloud
  - mac-mini
parent: "[[Homelab 3.0]]"
---

# iCloud Catalog — Local AI File Analyzer

Local AI pipeline running on the Mac Mini (192.168.3.30) that walks iCloud Drive, analyzes every file using Gemma 4 via Ollama, and writes structured catalogs + directory summaries.

## Why abliterated

Default Gemma 4 refuses to describe a large chunk of real-world photo content (anything it reads as sensitive, nude, violent, etc.). Since this is a local, private catalog of personal files, those refusals are pure noise — the catalog gets `I can't help with that` as a description. `huihui_ai/gemma-4-abliterated:e2b` is the same model with the refusal direction ablated; it produces a real description regardless of content.

## Goals

1. Catalog 361K files across 15,376 directories in iCloud Drive
2. Generate rich LLM descriptions for images, videos, PDFs, and text files
3. Group "other" files by extension at folder level (no LLM needed)
4. Extract EXIF metadata (date + GPS) from photos for later organization
5. Generate directory-level summaries bottom-up

## Stack

| Component | Version / Model |
|-----------|-----------------|
| Ollama | Native API on port 11434 (OpenAI-compat vision is broken) |
| Vision/Text model | `huihui_ai/gemma-4-abliterated:e2b` (abliterated for explicit content) |
| Transcription | whisper.cpp with Metal GPU acceleration |
| Frame extraction | ffmpeg |
| EXIF | Pillow (PIL) with pillow-heif |
| PDF extraction | pdfplumber |
| DOCX / XLSX | python-docx, openpyxl |

## Location

- **Scripts:** `~/icloud-catalog/` on Mac Mini
  - `setup.sh` — installs Homebrew, ffmpeg, whisper.cpp, Python packages
  - `icloud_catalog.py` — main cataloger (folder-first)
  - `icloud_summarize.py` — bottom-up directory summarizer
  - `run_catalog.sh` — convenience wrapper: `./run_catalog.sh` runs both scripts sequentially; `./run_catalog.sh catalog` or `./run_catalog.sh summarize` runs one. Honors exit codes and won't summarize if cataloging crashed.
- **Output per folder:** `file_catalog.txt` + `summary.txt` in each directory of iCloud Drive
- **Log:** `~/icloud-catalog/catalog.log`

## Architecture

### Folder-first processing

Original design processed every file individually → ETA 12+ days for 42K rich files. Restructured:

1. **Phase 1:** Walk tree, collect all directory paths (lightweight)
2. **Phase 2:** For each directory:
   - Classify files into **rich** (images, videos, PDFs, .txt, .md, .rtf) vs **other** (code, config, archives, audio, etc.)
   - Send each rich file to the LLM for individual description
   - Group "other" files by extension with counts (no LLM call)
3. **Phase 3:** `icloud_summarize.py` walks bottom-up, generating `summary.txt` for each directory using its `file_catalog.txt` and child `summary.txt` files

### Catalog format

Tab-separated, 4 fields (handles filenames with `:`):
```
filename<TAB>description<TAB>file_meta_json<TAB>entry_meta_json
```

- `file_meta_json` — what the file is (EXIF/ffprobe): `taken`, `lat`, `lon`, `cam`, `dims`, `dur`
- `entry_meta_json` — who/when wrote this line: `model`, `ts` (UTC)

Example:
```
photo.jpg	A sunset over the ocean with silhouetted palm trees	{"taken":"2024-03-15T14:30:00","lat":37.7749,"lon":-122.4194,"cam":"Apple iPhone 15 Pro","dims":[4032,3024]}	{"model":"huihui_ai/gemma-4-abliterated:e2b","ts":"2026-04-19T19:30:12Z"}
clip.mp4	Birthday party cake cutting	{"taken":"2023-06-12T18:45:00","dur":45.2,"dims":[1920,1080],"cam":"Apple iPhone 15 Pro"}	{"model":"huihui_ai/gemma-4-abliterated:e2b","ts":"2026-04-19T19:31:08Z"}
report.pdf	Q4 financial report showing 15% revenue growth	{}	{"model":"huihui_ai/gemma-4-abliterated:e2b","ts":"2026-04-19T19:31:55Z"}
[Other files] 12 .json, 3 .py, 5 .txt
```

Parser handles tab format with 1–4 fields; legacy colon-only format still accepted via longest-prefix match against actual directory contents.

## Key Issues Resolved

### 1. OpenAI-compatible vision API is broken in Ollama
- **Symptom:** `string indices must be integers, not 'tuple'` errors on every image
- **Diagnosis:** Same test via `openai` client returned empty strings; via native `ollama.chat()` returned proper descriptions
- **Fix:** Refactored `llm_vision()` and `llm_text()` to use `ollama.chat()` with `images=[bytes]` field instead of OpenAI data-URL format. Kept `openai` client for nothing now (imports could be cleaned up).
- **Reference:** [GitHub issue #3690](https://github.com/ollama/ollama/issues/3690) confirms OpenAI-compat vision is incomplete

### 2. pdfplumber stderr warnings crashed unrelated code
- **Symptom:** Initially wrapped `process_rich_file` in `sys.stderr = open(os.devnull)` to hide pdfminer FontBBox warnings. This broke the OpenAI SDK's internal logging.
- **Fix:** Moved stderr suppression into `extract_text_from_pdf` only, using `os.dup2()` to redirect fd 2 at the C level

### 3. Filenames containing `:` broke the resume logic
- **Symptom:** Files like `Python:AI Developer.pdf` got re-processed every run because the parser split on the first `:`
- **Fix:** Switched output separator to tab. Parser prefers tab format; falls back to trying longest matching prefix against actual directory contents when only `:` is present

### 4. SSH dropouts killed long runs
- **Symptom:** MacBook restart → SSH closed → script died (SIGHUP)
- **Fix:** Run with `nohup python3 -u script.py < /dev/null > catalog.log 2>&1 &` then `disown`. Monitor with `tail -f catalog.log` from any new session.

### 5. Memory exhaustion on full tree walk
- **Symptom:** Original script collected all 361K file paths into a list before processing — ran out of memory and killed SSH
- **Fix:** Folder-first approach only loads one directory's file list at a time

## Prompts

All prompts use `[TASK]` / `[OUTPUT FORMAT]` tags to keep Gemma structured. Token cap is `num_predict: 1024` for every call.

### Image (per file)
```
[TASK] Describe this image in exactly one concise sentence.
[OUTPUT FORMAT] (Single concise sentence only)
```
Image sent as raw bytes via `ollama.chat(images=[bytes])`.

### Video — Stage 1: narrative from frames
```
[TASK] These are {N} frames extracted from a {duration} video, shown in
chronological order. Describe what happens in this video as a brief
narrative story (3-5 sentences).
[OUTPUT FORMAT] (Brief narrative paragraph)
```

### Video — Stage 2: collapse narrative to one line
```
[TASK] Summarize this video description into exactly one concise sentence.

[VIDEO STORY]
{stage 1 output}

[OUTPUT FORMAT] (Single concise sentence only)
```

### Audio
```
[TASK] Summarize this audio transcription in exactly one concise sentence.

[TRANSCRIPT]
{whisper.cpp output, truncated to 8000 chars}

[OUTPUT FORMAT] (Single concise sentence only)
```

### Document (PDF / DOCX / XLSX / iWork)
```
[TASK] Summarize this document in exactly one concise sentence.

[DOCUMENT CONTENT]
{extracted text, truncated to 8000 chars}

[OUTPUT FORMAT] (Single concise sentence only)
```

### Text / code
```
[TASK] Summarize this {.ext} file in exactly one concise sentence.

[FILE CONTENT]
{content, truncated to 8000 chars}

[OUTPUT FORMAT] (Single concise sentence only)
```

### Directory summary (`icloud_summarize.py`)
```
[TASK] You are organizing a file system. Based on the file descriptions and
subdirectory summaries below, write a concise paragraph (2-4 sentences)
explaining what the directory "{dir_name}" is used for and what it contains.

[FILES IN THIS DIRECTORY]
{file_catalog.txt contents}

[SUBDIRECTORY SUMMARIES]
  {child1}/: {child1 summary.txt}
  {child2}/: {child2 summary.txt}

[OUTPUT FORMAT] (Concise paragraph, 2-4 sentences. Describe the purpose
and contents. Do not list individual files.)
```

Context is truncated to `MAX_CONTEXT_CHARS = 12000` — if the combined catalog + child summaries exceed that, tail is dropped with a `[... truncated ...]` marker. No sampling or intelligent windowing; first-N wins.

### Response cleanup (`_clean_response`)

Stripped regardless of prompt:
- Leading `"Refined sentence:"`, `"The image shows"`, `"Here is"`, `"Summary:"`, `"Let's try"`, `"This image is"`
- Surrounding single/double quotes
- Any leading label followed by `:` if the label is under 30 chars (grabs the content after the colon)
- Whitespace/newlines collapsed to single spaces

## Video handling

### Frame sampling tiers (duration → frame count)
| Duration | Frames |
|----------|--------|
| < 30s | 1 |
| 30s – 2min | 4 |
| 2min – 10min | 8 |
| > 10min | 16 |

Frames are extracted with `ffmpeg -ss {ts} -i {path} -frames:v 1 -q:v 2` at evenly-spaced timestamps (5% margin at start/end). Written to a temp dir as JPEG, loaded as raw bytes, deleted.

### Frame description strategy
All frames are sent in a **single vision call** as an ordered sequence — not one-per-frame. Gemma sees them as a chronological sequence and writes a narrative. This is 1 LLM call per video regardless of frame count.

### Audio not merged with video
`process_video` never invokes whisper.cpp. Audio-only files go through `process_audio`, which does transcribe, but its output is only the one-line summary — the full transcript is **not** stored anywhere. If the transcript itself is worth keeping, this is a design gap (no sidecar file, not in metadata).

### Video size cap
Files over `MAX_VIDEO_SIZE_MB = 2000` (2GB) are skipped with `[Video file (Xmb) — too large to process]`. Only frames are read from disk, never the full file.

## Directory summary algorithm

`icloud_summarize.py` runs after cataloging is complete.

1. Walk tree, sort directories by depth descending (deepest first)
2. For each directory, check `needs_update()`:
   - No `summary.txt` exists → needs update
   - `file_catalog.txt` mtime > `summary.txt` mtime → needs update
   - Any child `summary.txt` mtime > this `summary.txt` mtime → needs update
3. Read `file_catalog.txt` verbatim, read every child's `summary.txt`, format as shown in the prompt above
4. Call LLM, write result to `summary.txt` with the current mtime

No per-file token budgeting. No sampling of children. If a directory has 10,000 catalog entries, the first 12,000 chars (≈ first ~200 files) go in, the rest are dropped. This is a known weakness for huge photo folders.

## Rich vs. other classification

### Rich (get individual LLM descriptions)
- **Images:** `.png .jpg .jpeg .gif .webp .bmp .tiff .tif .heic .heif .ico .svg`
- **Videos:** `.mp4 .mov .m4v .avi .mkv .wmv .flv .webm .mpg .mpeg .3gp`
- **Documents:** `.pdf` (only PDFs in this tier — DOCX/XLSX/etc. go in "other" despite having extractors)
- **Text:** `.txt .md .markdown .rtf`

### Grouped "other" (counted by extension, no LLM call)
Everything else. The explicit sets defined for classification purposes:
- **Audio:** `.mp3 .m4a .wav .aac .flac .ogg .wma .aiff .aif`
- **Documents (non-PDF):** `.docx .doc .xlsx .xls .pptx .ppt .pages .numbers .key`
- **Text/code:** `.csv .tsv .json .xml .yaml .yml .toml .ini .cfg .conf .log .sh .bash .zsh .fish .py .js .ts .jsx .tsx .html .htm .css .scss .java .c .cpp .h .hpp .cs .go .rs .rb .php .swift .kt .scala .r .m .mm .sql .graphql .proto .env .gitignore .dockerignore .editorconfig .tex .bib .org .rst`
- **Archives:** `.zip .tar .gz .bz2 .xz .7z .rar .dmg .iso .pkg .deb .rpm`
- **Unknown:** anything not matched above

### Edge cases
- **HEIC/HEIF:** converted to JPEG via macOS `sips` before the vision call
- **SVG:** vision skipped; SVG source text sent to `llm_text` instead
- **`.mov`:** treated as video (processed by ffmpeg)
- **Apple iWork (`.pages`/`.numbers`/`.key`):** `textutil -convert txt -stdout` — usually works, not guaranteed
- **Encrypted PDFs:** pdfplumber raises; caught by the `except Exception: return None` in `extract_text_from_pdf` → `[Document (.pdf) — could not extract readable text]`
- **`.pptx`/`.ppt`:** explicitly unsupported → `[Presentation file — content not extractable in current setup]`
- **Password-protected DOCX:** python-docx raises; same error path
- **Pages over 10 in a PDF:** only first 10 extracted, tail marked `[... X more pages ...]`

## iCloud placeholder files

macOS "Optimize Mac Storage" leaves unloaded files as zero-byte placeholders named `.{original_name}.icloud`.

**Current behavior:**
- Script detects them via `is_icloud_placeholder` (starts with `.`, ends with `.icloud`)
- If the unwrapped name (`original_name`) would be a rich file, it's added to `rich_files` — but `process_rich_file` short-circuits with `[File 'original_name' exists in iCloud but is not downloaded locally]`
- If it would be an "other" file, it's counted in the grouped line under the unwrapped name's extension
- Either way, the placeholder is cataloged; **the file is never forced to download**

**Implication:** anything showing `[File ... exists in iCloud but is not downloaded locally]` is a gap. To fix: either run `brctl download` on the directory first, or add a `Path.touch()` / file-read nudge in the placeholder branch to trigger on-demand download. Currently not implemented.

## Metadata JSON schema

Each rich-file line has two JSON objects: file metadata (3rd field) and entry metadata (4th field).

### File metadata (3rd tab field)

| Key | Type | When present | Source |
|-----|------|--------------|--------|
| `taken` | ISO 8601 string | EXIF `DateTimeOriginal` (36867) or `DateTime` (306) for images; `creation_time` / `com.apple.quicktime.creationdate` for videos | `PIL.Image.getexif()` for images, `ffprobe -show_entries format_tags` for videos |
| `lat` | float (decimal degrees, 6 dp) | EXIF GPS IFD 34853 contains lat tags, or video has `location` / ISO6709 tag | DMS→decimal for images, regex on `[+-]DD.DDDD[+-]DDD.DDDD` for videos |
| `lon` | float (decimal degrees, 6 dp) | Same as `lat` | Same |
| `cam` | string | EXIF `Make` (271) + `Model` (272) concatenated; or QuickTime `com.apple.quicktime.make` + `com.apple.quicktime.model` | EXIF / ffprobe |
| `dims` | `[int, int]` | Always for images (PIL `img.width, img.height`); when present on video stream | PIL / ffprobe |
| `dur` | float (seconds, 1 dp) | Videos only, from ffprobe `format.duration` | ffprobe |

Absent keys mean the metadata wasn't readable — empty object `{}` is written when no fields extracted. Images and videos only; PDFs/text always get `{}`. Timezone info is preserved verbatim from source (EXIF is usually naïve local; Apple QuickTime is UTC with offset).

### Entry metadata (4th tab field)

| Key | Type | Value |
|-----|------|-------|
| `model` | string | Exact `MODEL_NAME` used for this line's description |
| `ts` | ISO 8601 UTC with `Z` suffix | When this catalog line was written |

Always present for new entries written after the 4-field update. Legacy 3-field entries have no entry metadata — when ingested into SQLite, `entry_model` and `entry_ts` are NULL.

## Performance

Measured on Mac Mini M-series, `huihui_ai/gemma-4-abliterated:e2b` loaded in Ollama:
- **Images:** ~3–8s each (varies by resolution)
- **PDFs:** ~5–20s (extraction + LLM)
- **Videos:** 10–45s depending on frame count (1 to 16 frames)
- **Text files:** ~1–6s (short files can return `[Empty or near-empty text file]` in <1s)
- **Directories with only "other" files:** <50ms (no LLM)
- **Pure walk of one directory:** typically <10ms

Starting from 42,931 rich files, average throughput settles around 4–6s per rich file once model is warm → ETA roughly 2–3 days of continuous runtime. Memory usage: Ollama process ~5GB RSS (model resident), Python ~200–400MB.

Catalog disk footprint: ~200 bytes per file (filename + description + metadata JSON), so ~80MB across all catalogs for this dataset — negligible.

## Failure modes

| Scenario | What happens |
|----------|--------------|
| Ollama daemon dies mid-file | `ollama.chat` raises → caught in `llm_vision`/`llm_text` → returns `[Vision error: ...]` / `[LLM error: ...]` as the description. The line is **still written** to the catalog and considered "done" on next run. Will not retry automatically. |
| PDF is password-protected | pdfplumber raises → `extract_text_from_pdf` returns None → catalog entry `[Document (.pdf) — could not extract readable text]` |
| HEIC decode fails (sips error) | `_convert_heic_to_bytes` returns None → catalog entry `[Image file — format not supported for vision analysis]` |
| Corrupt video | `ffprobe` fails to read duration → `[Video file — could not read duration]`; or frame extraction returns 0 frames → `[Video file (dur) — frame extraction failed]` |
| File over size cap | Pre-LLM size check → `[Image/Video/Audio/Document file — too large to analyze]` |
| Permission denied on directory | `process_directory` catches `PermissionError`, returns zero-work stats, directory skipped silently |
| Empty LLM response | `_clean_response` returns empty string → catalog stores empty description (still marked "done") |
| Disk fills | `f_out.write` raises → the enclosing `with open(catalog_path, 'a')` block exits without re-raising cleanly; process crashes, but already-written lines are fsync'd via `f.flush()` after every file |

**No retry queue exists.** Everything that errors once gets a negative cache line and is never re-attempted unless you delete the line from `file_catalog.txt` manually. To force a retry for a specific folder, `sed -i '' '/ERROR_PATTERN/d' that_folder/file_catalog.txt`.

## Model-swap invalidation

Catalogs do **not** record which model wrote each line. If `MODEL_NAME` changes, all existing entries stay — the script will only fill in files not yet cataloged.

To force regeneration with a new model:
- **Nuke all descriptions:** `find ~/Library/Mobile\ Documents/com~apple~CloudDocs/ -name "file_catalog.txt" -delete`
- **Nuke error entries only:** `find ~/Library/Mobile\ Documents/com~apple~CloudDocs/ -name "file_catalog.txt" -exec sed -i '' '/\[.*error/d' {} \;`
- **Nuke just summaries:** `find ... -name "summary.txt" -delete` (next summarize run regenerates)

Possible improvement: add a fourth tab-separated field with `{"model": "name", "ts": ISO}` so line-level regen is feasible.

## EXIF Metadata Extraction

Added `get_file_metadata(path)` that returns `{"taken": ISO_date, "lat": ..., "lon": ...}`:
- **Images:** Uses `PIL.Image.getexif()` — tag 36867 (DateTimeOriginal), IFD 34853 (GPS). Handles DMS→decimal conversion.
- **Videos:** Uses `ffprobe -show_entries format_tags` — reads `com.apple.quicktime.creationdate` and `com.apple.quicktime.location.ISO6709`

Console output shows: `photo.jpg — A sunset over... [📅2024-03-15 📍37.775,-122.419] (3.2s)`

Enables future photo organization by time/location clustering.

## Running

### Start (from Mac Mini)
```bash
cd ~/icloud-catalog && nohup python3 -u icloud_catalog.py < /dev/null > catalog.log 2>&1 &
disown
```

### Monitor
```bash
tail -f ~/icloud-catalog/catalog.log
```

### Check progress
```bash
find ~/Library/Mobile\ Documents/com~apple~CloudDocs/ -name "file_catalog.txt" 2>/dev/null | wc -l
```

### Stop
```bash
pkill -f icloud_catalog.py
```

### Run the summarizer (after cataloging)
```bash
cd ~/icloud-catalog && nohup python3 -u icloud_summarize.py < /dev/null > summarize.log 2>&1 &
disown
tail -f summarize.log
```
Same nohup/disown pattern — summarization is also long-running (one LLM call per directory that changed). It's idempotent: directories whose `summary.txt` is newer than all inputs are skipped. Stop with `pkill -f icloud_summarize.py`.

### Full pipeline
```bash
cd ~/icloud-catalog && nohup ./run_catalog.sh < /dev/null > pipeline.log 2>&1 &
disown
```
Runs cataloger, waits for clean exit (or Ctrl+C), then runs summarizer.

### Model swap
All config at top of `icloud_catalog.py` and `icloud_summarize.py`:
```python
OLLAMA_URL = "http://localhost:11434/v1"
MODEL_NAME = "huihui_ai/gemma-4-abliterated:e2b"
```

## Resumability

The catalog is idempotent:
- Each run re-parses `file_catalog.txt` to see what's already done
- Skipped files: those already listed by filename in the catalog
- Skipped directories: those with no rich files and an existing `[Other files]` summary line
- Interrupt with Ctrl+C or `pkill` — safe to resume anytime

## Known issues / TODO

### Correctness
- **Negative cache on errors** — transient Ollama / network hiccups write `[Vision error: ...]` or `[LLM error: ...]` as the description and the line is treated as done on resume. Until a retry tool exists, a single bad moment can permanently poison any file it hit. **Mitigation plan:** `retry_errors.py` that greps all `file_catalog.txt` for `\[.*error|not downloaded locally\]`, deletes those lines, optionally runs `brctl download` first, then re-invokes the cataloger on only the affected directories.
- **No verification / spot-check** — with 42K rich files and no ground truth, systematic wrongness (e.g. a model swap silently degrading captions) goes undetected. **Mitigation plan:** `spot_check.py` that samples N random catalog entries, opens the file alongside its description in Quick Look, and logs accept/reject — simplest possible human-in-the-loop QA.

### Content gaps
- **Audio transcript is discarded** — `process_audio` sends the transcript to the LLM for a one-liner, then throws it away. Full whisper output never persists. **Mitigation plan:** write a sidecar `<filename>.transcript.txt` next to the audio file, and reference its existence in metadata (e.g. `{"transcript":"./song.transcript.txt"}`).
- **Directory summaries truncate at 12K chars** — for a folder with 10K photo entries, only the first ~200 lines reach the summary prompt. **Mitigation plan:** before truncation, sample-N-per-subdir (e.g. random 20 from this dir's catalog + full child summaries) so the model sees representative breadth instead of alphabetical head.
- **`num_predict: 1024` is a global cap** — fine for per-file one-liners, possibly tight for directory summaries that want real 2–4 sentences. **Mitigation plan:** separate caps: keep 256 for one-liner outputs, bump to 1024+ for directory summaries only.
- **iCloud placeholders never forced down** — noted above. **Mitigation plan:** optional `--force-download` flag that runs `brctl download` on the directory before processing.
- **Model identity not recorded per line** — noted in the Model-swap section. **Mitigation plan:** fourth tab-separated field `{"model":"...","ts":"..."}` so a model swap + retry tool can target only stale lines.

### Architecture
- **Single-threaded through Ollama** — one request in flight at a time. On Apple Silicon this is probably the right call (Ollama already maxes the GPU per request), but worth measuring. **Test plan:** fire 2–4 concurrent `ollama.chat` calls against the loaded model and measure tokens/sec vs serial — if it doesn't degrade, add a `concurrent.futures.ThreadPoolExecutor` around `process_rich_file` with a configurable worker count.

## Possible next steps (once catalogs exist)

### Organize the files themselves
- **Photo/video reorg by EXIF** — cluster by time + GPS into `YYYY/YYYY-MM-DD Location/`. Use gap-detection on timestamps for trip-sized buckets (e.g., > 6h gap = new trip).
- **Duplicate detection** — exact SHA256 for bit-identical; description-similarity + timestamp proximity for cross-format dupes (HEIC/JPG pair, PDF/DOCX of same doc).
- **Misfile detection** — flag files whose description diverges semantically from their directory's `summary.txt` (e.g., tax PDF in a photos folder).
- **Cleanup candidates** — large old files with low-value descriptions, screenshots older than N months, duplicate downloads.

### Make the catalog queryable
- **Single index** (SQLite + FTS5 or a vector DB) built from all `file_catalog.txt` files — one row per file: path, description, ext, EXIF, embedding.
- **Natural-language search** — "photos from Rome trip", "PDF about mortgage", "videos from last summer".
- **Timeline + map views** from EXIF.
- **Auto-tag taxonomy** — extract recurring entities from descriptions, produce a tag vocabulary, backfill per file.
- **Obsidian integration** — file-per-folder MOC with wikilinks, or per-topic MOCs pulling files by tag.
- **Incremental diff** — re-run only on directories with changed mtime; produce a "what's new" digest.

## Related

- [[Infrastructure Overview]] — Mac Mini at 192.168.3.30
- [[Homelab TODO]]
