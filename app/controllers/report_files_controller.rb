class ReportFilesController < ApplicationController
  allow_unauthenticated_access only: [:show]

  def show
    @report = Report.find_by!(slug: params[:report_id])
    @report_file = @report.report_files.find_by!(filename: params[:id])

    # For published reports, allow public access
    # For draft reports, require ownership or admin
    unless @report.published? || @report.user == Current.user || Current.user&.admin?
      head :not_found
      return
    end

    render html: @report_file.content.html_safe, content_type: @report_file.content_type
  end
end
