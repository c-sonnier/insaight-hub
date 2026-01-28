class GenerateThumbnailJob < ApplicationJob
  include AccountAware

  queue_as :default

  # Retry up to 3 times with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  THUMBNAIL_WIDTH = 1200
  THUMBNAIL_HEIGHT = 630
  VIEWPORT_WIDTH = 1200
  VIEWPORT_HEIGHT = 800

  def perform(insight_item_id:, account_id:)
    with_account_context(account_id) do
      insight_item = InsightItem.find_by(id: insight_item_id)
      return unless insight_item

      generate_thumbnail(insight_item)
    end
  end

  private

  def generate_thumbnail(insight_item)
    entry_file = insight_item.entry_insight_item_file
    return mark_generation_complete(insight_item) unless entry_file

    html_content = build_html_content(entry_file, insight_item)
    screenshot_data = capture_screenshot(html_content)

    if screenshot_data
      attach_thumbnail(insight_item, screenshot_data)
    end

    mark_generation_complete(insight_item)
    broadcast_thumbnail_update(insight_item)
  rescue => e
    Rails.logger.error("Thumbnail generation failed for InsightItem #{insight_item.id}: #{e.message}")
    mark_generation_complete(insight_item)
    raise e
  end

  def build_html_content(entry_file, insight_item)
    if entry_file.markdown?
      render_markdown_html(entry_file)
    elsif entry_file.html?
      inline_css_into_html(entry_file.content, insight_item)
    else
      # For other file types, create a basic wrapper
      wrap_content(entry_file)
    end
  end

  def inline_css_into_html(html_content, insight_item)
    # Build a map of CSS filenames to their content
    css_files = insight_item.insight_item_files.css_files.index_by(&:filename)
    return html_content if css_files.empty?

    # Replace <link rel="stylesheet" href="..."> with inline <style> tags
    html_content.gsub(/<link[^>]+rel=["']stylesheet["'][^>]*>/i) do |link_tag|
      # Extract the href value
      href_match = link_tag.match(/href=["']([^"']+)["']/i)
      next link_tag unless href_match

      href = href_match[1]
      # Get just the filename (ignore paths)
      filename = File.basename(href)

      if css_files[filename]
        "<style>#{css_files[filename].content}</style>"
      else
        link_tag # Keep external links as-is
      end
    end
  end

  def render_markdown_html(file)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
            color: #1a1a1a;
            background: #fff;
          }
          h1, h2, h3 { margin-top: 1.5em; margin-bottom: 0.5em; font-weight: 600; }
          h1 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
          h2 { font-size: 1.5em; }
          p { margin: 1em 0; }
          code { background: #f6f8fa; padding: 0.2em 0.4em; border-radius: 3px; font-size: 0.9em; }
          pre { background: #f6f8fa; padding: 1em; border-radius: 6px; overflow-x: auto; }
          pre code { background: none; padding: 0; }
          blockquote { border-left: 4px solid #ddd; margin: 1em 0; padding-left: 1em; color: #666; }
          table { border-collapse: collapse; width: 100%; }
          th, td { border: 1px solid #ddd; padding: 0.5em 1em; }
          th { background: #f6f8fa; }
          img { max-width: 100%; }
        </style>
      </head>
      <body>
        #{file.rendered_content}
      </body>
      </html>
    HTML
  end

  def wrap_content(file)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body {
            font-family: monospace;
            padding: 2rem;
            background: #1e1e1e;
            color: #d4d4d4;
            white-space: pre-wrap;
            word-wrap: break-word;
          }
        </style>
      </head>
      <body>#{CGI.escapeHTML(file.content.to_s[0..5000])}</body>
      </html>
    HTML
  end

  def capture_screenshot(html_content)
    browser = nil
    begin
      browser = Ferrum::Browser.new(
        headless: true,
        window_size: [ VIEWPORT_WIDTH, VIEWPORT_HEIGHT ],
        browser_options: {
          "no-sandbox": nil,
          "disable-gpu": nil,
          "disable-dev-shm-usage": nil,
          "no-zygote": nil,
          "single-process": nil,
          "disable-extensions": nil,
          "disable-background-networking": nil
        },
        timeout: 30,
        process_timeout: 30
      )

      page = browser.create_page
      page.content = html_content

      # Wait for content and JavaScript to render
      sleep 2

      # Take screenshot
      page.screenshot(format: :png, full: false, encoding: :binary)
    ensure
      browser&.quit
    end
  end

  def attach_thumbnail(insight_item, screenshot_data)
    insight_item.thumbnail.attach(
      io: StringIO.new(screenshot_data),
      filename: "thumbnail_#{insight_item.slug}.png",
      content_type: "image/png"
    )
  end

  def mark_generation_complete(insight_item)
    insight_item.update_column(:thumbnail_generating, false)
  end

  def broadcast_thumbnail_update(insight_item)
    Turbo::StreamsChannel.broadcast_replace_to(
      "insight_item_thumbnails_#{insight_item.account_id}",
      target: "insight_item_thumbnail_#{insight_item.id}",
      partial: "insight_items/thumbnail",
      locals: { insight_item: insight_item }
    )
  end
end
