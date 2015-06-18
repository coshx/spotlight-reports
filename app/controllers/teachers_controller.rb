class TeachersController < ApplicationController
  require 'httparty'

  def index
    return render html: "<strong>Not Authorized</strong>".html_safe unless session[:school_id]
  end

  def get_teachers
    return render html: "<strong>Not Authorized</strong>".html_safe unless session[:school_id]

    render json: Teacher.where(school_account: params[:id]).to_json
  end


  def get_teacher_details
    return render html: "<strong>Not Authorized</strong>".html_safe unless session[:school_id]

    teacher = Teacher.where(canvas_id: params[:id]).first
    courses = teacher.get_courses

    courses_hash = Hash[ courses.map { |course| [course.canvas_id, course] } ]
    course_data = teacher.get_course_data(courses)

    render json: {teacher: teacher, courses: courses_hash, course_analytics: course_data}
  end

end
