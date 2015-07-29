class CoursesController < ApplicationController


  skip_before_filter :verify_authenticity_token

  def get_school_averages
    puts 'hello world'
    return render html: "<strong>Not Authorized</strong>".html_safe unless session[:school_id]
    puts session[:school_id], params[:start_date], params[:end_date]
    render json: Course.average_stats(session[:school_id], params[:start_date], params[:end_date])
  end

  private



end
