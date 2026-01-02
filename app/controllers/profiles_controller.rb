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

  def import_insights
    unless params[:insights_zip].present?
      redirect_to profile_path, alert: "Please select a zip file to import."
      return
    end

    imported_count = 0
    skipped_count = 0

    Zip::File.open(params[:insights_zip].tempfile) do |zip_file|
      # Group entries by folder
      folders = zip_file.entries.reject(&:directory?).group_by do |entry|
        entry.name.split("/").first
      end

      folders.each do |folder_name, entries|
        # Skip if insight with this slug already exists
        if InsightItem.exists?(slug: folder_name)
          skipped_count += 1
          next
        end

        # Derive title from folder name (slug)
        title = folder_name.tr("-", " ").titleize

        insight_item = Current.user.insight_items.build(
          title: title,
          slug: folder_name,
          description: "[Imported] Please update this description.",
          audience: :developer,
          status: :draft,
          metadata: { "tags" => ["imported"] }
        )

        entries.each do |entry|
          filename = entry.name.sub("#{folder_name}/", "")
          content = entry.get_input_stream.read.force_encoding("UTF-8")
          content_type = determine_content_type(filename)

          insight_item.insight_item_files.build(
            filename: filename,
            content: content,
            content_type: content_type
          )
        end

        # Set entry file to first HTML or markdown file if available
        html_file = insight_item.insight_item_files.find { |f| f.filename.end_with?(".html") }
        md_file = insight_item.insight_item_files.find { |f| f.filename.end_with?(".md") }
        insight_item.entry_file = (html_file || md_file)&.filename

        if insight_item.save
          imported_count += 1
        end
      end
    end

    message = "Imported #{imported_count} insight(s)."
    message += " Skipped #{skipped_count} (already exist)." if skipped_count > 0

    redirect_to my_insights_path, notice: message
  rescue Zip::Error => e
    redirect_to my_insights_path, alert: "Invalid zip file: #{e.message}"
  end

  private

  def determine_content_type(filename)
    extension = File.extname(filename).downcase
    case extension
    when ".html", ".htm"
      "text/html"
    when ".css"
      "text/css"
    when ".js"
      "text/javascript"
    when ".md", ".markdown"
      "text/markdown"
    when ".json"
      "application/json"
    when ".txt"
      "text/plain"
    else
      "application/octet-stream"
    end
  end

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
