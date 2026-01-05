class InsightItemFilesController < ApplicationController
  def show
    @insight_item = InsightItem.find_by!(slug: params[:insight_item_id])
    @insight_item_file = @insight_item.insight_item_files.find_by!(filename: params[:id])

    unless @insight_item.published? || @insight_item.user == Current.user || Current.user&.admin?
      head :not_found
      return
    end

    if @insight_item_file.markdown?
      render html: markdown_html_wrapper(@insight_item_file.rendered_content).html_safe, content_type: "text/html"
    elsif @insight_item_file.content_type == "text/html"
      render html: @insight_item_file.content.html_safe, content_type: "text/html"
    else
      # For CSS, JS, JSON, and other non-HTML files, use send_data to preserve MIME type
      send_data @insight_item_file.content,
                type: @insight_item_file.content_type,
                disposition: "inline"
    end
  end

  private

  def markdown_html_wrapper(content)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
            color: #1a1a1a;
          }
          h1, h2, h3, h4, h5, h6 { margin-top: 1.5em; margin-bottom: 0.5em; font-weight: 600; }
          h1 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
          h2 { font-size: 1.5em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
          h3 { font-size: 1.25em; }
          p { margin: 1em 0; }
          a { color: #0366d6; text-decoration: none; }
          a:hover { text-decoration: underline; }
          code {
            background: #f6f8fa;
            padding: 0.2em 0.4em;
            border-radius: 3px;
            font-family: 'SFMono-Regular', Consolas, monospace;
            font-size: 0.9em;
          }
          pre {
            background: #f6f8fa;
            padding: 1em;
            border-radius: 6px;
            overflow-x: auto;
          }
          pre code { background: none; padding: 0; }
          blockquote {
            border-left: 4px solid #ddd;
            margin: 1em 0;
            padding-left: 1em;
            color: #666;
          }
          table { border-collapse: collapse; width: 100%; margin: 1em 0; }
          th, td { border: 1px solid #ddd; padding: 0.5em 1em; text-align: left; }
          th { background: #f6f8fa; }
          img { max-width: 100%; height: auto; }
          ul, ol { padding-left: 2em; }
          li { margin: 0.25em 0; }
          hr { border: none; border-top: 1px solid #eee; margin: 2em 0; }
        </style>
      </head>
      <body>
        #{content}
      </body>
      </html>
    HTML
  end
end
