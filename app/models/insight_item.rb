class InsightItem < ApplicationRecord
  belongs_to :user
  has_many :insight_item_files, dependent: :destroy

  accepts_nested_attributes_for :insight_item_files, allow_destroy: true, reject_if: :all_blank

  enum :audience, { developer: "developer", stakeholder: "stakeholder", end_user: "end_user" }
  enum :status, { draft: "draft", published: "published" }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "must contain only lowercase letters, numbers, and hyphens" }
  validates :audience, presence: true, inclusion: { in: audiences.keys }
  validates :status, presence: true, inclusion: { in: statuses.keys }

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :published, -> { where(status: :published) }
  scope :draft, -> { where(status: :draft) }
  scope :by_audience, ->(audience) { where(audience: audience) if audience.present? }
  scope :by_tag, ->(tag) { where("json_extract(metadata, '$.tags') LIKE ?", "%#{tag}%") if tag.present? }
  scope :search, ->(query) { where("title LIKE :q OR description LIKE :q", q: "%#{query}%") if query.present? }

  def tags
    metadata&.dig("tags") || []
  end

  def tags=(value)
    self.metadata ||= {}
    tags_array = case value
    when String
      value.split(",").map(&:strip).reject(&:blank?)
    when Array
      value.map(&:strip).reject(&:blank?)
    else
      []
    end
    self.metadata["tags"] = tags_array
  end

  def publish!
    update!(status: :published, published_at: Time.current)
    InsightItemsChannel.broadcast_new_insight_item(self)
  end

  def unpublish!
    update!(status: :draft, published_at: nil)
  end

  def entry_insight_item_file
    insight_item_files.find_by(filename: entry_file) || insight_item_files.first
  end

  def single_file?
    insight_item_files.count == 1
  end

  def to_param
    slug
  end

  private

  def generate_slug
    base_slug = title.to_s.parameterize
    self.slug = base_slug
    counter = 1
    while InsightItem.exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
