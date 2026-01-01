# frozen_string_literal: true

# Concern for models that can be attached to an Engagement (delegated types pattern)
# Include this in any model that serves as an engageable type (Comment, Reaction, etc.)
module Engageable
  extend ActiveSupport::Concern

  included do
    has_one :engagement, as: :engageable, touch: true, dependent: :destroy
  end

  # Delegate common methods to the engagement for convenience
  delegate :user, :insight_item, :created_at, to: :engagement, allow_nil: true
end

