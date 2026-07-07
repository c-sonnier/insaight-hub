---
title: "feat: Add markdown output format for insights"
type: feat
status: completed
date: 2026-02-23
---

# feat: Add markdown output format for insights

## Overview

When LLMs consume insights via MCP tools or the REST API, they receive full raw HTML/CSS/JS content. This wastes tokens on presentational markup that provides no semantic value. This feature adds an optional `format` parameter that returns insight content as clean markdown, stripping CSS, JS, and non-textual elements.

## Problem Statement

Insights stored as multi-file HTML bundles (HTML + CSS + JS) can be very large. An LLM reading an insight via `GetInsightTool` or `GET /api/v1/insight_items/:slug` receives the full raw content of every file — including stylesheets, scripts, and base64-encoded images. This:

- Consumes excessive context window tokens
- Includes irrelevant information (CSS classes, JS logic, encoded images)
- Reduces the effective payload an LLM can reason about
- Makes multi-insight analysis impractical within token limits

## Proposed Solution

Add HTML-to-markdown conversion using the `reverse_markdown` gem. Expose it through:

1. **MCP GetInsightTool** — `format` parameter, defaults to `"markdown"`
2. **REST API** — `?format=markdown` query parameter on `GET /api/v1/insight_items/:slug`
3. **Model layer** — Reusable `InsightItemFile#to_markdown` and `InsightItem#files_as_markdown` methods

### File Filtering Rules (markdown mode)

| Content Type | Behavior |
|---|---|
| `text/html` | Convert to markdown via `reverse_markdown` |
| `text/markdown` | Pass through as-is |
| `application/json` | Include wrapped in fenced `json` code block |
| `text/css` | **Exclude** |
| `text/javascript` / `application/javascript` | **Exclude** |
| Other (`text/plain`, etc.) | **Exclude** |

### HTML Preprocessing (before conversion)

Before passing HTML to `reverse_markdown`:
1. **Strip `<style>` tags and contents** — removes inline CSS
2. **Strip `<script>` tags and contents** — removes inline JS
3. **Replace base64 image `src` attributes** — `data:image/...` → `![image](image-removed)`
4. **Replace inline SVGs** — `<svg>...</svg>` → `[SVG graphic]`

This ensures the markdown output contains only textual content.

### Response Shape Changes

When `format=markdown`:
- Converted HTML files have `content_type: "text/markdown"`
- JSON files have `content_type: "application/json"` (unchanged), content wrapped in fenced code block
- CSS/JS files are excluded from the `files` array
- Entry file ordering preserved (entry file first)

When `format=html` (or default for REST API):
- Existing behavior, unchanged

## Technical Approach

### Phase 1: Dependencies and Model Layer

**Add gem:**
- `reverse_markdown` to Gemfile

**`app/models/insight_item_file.rb`** — Add `to_markdown` instance method:

```ruby
# app/models/insight_item_file.rb
def to_markdown
  case
  when html?
    convert_html_to_markdown
  when markdown?
    content
  when content_type == "application/json"
    "```json\n#{content}\n```"
  else
    nil # signals this file should be excluded
  end
end

private

def convert_html_to_markdown
  cleaned = HtmlToMarkdownConverter.convert(content)
  cleaned
end
```

**`app/services/html_to_markdown_converter.rb`** — Extraction service:

```ruby
# app/services/html_to_markdown_converter.rb
class HtmlToMarkdownConverter
  def self.convert(html)
    doc = Nokogiri::HTML.fragment(html)

    # Strip <style> and <script> tags
    doc.css("style, script").remove

    # Replace base64 images with placeholder
    doc.css("img[src^='data:image']").each do |img|
      img["src"] = "image-removed"
    end

    # Replace inline SVGs with placeholder
    doc.css("svg").each do |svg|
      svg.replace("[SVG graphic]")
    end

    ReverseMarkdown.convert(doc.to_html, unknown_tags: :bypass)
  end
end
```

**`app/models/insight_item.rb`** — Add `files_as_markdown` method:

```ruby
# app/models/insight_item.rb
def files_as_markdown
  entry = entry_insight_item_file
  files = insight_item_files.select { |f| f.to_markdown.present? }

  # Entry file first, then alphabetical
  files.sort_by! do |f|
    [f == entry ? 0 : 1, f.filename]
  end

  files.map do |file|
    {
      id: file.id,
      filename: file.filename,
      content_type: file.html? ? "text/markdown" : file.content_type,
      content: file.to_markdown
    }
  end
end
```

### Phase 2: MCP Tool Update

**`app/tools/get_insight_tool.rb`:**

- Add optional `format` parameter to `input_schema` (enum: `["markdown", "html"]`)
- Default to `"markdown"` when not provided
- When `format == "markdown"`: use `insight.files_as_markdown` for file data
- When `format == "html"`: use existing raw file data
- Validate `format` value, return error for invalid values
- Update tool `description` to reflect new default

```ruby
# app/tools/get_insight_tool.rb (updated)
input_schema(
  properties: {
    slug: { type: "string", description: "The insight slug" },
    format: {
      type: "string",
      description: "Output format: 'markdown' (default, text content only) or 'html' (all raw files)",
      enum: ["markdown", "html"]
    }
  },
  required: ["slug"]
)

def call(slug:, format: "markdown", server_context:)
  # ... find insight ...

  files_data = if format == "markdown"
    insight.files_as_markdown
  else
    insight.insight_item_files.map { |f| { id: f.id, filename: f.filename, content_type: f.content_type, content: f.content } }
  end

  result = {
    insight: {
      # ... metadata fields ...
      format: format,
      files: files_data
    }
  }
end
```

### Phase 3: REST API Update

**`app/controllers/api/v1/insight_items_controller.rb`:**

- Accept `params[:format_type]` query parameter (use `format_type` to avoid Rails `format` collision)
  - Actually, since this is an API-only controller (`ActionController::API`), `params[:format]` may conflict with Rails routing. Use `params[:content_format]` to be safe.
  - **Decision**: Use `params[:content_format]` with values `"markdown"` or `"html"`. Default: `"html"` (backward compatible).
- Update `insight_item_json` helper to accept a format option
- When `content_format=markdown`: use `insight.files_as_markdown`

```ruby
# In show action:
def show
  render json: insight_item_json(@insight_item, include_files: true, content_format: params[:content_format])
end

# In helper:
def insight_item_json(insight_item, include_files: false, content_format: "html")
  # ... existing metadata ...
  if include_files
    json[:files] = if content_format == "markdown"
      insight_item.files_as_markdown
    else
      # existing raw file logic
    end
  end
end
```

### Phase 4: Error Handling

- **Invalid format values**: Return `{ error: "Invalid format. Must be: markdown or html" }` with appropriate status
- **Per-file conversion failures**: If `reverse_markdown` raises on a specific file, return that file with raw content + `conversion_warning` field
- **Empty files after filtering**: Return empty `files` array with `note: "No text content files found in this insight"`

### Phase 5: Tests and Documentation

**Tests:**
- `test/models/insight_item_file_test.rb` — Unit tests for `to_markdown` with various content types
- `test/services/html_to_markdown_converter_test.rb` — Tests for HTML preprocessing (strip style/script, base64 replacement, SVG replacement)
- `test/tools/get_insight_tool_test.rb` — Integration tests for format parameter
- `test/controllers/api/v1/insight_items_controller_test.rb` — API format parameter tests

**Documentation:**
- Update `docs/API.md` with `content_format` query parameter
- Update MCP tool description string

## Acceptance Criteria

- [x] `reverse_markdown` gem added to Gemfile
- [x] `InsightItemFile#to_markdown` converts HTML files to clean markdown
- [x] `HtmlToMarkdownConverter` strips `<style>`, `<script>`, base64 images, inline SVGs before conversion
- [x] `InsightItem#files_as_markdown` returns filtered, converted file array (entry file first)
- [x] MCP `GetInsightTool` defaults to markdown format, supports `format: "html"` for raw output
- [x] MCP tool description updated to reflect markdown default
- [x] REST API `GET /api/v1/insight_items/:slug?content_format=markdown` returns markdown
- [x] REST API defaults to raw HTML (backward compatible)
- [x] Invalid format values return clear error messages (MCP: enum validation; API: unknown values default to html)
- [x] Conversion errors on individual files are handled gracefully (raw content + warning)
- [x] Empty file arrays after filtering return empty array (clear signal, no special note needed)
- [x] Converted HTML files report `content_type: "text/markdown"`
- [x] JSON files included in markdown mode wrapped in fenced code blocks
- [x] CSS and JS files excluded in markdown mode
- [x] Tests cover: HTML conversion, style/script stripping, base64 handling, SVG handling, multi-file ordering, error cases
- [x] `docs/API.md` updated with new `content_format` parameter

## Files to Modify

| File | Change |
|------|--------|
| `Gemfile` | Add `gem "reverse_markdown"` |
| `app/services/html_to_markdown_converter.rb` | **New** — HTML preprocessing + conversion |
| `app/models/insight_item_file.rb` | Add `to_markdown` method |
| `app/models/insight_item.rb` | Add `files_as_markdown` method |
| `app/tools/get_insight_tool.rb` | Add `format` param, default to markdown, update description |
| `app/controllers/api/v1/insight_items_controller.rb` | Add `content_format` param support |
| `docs/API.md` | Document `content_format` parameter |
| `test/models/insight_item_file_test.rb` | Unit tests for `to_markdown` |
| `test/services/html_to_markdown_converter_test.rb` | **New** — Converter tests |
| `test/tools/get_insight_tool_test.rb` | Format parameter tests |
| `test/controllers/api/v1/insight_items_controller_test.rb` | API format tests |

## Dependencies & Risks

**Dependencies:**
- `reverse_markdown` gem — well-maintained, ~2M downloads, uses Nokogiri (already a transitive dep)
- Nokogiri — already available as Rails dependency

**Risks:**
- **Conversion quality**: Complex HTML tables, nested layouts may produce imperfect markdown. Mitigated by using `unknown_tags: :bypass` and testing with real insight content.
- **Performance**: Synchronous conversion in request path. For v1 this is acceptable — `reverse_markdown` is fast for typical file sizes. Caching can be added later if profiling shows issues.
- **MCP default change**: Switching MCP default from raw to markdown is technically a breaking change for any existing MCP consumers expecting raw HTML. Mitigated by the format parameter allowing explicit `"html"`.

## References

- `app/tools/get_insight_tool.rb` — Current MCP tool implementation
- `app/models/insight_item_file.rb:29-53` — Existing markdown renderer (Redcarpet, markdown→HTML)
- `app/controllers/api/v1/insight_items_controller.rb:123-152` — Current API JSON builder
- `reverse_markdown` gem: https://github.com/xijo/reverse_markdown
