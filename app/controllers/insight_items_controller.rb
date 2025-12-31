class InsightItemsController < ApplicationController
  allow_unauthenticated_access only: [:index, :show]
  before_action :set_insight_item, only: [:show, :edit, :update, :destroy, :publish, :unpublish, :export]
  before_action :authorize_owner, only: [:edit, :update, :destroy, :publish, :unpublish, :export]
  before_action :authorize_published_or_owner, only: [:show]

  def index
    @insight_items = InsightItem.published.includes(:user)
    @insight_items = @insight_items.by_audience(params[:audience]) if params[:audience].present?
    @insight_items = @insight_items.by_tag(params[:tag]) if params[:tag].present?
    @insight_items = @insight_items.search(params[:q]) if params[:q].present?

    @insight_items = case params[:sort]
    when "oldest"
      @insight_items.order(published_at: :asc)
    when "updated"
      @insight_items.order(updated_at: :desc)
    else
      @insight_items.order(published_at: :desc)
    end

    @pagy, @insight_items = pagy(@insight_items, items: 12)
  end

  def show
    @insight_item_files = @insight_item.insight_item_files.order(:filename)
    @current_file = if params[:file]
      @insight_item.insight_item_files.find_by(filename: params[:file])
    else
      @insight_item.entry_insight_item_file
    end
  end

  def new
    @insight_item = Current.user.insight_items.build
    @insight_item.insight_item_files.build
  end

  def create
    @insight_item = Current.user.insight_items.build(insight_item_params)

    if @insight_item.save
      redirect_to @insight_item, notice: "Insight was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @insight_item.update(insight_item_params)
      redirect_to @insight_item, notice: "Insight was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @insight_item.destroy
    redirect_to insight_items_path, notice: "Insight was successfully deleted."
  end

  def publish
    @insight_item.publish!
    redirect_to @insight_item, notice: "Insight has been published."
  end

  def unpublish
    @insight_item.unpublish!
    redirect_to @insight_item, notice: "Insight has been unpublished."
  end

  def my_insights
    @insight_items = Current.user.insight_items.order(created_at: :desc)
  end

  def export
    if @insight_item.single_file?
      file = @insight_item.entry_insight_item_file
      send_data file.content,
                filename: file.filename,
                type: file.content_type,
                disposition: "attachment"
    else
      zip_data = generate_insight_zip(@insight_item)
      send_data zip_data,
                filename: "#{@insight_item.slug}.zip",
                type: "application/zip",
                disposition: "attachment"
    end
  end

  private

  def generate_insight_zip(insight_item)
    require "zip"

    stringio = Zip::OutputStream.write_buffer do |zio|
      insight_item.insight_item_files.each do |file|
        zio.put_next_entry(file.filename)
        zio.write(file.content)
      end
    end
    stringio.rewind
    stringio.read
  end

  def set_insight_item
    @insight_item = InsightItem.find_by!(slug: params[:id])
  end

  def authorize_owner
    unless @insight_item.user == Current.user || Current.user&.admin?
      redirect_to insight_items_path, alert: "You are not authorized to perform this action."
    end
  end

  def authorize_published_or_owner
    unless @insight_item.published? || @insight_item.user == Current.user || Current.user&.admin?
      redirect_to insight_items_path, alert: "This insight is not available."
    end
  end

  def insight_item_params
    params.require(:insight_item).permit(
      :title,
      :description,
      :audience,
      :entry_file,
      :tags,
      insight_item_files_attributes: [:id, :filename, :content, :content_type, :_destroy]
    )
  end
end
