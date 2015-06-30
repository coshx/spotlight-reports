class TeachersController < ApplicationController
  before_action :check_login
  require 'httparty'

  def index
  end

  def get_teachers
    render json: Teacher.where(school_account: params[:id]).to_json
  end


  def get_teacher_details
    teacher = Teacher.where(canvas_id: params[:id]).first
    days_since_last_access = teacher.days_since_last_access
    courses = teacher.get_courses

    courses_hash = Hash[ courses.map { |course| [course.canvas_id, course] } ]
    course_data = teacher.get_course_data(courses)

    statgrid_data = teacher.compile_statgrid_data(courses)

    render json: {
      teacher: teacher,
      days_since_last_access: days_since_last_access,
      courses: courses_hash,
      course_analytics: course_data,
      statgrid: statgrid_data
    }
  end

  private

  def check_login
    return render html: "<strong>Not Authorized</strong>".html_safe unless session[:school_id]
  end

end
