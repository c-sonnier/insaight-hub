class ProfilesController < ApplicationController
  def show
    @user = Current.user
  end

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user

    # Handle avatar removal if requested
    if params[:user][:remove_avatar] == "1"
      @user.avatar.purge
    end

    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def regenerate_token
    Current.user.regenerate_api_token!
    redirect_to profile_path, notice: "API token regenerated successfully."
  end

  private

  def profile_params
    params.require(:user).permit(:name, :theme, :avatar)
  end
end
