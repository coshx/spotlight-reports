class CoursesController < ApplicationController

  before_action :check_login
  skip_before_filter :verify_authenticity_token

  def get_school_averages
    render json: Course.average_stats(session[:school_id], params[:start_date], params[:end_date])
  end

  private

  def check_login
    return render html: "<strong>Not Authorized</strong>".html_safe unless session[:school_id]
  end

end
