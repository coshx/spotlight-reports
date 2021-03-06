class CoursesController < ApplicationController


  skip_before_filter :verify_authenticity_token

  def get_school_averages
    render json: Course.average_stats(params[:school_id], params[:start_date], params[:end_date])
  end

  private



end
