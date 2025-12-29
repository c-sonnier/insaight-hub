class ReportsController < ApplicationController
  allow_unauthenticated_access only: [:index, :show]
  before_action :set_report, only: [:show, :edit, :update, :destroy, :publish, :unpublish]
  before_action :authorize_owner, only: [:edit, :update, :destroy, :publish, :unpublish]
  before_action :authorize_published_or_owner, only: [:show]

  def index
    @reports = Report.published.includes(:user)
    @reports = @reports.by_audience(params[:audience]) if params[:audience].present?
    @reports = @reports.by_tag(params[:tag]) if params[:tag].present?
    @reports = @reports.search(params[:q]) if params[:q].present?

    @reports = case params[:sort]
    when "oldest"
      @reports.order(published_at: :asc)
    when "updated"
      @reports.order(updated_at: :desc)
    else
      @reports.order(published_at: :desc)
    end

    @pagy, @reports = pagy(@reports, items: 12)
  end

  def show
    @report_files = @report.report_files.order(:filename)
    @current_file = if params[:file]
      @report.report_files.find_by(filename: params[:file])
    else
      @report.entry_report_file
    end
  end

  def new
    @report = Current.user.reports.build
    @report.report_files.build
  end

  def create
    @report = Current.user.reports.build(report_params)

    if @report.save
      redirect_to @report, notice: "Report was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @report.update(report_params)
      redirect_to @report, notice: "Report was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @report.destroy
    redirect_to reports_path, notice: "Report was successfully deleted."
  end

  def publish
    @report.publish!
    redirect_to @report, notice: "Report has been published."
  end

  def unpublish
    @report.unpublish!
    redirect_to @report, notice: "Report has been unpublished."
  end

  def my_reports
    @reports = Current.user.reports.order(created_at: :desc)
  end

  private

  def set_report
    @report = Report.find_by!(slug: params[:id])
  end

  def authorize_owner
    unless @report.user == Current.user || Current.user&.admin?
      redirect_to reports_path, alert: "You are not authorized to perform this action."
    end
  end

  def authorize_published_or_owner
    unless @report.published? || @report.user == Current.user || Current.user&.admin?
      redirect_to reports_path, alert: "This report is not available."
    end
  end

  def report_params
    params.require(:report).permit(
      :title,
      :description,
      :audience,
      :entry_file,
      :tags,
      report_files_attributes: [:id, :filename, :content, :content_type, :_destroy]
    )
  end
end
