module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[edit update destroy]

    def index
      # Users (memberships) in the current account
      @users = current_account.users.includes(:identity).order(created_at: :desc)
    end

    def edit
    end

    def update
      # Only allow updating the role for account memberships
      if @user.update(user_params)
        redirect_to admin_users_path, notice: "User was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == Current.user
        redirect_to admin_users_path, alert: "You cannot remove yourself from the organization."
      elsif @user.owner? && current_account.users.owners.count == 1
        redirect_to admin_users_path, alert: "Cannot remove the last owner of the organization."
      else
        @user.destroy
        redirect_to admin_users_path, notice: "User was removed from the organization."
      end
    end

    private

    def set_user
      @user = current_account.users.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:role)
    end
  end
end
