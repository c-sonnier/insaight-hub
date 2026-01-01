class InsightItemFile < ApplicationRecord
  belongs_to :insight_item

  validates :filename, presence: true
  validates :filename, uniqueness: { scope: :insight_item_id, message: "already exists in this insight" }
  validates :content, presence: true

  scope :html_files, -> { where(content_type: "text/html") }
  scope :css_files, -> { where(content_type: "text/css") }
  scope :js_files, -> { where(content_type: ["text/javascript", "application/javascript"]) }
  scope :markdown_files, -> { where(content_type: "text/markdown") }

  def html?
    content_type == "text/html"
  end

  def css?
    content_type == "text/css"
  end

  def javascript?
    content_type.in?(["text/javascript", "application/javascript"])
  end

  def markdown?
    content_type == "text/markdown"
  end

  def rendered_content
    return content unless markdown?

    markdown_renderer.render(content)
  end

  private

  def markdown_renderer
    @markdown_renderer ||= Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        hard_wrap: true,
        link_attributes: { target: "_blank", rel: "noopener" }
      ),
      autolink: true,
      tables: true,
      fenced_code_blocks: true,
      strikethrough: true,
      superscript: true,
      underline: true,
      highlight: true,
      quote: true,
      footnotes: true
    )
  end

  def extension
    File.extname(filename).delete(".")
  end
end
