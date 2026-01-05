# frozen_string_literal: true

# Comment model for threaded discussions on insights.
# Uses the Engageable concern to participate in the delegated types pattern.
class Comment < ApplicationRecord
  include Engageable

  belongs_to :account

  # Self-referential association for threaded replies
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy

  # Validations
  validates :body, presence: true, length: { maximum: 5000 }

  # Scopes
  scope :root_comments, -> { where(parent_id: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }

  # Check if this is a reply to another comment
  def reply?
    parent_id.present?
  end

  # Check if this comment has any replies
  def has_replies?
    replies.exists?
  end

  # Get the depth of nesting (0 for root comments)
  def depth
    return 0 if parent.nil?
    1 + parent.depth
  end
end

