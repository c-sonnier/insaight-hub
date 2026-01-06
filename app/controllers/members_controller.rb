class MembersController < ApplicationController
  include AccountScoped

  def index
    @members = current_account.users.includes(:identity).order(created_at: :asc)
  end
end

