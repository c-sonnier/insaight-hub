class ProfilesController < ApplicationController
  def show
    @user = Current.user
  end

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user
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
    require "zip"

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
    params.require(:user).permit(:name, :theme)
  end
end
