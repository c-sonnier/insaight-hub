class InsightItem < ApplicationRecord
  belongs_to :account
  belongs_to :user
  has_many :insight_item_files, dependent: :destroy
  has_many :engagements, dependent: :destroy
  has_many :comments, through: :engagements, source: :engageable, source_type: "Comment"

  accepts_nested_attributes_for :insight_item_files, allow_destroy: true, reject_if: :all_blank

  enum :audience, { developer: "developer", stakeholder: "stakeholder", end_user: "end_user" }
  enum :status, { draft: "draft", published: "published" }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :account_id }, format: { with: /\A[a-z0-9-]+\z/, message: "must contain only lowercase letters, numbers, and hyphens" }
  validates :audience, presence: true, inclusion: { in: audiences.keys }
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :share_token, uniqueness: true, allow_nil: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :published, -> { where(status: :published) }
  scope :draft, -> { where(status: :draft) }
  scope :by_audience, ->(audience) { where(audience: audience) if audience.present? }
  scope :by_tag, ->(tag) { where("json_extract(metadata, '$.tags') LIKE ?", "%#{tag}%") if tag.present? }
  scope :search, ->(query) { where("title LIKE :q OR description LIKE :q", q: "%#{query}%") if query.present? }
  scope :shareable, -> { published.where(share_enabled: true).where.not(share_token: nil) }

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

  def comments_count
    engagements.comments.count
  end

  def to_param
    slug
  end

  def generate_share_token!
    update!(share_token: SecureRandom.urlsafe_base64(16))
  end

  def regenerate_share_token!
    generate_share_token!
  end

  def enable_sharing!
    generate_share_token! if share_token.blank?
    update!(share_enabled: true)
  end

  def disable_sharing!
    update!(share_enabled: false)
  end

  def shareable?
    published? && share_enabled? && share_token.present?
  end

  private

  def generate_slug
    base_slug = title.to_s.parameterize
    self.slug = base_slug
    counter = 1
    while InsightItem.where(account_id: account_id).exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
