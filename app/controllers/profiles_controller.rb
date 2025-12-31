require "zip"

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

    # Handle password change - require current password verification
    if params[:user][:password].present?
      unless @user.authenticate(params[:user][:current_password])
        @user.errors.add(:current_password, "is incorrect")
        return render :edit, status: :unprocessable_entity
      end
    end

    update_params = profile_params.except(:current_password)
    # Remove password fields if not changing password
    if params[:user][:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def regenerate_token
    Current.user.regenerate_api_token!
    redirect_to profile_path, notice: "API token regenerated successfully."
  end

  def export_all_insights
    insight_items = Current.user.insight_items.includes(:insight_item_files)

    if insight_items.empty?
      redirect_to profile_path, alert: "You don't have any insights to export."
      return
    end

    zip_data = generate_all_insights_zip(insight_items)
    send_data zip_data,
              filename: "all-insights-#{Date.current}.zip",
              type: "application/zip",
              disposition: "attachment"
  end

  private

  def generate_all_insights_zip(insight_items)
    stringio = Zip::OutputStream.write_buffer do |zio|
      insight_items.each do |insight_item|
        folder_name = insight_item.slug

        insight_item.insight_item_files.each do |file|
          zio.put_next_entry("#{folder_name}/#{file.filename}")
          zio.write(file.content)
        end
      end
    end
    stringio.rewind
    stringio.read
  end

  def profile_params
    params.require(:user).permit(:name, :email_address, :theme, :avatar, :password, :password_confirmation, :current_password)
  end
end
