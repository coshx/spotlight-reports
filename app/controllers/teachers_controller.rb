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

    client = Pandarus::Client.new(
      prefix: ENV['API_URL'],
      token: ENV['API_TOKEN'])

    teacher = Teacher.find(params[:id])
    teacher.avatar_url = client.show_user_details(teacher.canvas_id).avatar_url
    teacher.email = client.get_user_profile(teacher.canvas_id).primary_email

    enrollments = client.list_enrollments_users(teacher.canvas_id, type:"TeacherEnrollment")
    course_ids = enrollments.map {|enrollment| enrollment.course_id}
    courses = course_ids.map { |course_id| Course.where(canvas_id: course_id) }.flatten.uniq
    courses_hash = Hash[ courses.map { |course| [course.canvas_id, course] } ]

    course_data = Hash[ courses.map { |course| [ course.canvas_id, HTTParty.get("https://cvilleschools.test.instructure.com/api/v1/courses/" + course.canvas_id.to_s + "/analytics/activity?access_token=" + ENV['API_TOKEN'])] } ]

    render json: {teacher: teacher, courses: courses_hash, course_analytics: course_data}
  end

end
