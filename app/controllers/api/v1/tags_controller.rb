module Api
  module V1
    class TagsController < BaseController
      def index
        # Get all unique tags from the user's reports
        tags = current_user.reports.flat_map(&:tags).uniq.sort

        render json: { tags: tags }
      end
    end
  end
end
