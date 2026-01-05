# frozen_string_literal: true

# Engagement is the "super" model for all engagement types using Rails delegated types.
# This pattern allows us to have a unified timeline of all engagements while each type
# (Comment, Reaction, Annotation, etc.) maintains its own specialized behavior and schema.
#
# Reference: https://api.rubyonrails.org/classes/ActiveRecord/DelegatedType.html
class Engagement < ApplicationRecord
  # Delegated type declaration - add new types here as they're created
  delegated_type :engageable, types: %w[Comment], dependent: :destroy

  # Common associations shared by all engagement types
  belongs_to :account
  belongs_to :insight_item
  belongs_to :user

  # Common scopes for querying engagements
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }
  scope :comments, -> { where(engageable_type: "Comment") }
end

