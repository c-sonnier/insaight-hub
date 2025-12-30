class InsightItemFile < ApplicationRecord
  belongs_to :insight_item

  validates :filename, presence: true
  validates :filename, uniqueness: { scope: :insight_item_id, message: "already exists in this insight" }
  validates :content, presence: true

  scope :html_files, -> { where(content_type: "text/html") }
  scope :css_files, -> { where(content_type: "text/css") }
  scope :js_files, -> { where(content_type: ["text/javascript", "application/javascript"]) }

  def html?
    content_type == "text/html"
  end

  def css?
    content_type == "text/css"
  end

  def javascript?
    content_type.in?(["text/javascript", "application/javascript"])
  end

  def extension
    File.extname(filename).delete(".")
  end
end
