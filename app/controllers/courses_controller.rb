class CoursesController < ApplicationController

  skip_before_filter :verify_authenticity_token
  before_action :check_login

  def get_school_averages
    render json: Course.average_stats(session[:school_id], params[:start_date], params[:end_date])
  end

  private

  def check_login
    return render html: "<strong>Not Authorized</strong>".html_safe unless session[:school_id]
  end

end
