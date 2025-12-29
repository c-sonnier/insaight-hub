module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    private

    def require_admin
      unless Current.user&.admin?
        redirect_to root_path, alert: "You are not authorized to access this area."
      end
    end
  end
end
