class TeachersController < ApplicationController
  before_action :check_login
  require 'httparty'

  def index
  end

  def get_teachers
    render json: Teacher.where(school_account: params[:id]).to_json
  end

  def get_course_graph_data
    teacher = Teacher.where(canvas_id: params[:id], school_account: session[:school_id]).first
    courses = teacher.get_courses(teacher.school_account)
    render json: teacher.get_course_data(courses)
  end

  def get_course_grid_data
    teacher = Teacher.where(canvas_id: params[:id], school_account: session[:school_id]).first
    courses = teacher.get_courses(teacher.school_account)
    render json: teacher.compile_statgrid_data(courses)
  end

  def get_student_grid_data
    teacher = Teacher.where(canvas_id: params[:id], school_account: session[:school_id]).first
    courses = teacher.get_courses(teacher.school_account)
    render json: teacher.get_student_data(courses)
  end

  def get_teacher_details
    teacher = Teacher.where(canvas_id: params[:id], school_account: session[:school_id]).first
    days_since_last_access = teacher.days_since_last_access
    courses = teacher.get_courses(teacher.school_account)

    courses_hash = Hash[ courses.map { |course| [course.canvas_id, course] } ]

    render json: {
      teacher: teacher,
      days_since_last_access: days_since_last_access,
      courses: courses_hash
    }
  end

  def get_course_grade_data
    teacher = Teacher.where(canvas_id: params[:id], school_account: session[:school_id]).first
    courses = teacher.get_courses(teacher.school_account)
    render json: teacher.get_grade_data(courses)
  end


  private

  def check_login
    return render html: "<strong>Not Authorized</strong>".html_safe unless session[:school_id]
  end

end
