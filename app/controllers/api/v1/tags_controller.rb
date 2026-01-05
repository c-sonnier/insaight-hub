module Api
  module V1
    class TagsController < BaseController
      def index
        # Get all unique tags from the account's insights
        tags = current_account.insight_items.flat_map(&:tags).uniq.sort

        render json: { tags: tags }
      end
    end
  end
end
